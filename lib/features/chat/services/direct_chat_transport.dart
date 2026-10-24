import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'local_chat_store.dart';

/// Foreground-only peer-to-peer chat. Firestore stores *only* disposable
/// WebRTC SDP/ICE transport signaling (no message text or media URLs).
/// STUN cannot traverse every NAT; a private TURN relay is required for
/// reliable delivery across restrictive networks (TURN never stores files).
class DirectChatTransport {
  DirectChatTransport({
    required this.uid,
    required this.peerId,
    required this.chatId,
    required this.store,
  });

  final String uid;
  final String peerId;
  final String chatId;
  final LocalChatStore store;
  final ValueNotifier<bool> connected = ValueNotifier<bool>(false);
  RTCPeerConnection? _pc;
  RTCDataChannel? _channel;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _signalListener;
  bool _disposed = false;
  bool _remoteSet = false;
  String? _offerId;
  String? _remoteSession;
  final Set<String> _iceSeen = {};
  final List<Map<String, dynamic>> _pendingLocalIce = [];
  bool _signalReady = false;
  Map<String, dynamic>? _deferredSignal;
  bool _handlingRemote = false;
  final Map<String, IOSink> _incomingFiles = {};
  final Map<String, File> _incomingPaths = {};
  final Map<String, Map<String, dynamic>> _incomingMeta = {};
  Future<void> _sendQueue = Future<void>.value();
  String? lastError;

  DocumentReference<Map<String, dynamic>> get _self => FirebaseFirestore.instance
      .collection('chats').doc(chatId).collection('p2p_signals').doc(uid);
  DocumentReference<Map<String, dynamic>> get _peer => FirebaseFirestore.instance
      .collection('chats').doc(chatId).collection('p2p_signals').doc(peerId);

  bool get isOnline => connected.value && !_disposed &&
      _channel?.state == RTCDataChannelState.RTCDataChannelOpen;

  Future<void> start() async {
    if (_disposed || _signalListener != null) return;
    _pc = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    });
    _pc!.onIceCandidate = (candidate) {
      if (_disposed || candidate.candidate == null) return;
      _pendingLocalIce.add(Map<String, dynamic>.from(candidate.toMap()));
      if (_signalReady) unawaited(_flushIce());
    };
    _pc!.onDataChannel = _attachChannel;
    _pc!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        connected.value = false;
      }
    };
    _signalListener = _peer.snapshots().listen((snap) {
      if (!snap.exists || _disposed) return;
      unawaited(_consumeSignal(snap.data() ?? {}));
    }, onError: (Object error) {
      lastError = error.toString();
      debugPrint('WorldVoice P2P signaling denied/unavailable: $error');
    });
    // Deterministic offerer avoids glare when both phones open at once.
    if (uid.compareTo(peerId) < 0) await _publishOffer();
  }

  Future<void> _flushIce() async {
    if (!_signalReady || _pendingLocalIce.isEmpty || _disposed) return;
    final values = List<Map<String, dynamic>>.from(_pendingLocalIce);
    _pendingLocalIce.clear();
    try {
      await _self.update({
        'ice': FieldValue.arrayUnion(values),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      // Retry with the next ICE candidate or the next negotiation.
      _pendingLocalIce.insertAll(0, values);
      debugPrint('WorldVoice P2P ICE retry: $error');
    }
  }

  Future<void> _publishOffer() async {
    _offerId = LocalChatStore.newId();
    final dc = await _pc!.createDataChannel('worldvoice-chat',
        RTCDataChannelInit()..ordered = true);
    _attachChannel(dc);
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);
    await _self.set({
      'owner': uid, 'offerId': _offerId, 'kind': 'offer',
      'sdp': offer.sdp ?? '', 'ice': <dynamic>[],
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _signalReady = true;
    await _flushIce();
  }

  Future<void> _consumeSignal(Map<String, dynamic> data) async {
    if (_disposed || _pc == null) return;
    if (_handlingRemote) {
      _deferredSignal = data;
      return;
    }
    _handlingRemote = true;
    try {
      final kind = data['kind'];
      final offerId = data['offerId']?.toString();
      if (offerId == null) return;
      if (uid.compareTo(peerId) > 0 && kind == 'offer') {
        if (_remoteSession != offerId) {
          _remoteSession = offerId;
          _iceSeen.clear();
          final remoteSdp = (data['sdp'] ?? '').toString();
          if (remoteSdp.isEmpty) return;
          await _pc!.setRemoteDescription(RTCSessionDescription(remoteSdp, 'offer'));
          _remoteSet = true;
          final answer = await _pc!.createAnswer();
          await _pc!.setLocalDescription(answer);
          await _self.set({
            'owner': uid, 'offerId': offerId, 'kind': 'answer',
            'sdp': answer.sdp ?? '', 'ice': <dynamic>[],
            'updatedAt': FieldValue.serverTimestamp(),
          });
          _signalReady = true;
          await _flushIce();
        }
      } else if (uid.compareTo(peerId) < 0 &&
          kind == 'answer' && offerId == _offerId && !_remoteSet) {
        final remoteSdp = (data['sdp'] ?? '').toString();
        if (remoteSdp.isEmpty) return;
        await _pc!.setRemoteDescription(RTCSessionDescription(remoteSdp, 'answer'));
        _remoteSet = true;
      }
      if (!_remoteSet) return;
      final candidates = data['ice'];
      if (candidates is List) {
        for (final item in candidates) {
          if (item is! Map) continue;
          final candidate = (item['candidate'] ?? '').toString();
          if (candidate.isEmpty || !_iceSeen.add(candidate)) continue;
          try {
            await _pc!.addCandidate(RTCIceCandidate(
              candidate,
              item['sdpMid']?.toString(),
              (item['sdpMLineIndex'] as num?)?.toInt(),
            ));
          } catch (error) {
            debugPrint('WorldVoice P2P remote candidate: $error');
          }
        }
      }
    } catch (error) {
      lastError = error.toString();
      debugPrint('WorldVoice P2P negotiation: $error');
    } finally {
      _handlingRemote = false;
      final next = _deferredSignal;
      _deferredSignal = null;
      if (next != null && !_disposed) {
        unawaited(_consumeSignal(next));
      }
    }
  }

  void _attachChannel(RTCDataChannel channel) {
    _channel = channel;
    channel.onDataChannelState = (state) {
      if (_disposed) return;
      connected.value = state == RTCDataChannelState.RTCDataChannelOpen;
      if (connected.value) unawaited(flush());
    };
    channel.onMessage = (message) {
      if (_disposed) return;
      if (!message.isBinary) {
        try {
          final payload = jsonDecode(message.text) as Map<String, dynamic>;
          unawaited(_receive(payload));
        } catch (error) {
          debugPrint('WorldVoice P2P frame rejected: $error');
        }
      } else {
        unawaited(_receiveBinary(message.binary));
      }
    };
  }

  Future<void> _transmit(Map<String, dynamic> payload) async {
    if (!isOnline) return;
    await _channel!.send(RTCDataChannelMessage(jsonEncode(payload)));
  }

  /// The local encrypted copy is committed before any attempt to transmit.
  Future<void> queueText(String text) async {
    final id = LocalChatStore.newId();
    await store.upsert({
      'id': id, 'senderId': uid, 'type': 'text', 'text': text,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'edited': false, 'withdrawn': false, 'hidden': false,
      'delivered': false, 'read': false,
    });
    await flush();
  }

  Future<void> queueMedia(File original, String type) async {
    final length = await original.length();
    if (length == 0 || length > 80 * 1024 * 1024) {
      throw StateError('File must be between 1 byte and 80 MB');
    }
    final id = LocalChatStore.newId();
    final local = await store.saveAttachment(original, id);
    await store.upsert({
      'id': id, 'senderId': uid, 'type': type, 'text': '',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'filePath': local.path, 'fileName': original.uri.pathSegments.last,
      'fileSize': length, 'edited': false, 'withdrawn': false,
      'hidden': false, 'delivered': false, 'read': false,
    });
    await flush();
  }

  Future<void> flush() {
    final next = _sendQueue.then((_) async {
      if (!isOnline) return;
      final messages = await store.messages();
      for (final item in messages) {
        if (!isOnline) return;
        if (item['senderId'] != uid ||
            item['delivered'] == true) {
          continue;
        }
        final pendingOp = item['pendingOp']?.toString();
        if (pendingOp == 'edit' || pendingOp == 'withdraw') {
          await _transmit({
            'op': pendingOp, 'id': item['id'], 'senderId': uid,
            'text': item['text'] ?? '',
          });
          continue;
        }
        final type = item['type']?.toString() ?? 'text';
        final filePath = item['filePath']?.toString() ?? '';
        if (type != 'text' && filePath.isNotEmpty) {
          await _sendFile(item);
        } else {
          await _transmit({'op': 'message', 'data': _wireData(item)});
        }
      }
    });
    _sendQueue = next.catchError((Object error) {
      lastError = error.toString();
      debugPrint('WorldVoice P2P outgoing queue: $error');
    });
    return next;
  }

  Map<String, dynamic> _wireData(Map<String, dynamic> item) => {
    'id': item['id'], 'senderId': uid, 'type': item['type'],
    'text': item['text'], 'createdAt': item['createdAt'],
    'edited': item['edited'] == true,
    'withdrawn': item['withdrawn'] == true,
  };

  Future<void> _sendFile(Map<String, dynamic> item) async {
    final file = File(item['filePath'] as String);
    if (!await file.exists()) return;
    final id = item['id'] as String;
    final transfer = LocalChatStore.newId();
    await _transmit({
      'op': 'file-begin', 'transfer': transfer,
      'data': {..._wireData(item), 'fileName': item['fileName'],
        'fileSize': item['fileSize']},
    });
    // Binary frame: 1-byte delimiter followed by UTF-8 transfer ID,
    // newline, then payload; stream, never load an entire video into RAM.
    final prefix = utf8.encode('W$transfer\n');
    await for (final chunk in file.openRead()) {
      // Keep WebRTC data-channel frames below the common 16 KiB limit.
      for (var offset = 0; offset < chunk.length; offset += 12 * 1024) {
        if (!isOnline) return;
        final end = min(offset + 12 * 1024, chunk.length);
        while (isOnline && await _channel!.getBufferedAmount() > 256 * 1024) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        if (!isOnline) return;
        await _channel!.send(RTCDataChannelMessage.fromBinary(
          Uint8List.fromList([...prefix, ...chunk.sublist(offset, end)]),
        ));
      }
    }
    await _transmit({'op': 'file-end', 'transfer': transfer, 'id': id});
  }

  Future<void> _receiveBinary(Uint8List bytes) async {
    final sep = bytes.indexOf(10);
    if (sep < 2 || sep > 100) return;
    final prefix = utf8.decode(bytes.sublist(0, sep));
    if (!prefix.startsWith('W')) return;
    final transfer = prefix.substring(1);
    final sink = _incomingFiles[transfer];
    if (sink == null) return;
    sink.add(bytes.sublist(sep + 1));
  }

  Future<void> _receive(Map<String, dynamic> frame) async {
    final op = frame['op'];
    final id = frame['id']?.toString();
    if (op == 'ack' && id != null) {
      await store.patch(id, {'delivered': true, 'pendingOp': ''});
      return;
    }
    if (op == 'read' && id != null) {
      await store.patch(id, {'read': true, 'delivered': true});
      return;
    }
    if (op == 'edit' || op == 'withdraw') {
      final senderId = frame['senderId']?.toString();
      if (senderId != peerId || id == null) return;
      final items = await store.messages();
      if (items.any((item) => item['id'] == id && item['senderId'] == peerId)) {
        await store.patch(id, op == 'withdraw'
          ? {'withdrawn': true, 'text': '', 'filePath': ''}
          : {'edited': true, 'text': (frame['text'] ?? '').toString()});
      }
      await _transmit({'op': 'ack', 'id': id});
      return;
    }
    if (op == 'file-begin') {
      final transfer = frame['transfer']?.toString() ?? '';
      final data = frame['data'];
      if (transfer.isEmpty || data is! Map ||
          data['senderId'] != peerId ||
          ((data['fileSize'] as num?)?.toInt() ?? 0) > 80 * 1024 * 1024) return;
      final original = (data['fileName'] ?? 'file.bin').toString();
      final extension = original.split('.').last.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      final root = await getApplicationSupportDirectory();
      final folder = Directory('${root.path}/worldvoice_peer_media/$uid');
      await folder.create(recursive: true);
      final safe = transfer.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
      final file = File('${folder.path}/$safe.$extension');
      _incomingPaths[transfer] = file;
      _incomingFiles[transfer] = file.openWrite();
      _incomingMeta[transfer] = Map<String, dynamic>.from(data);
      return;
    }
    if (op == 'file-end') {
      final transfer = frame['transfer']?.toString() ?? '';
      final sink = _incomingFiles.remove(transfer);
      final path = _incomingPaths.remove(transfer);
      final data = _incomingMeta.remove(transfer);
      if (sink == null || path == null || data == null) {
        return;
      }
      await sink.flush();
      await sink.close();
      final size = await path.length();
      if (size != (data['fileSize'] as num?)?.toInt()) {
        await path.delete();
        return;
      }
      await store.upsert({
        ...data, 'filePath': path.path, 'hidden': false,
        'delivered': true, 'read': false,
      });
      await _transmit({'op': 'ack', 'id': data['id']});
      await _transmit({'op': 'read', 'id': data['id']});
      return;
    }
    if (op != 'message') return;
    final data = frame['data'];
    if (data is! Map || data['senderId'] != peerId ||
        data['id'] is! String || data['text'] is! String) {
      return;
    }
    final items = await store.messages();
    final exists = items.any((item) => item['id'] == data['id']);
    if (!exists) {
      await store.upsert({
        ...Map<String, dynamic>.from(data), 'hidden': false,
        'delivered': true, 'read': false,
      });
    }
    await _transmit({'op': 'ack', 'id': data['id']});
    // A peer is in this foreground conversation when this transport is active.
    await _transmit({'op': 'read', 'id': data['id']});
  }

  Future<void> edit(String id, String text) async {
    final messages = await store.messages();
    if (!messages.any((m) => m['id'] == id && m['senderId'] == uid &&
        m['type'] == 'text')) {
      return;
    }
    final prior = messages.firstWhere((m) => m['id'] == id);
    final delivered = prior['delivered'] == true;
    await store.patch(id, {
      'text': text, 'edited': true, 'delivered': false,
      'pendingOp': delivered ? 'edit' : '',
    });
    await flush();
  }

  Future<void> withdraw(String id) async {
    final messages = await store.messages();
    if (!messages.any((m) => m['id'] == id && m['senderId'] == uid)) return;
    final prior = messages.firstWhere((m) => m['id'] == id);
    final delivered = prior['delivered'] == true;
    await store.patch(id, {
      'withdrawn': true, 'text': '', 'filePath': '',
      'delivered': !delivered,
      'pendingOp': delivered ? 'withdraw' : '',
    });
    if (delivered) await flush();
  }

  Future<void> dispose() async {
    _disposed = true;
    connected.value = false;
    await _signalListener?.cancel();
    // Do not clear the local queue. Future sessions retry delivery.
    try { await _self.delete(); } catch (_) {}
    for (final file in _incomingFiles.values) {
      await file.close();
    }
    _incomingFiles.clear();
    await _channel?.close();
    await _pc?.dispose();
    connected.dispose();
  }
}
