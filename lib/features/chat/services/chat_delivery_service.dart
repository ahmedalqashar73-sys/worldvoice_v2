import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'chat_delivery_crypto.dart';
import 'local_chat_store.dart';

/// App-scoped delivery, independent of the conversation screen. Firestore is
/// only a temporary encrypted mailbox, never the private chat transcript.
class ChatDeliveryService {
  ChatDeliveryService._();
  static final instance = ChatDeliveryService._();
  final _sessions = <String, ChatDeliverySession>{};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _chats;
  Timer? _retry;
  String? _uid;
  SimpleKeyPair? _identity;
  String? _publicKey;
  Future<void> _lifecycle = Future<void>.value();

  Future<void> setAccount(String? uid) {
    final next = _lifecycle.then((_) => _setAccount(uid));
    _lifecycle = next.catchError((Object error) {
      debugPrint('WorldVoice delivery initialization: $error');
    });
    return _lifecycle;
  }

  Future<void> _setAccount(String? uid) async {
    if (_uid == uid && _identity != null) return;
    _retry?.cancel();
    await _chats?.cancel();
    _chats = null;
    for (final session in _sessions.values) {
      session.close();
    }
    _sessions.clear();
    _uid = uid;
    _identity = null;
    _publicKey = null;
    if (uid == null) return;
    const secure = FlutterSecureStorage();
    final keyName = 'worldvoice_delivery_x25519_v1_$uid';
    var seed = await secure.read(key: keyName);
    if (seed == null) {
      seed = base64Encode(
        List<int>.generate(32, (_) => Random.secure().nextInt(256)),
      );
      await secure.write(key: keyName, value: seed);
    }
    _identity = await ChatDeliveryCrypto.agreement.newKeyPairFromSeed(
      base64Decode(seed),
    );
    _publicKey = base64Encode((await _identity!.extractPublicKey()).bytes);
    // Keep retrying initialization on temporary connectivity/rules failures.
    _retry = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(_sync()),
    );
    await _sync();
  }

  Future<void> _sync() async {
    final uid = _uid;
    if (uid == null || _identity == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('chat_delivery_keys')
          .doc(uid)
          .set({
            'publicKey': _publicKey,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      if (_uid != uid) return;
      _chats ??= FirebaseFirestore.instance
          .collection('chats')
          .where('memberIds', arrayContains: uid)
          .where('active', isEqualTo: true)
          .snapshots()
          .listen(
            (snapshot) {
              if (_uid != uid) return;
              final active = <String>{};
              for (final doc in snapshot.docs) {
                final members = List<String>.from(
                  doc.data()['memberIds'] as List,
                );
                if (members.length != 2 || doc.data()['type'] == 'group')
                  continue;
                active.add(doc.id);
                final peer = members.firstWhere((id) => id != uid);
                session(uid, peer, doc.id).wake();
              }
              for (final id in _sessions.keys.toList()) {
                if (!active.contains(id)) _sessions.remove(id)?.close();
              }
            },
            onError: (Object error) {
              debugPrint('WorldVoice delivery chat discovery: $error');
              _chats?.cancel();
              _chats = null;
            },
          );
      for (final item in _sessions.values) {
        item.wake();
      }
    } catch (error) {
      debugPrint('WorldVoice delivery retry pending: $error');
    }
  }

  ChatDeliverySession session(String uid, String peer, String chatId) {
    if (_uid != uid || _identity == null) {
      throw StateError('Message delivery is starting; please retry.');
    }
    return _sessions.putIfAbsent(
      chatId,
      () => ChatDeliverySession(uid, peer, chatId, _identity!, _publicKey!),
    );
  }
}

class ChatDeliverySession {
  ChatDeliverySession(
    this.uid,
    this.peer,
    this.chatId,
    this.identity,
    this.publicKey,
  ) {
    store.revision.addListener(wake);
    _listen();
  }
  final String uid, peer, chatId, publicKey;
  final SimpleKeyPair identity;
  LocalChatStore get store => LocalChatStore.of(uid, chatId);
  final connected = ValueNotifier<bool>(false);
  final status = ValueNotifier<String?>(null);
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _listener;
  bool _closed = false;
  Future<void>? _running;
  bool _again = false;
  static const chunkSize = 128 * 1024;
  static const maxBytes = 80 * 1024 * 1024;
  CollectionReference<Map<String, dynamic>> get _queue => FirebaseFirestore
      .instance
      .collection('chats')
      .doc(chatId)
      .collection('delivery_queue');

  void _listen() {
    _listener ??= _queue.snapshots().listen(
      (_) => wake(),
      onError: (Object error) {
        connected.value = false;
        status.value = error.toString();
        _listener?.cancel();
        _listener = null;
      },
    );
  }

  void wake() {
    unawaited(pump());
  }

  Future<void> pump() {
    if (_closed) return Future<void>.value();
    if (_running != null) {
      _again = true;
      return _running!;
    }
    final done = Completer<void>();
    _running = done.future;
    unawaited(() async {
      try {
        do {
          _again = false;
          await _pumpOnce();
        } while (_again && !_closed);
      } catch (error) {
        if (!_closed) {
          connected.value = false;
          status.value = error.toString();
        }
        debugPrint('WorldVoice encrypted delivery pending: $error');
      } finally {
        _running = null;
        done.complete();
      }
    }());
    return done.future;
  }

  Future<void> _pumpOnce() async {
    if (_closed) return;
    _listen();
    // Rules independently enforce blocks in both directions.
    final blocked = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('blocked_peers')
        .doc(peer)
        .get(const GetOptions(source: Source.server));
    if (_closed || blocked.exists) return;
    final incoming = await _queue.get(const GetOptions(source: Source.server));
    for (final envelope in incoming.docs) {
      if (_closed) return;
      if (envelope.data()['recipientId'] == uid &&
          envelope.data()['state'] == 'ready') {
        await _receive(envelope);
      }
    }
    for (final item in await store.messages()) {
      if (_closed) return;
      if (item['senderId'] == uid && item['delivered'] != true) {
        await _send(item);
      }
    }
    if (!_closed) {
      connected.value = true;
      status.value = null;
    }
  }

  Future<void> _send(Map<String, dynamic> item) async {
    final messageId = item['id'] as String;
    var deliveryId = item['deliveryId']?.toString();
    if (deliveryId == null || deliveryId.isEmpty) {
      deliveryId = LocalChatStore.newId();
      final assigned = await store.patchIf(
        messageId,
        {'version': item['version'], 'deliveryId': item['deliveryId']},
        {'deliveryId': deliveryId},
      );
      if (!assigned) return;
    }
    final ref = _queue.doc(deliveryId);
    final previous = await ref.get(const GetOptions(source: Source.server));
    if (_closed) return;
    final prior = previous.data();
    if (prior?['state'] == 'received') {
      await store.patchIf(
        messageId,
        {'deliveryId': deliveryId},
        {'delivered': true, 'pendingOp': ''},
      );
      await ref.delete(); // payload has already been deleted by the receiver
      return;
    }
    final expires = prior?['expiresAt'] as Timestamp?;
    if (prior?['state'] == 'ready' &&
        expires != null &&
        expires.toDate().isAfter(DateTime.now()))
      return;
    final peerKey = await FirebaseFirestore.instance
        .collection('chat_delivery_keys')
        .doc(peer)
        .get(const GetOptions(source: Source.server));
    final remote = peerKey.data()?['publicKey'] as String?;
    if (remote == null)
      throw StateError('The recipient needs to open the updated app once.');
    final context = '$chatId/$deliveryId';
    final key = await ChatDeliveryCrypto.derive(identity, remote, context);
    final path = item['filePath']?.toString() ?? '';
    final withdrawn = item['withdrawn'] == true;
    final hasFile = path.isNotEmpty && !withdrawn;
    final file = hasFile ? File(path) : null;
    final length = file == null ? 0 : await file.length();
    if (length > maxBytes) throw StateError('Attachment exceeds 80 MB.');
    final count = 1 + (length / chunkSize).ceil();
    final expiry = Timestamp.fromDate(
      DateTime.now().add(const Duration(days: 7)),
    );
    await ref.set({
      'senderId': uid,
      'recipientId': peer,
      'senderKey': publicKey,
      'recipientKey': remote,
      'state': 'uploading',
      'chunkCount': count,
      'expiresAt': expiry,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final metadata = <String, dynamic>{
      'id': messageId,
      'senderId': uid,
      'type': item['type'],
      'text': item['text'] ?? '',
      'createdAt': item['createdAt'],
      'version': item['version'] ?? (item['createdAt'] as int) * 1000,
      'bubbleId': item['bubbleId'] ?? 'free',
      'edited': item['edited'] == true,
      'withdrawn': withdrawn,
      'fileName': item['fileName'] ?? '',
      'fileSize': length,
    };
    Future<void> writeChunk(int index, List<int> bytes) async {
      if (_closed) throw StateError('Delivery account changed.');
      final encrypted = await ChatDeliveryCrypto.seal(
        bytes,
        key,
        '$context/$index',
      );
      await ref.collection('delivery_chunks').doc('$index').set({
        ...encrypted,
        'expiresAt': expiry,
      });
    }

    await writeChunk(0, utf8.encode(jsonEncode(metadata)));
    if (file != null) {
      final handle = await file.open();
      try {
        for (var i = 1; i < count; i++) {
          await writeChunk(i, await handle.read(chunkSize));
        }
      } finally {
        await handle.close();
      }
    }
    if (_closed) return;
    await ref.update({
      'state': 'ready',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _receive(
    QueryDocumentSnapshot<Map<String, dynamic>> envelope,
  ) async {
    final header = envelope.data();
    if (header['senderId'] != peer || header['recipientKey'] != publicKey)
      return;
    final expiry = header['expiresAt'] as Timestamp;
    if (expiry.toDate().isBefore(DateTime.now())) return;
    final count = header['chunkCount'] as int;
    if (count < 1 || count > 641) throw StateError('Invalid delivery size.');
    final context = '$chatId/${envelope.id}';
    final key = await ChatDeliveryCrypto.derive(
      identity,
      header['senderKey'] as String,
      context,
    );
    final chunks = envelope.reference.collection('delivery_chunks');
    final existing = await store.messages();
    // After a crash during cleanup, finish deleting without redownloading.
    final alreadySaved = existing.any(
      (m) => (m['receivedDeliveries'] as List?)?.contains(envelope.id) == true,
    );
    if (!alreadySaved) {
      Future<List<int>> readChunk(int index) async {
        if (_closed) throw StateError('Delivery account changed.');
        final doc = await chunks
            .doc('$index')
            .get(const GetOptions(source: Source.server));
        if (!doc.exists) throw StateError('Incomplete encrypted attachment.');
        return ChatDeliveryCrypto.open(doc.data()!, key, '$context/$index');
      }

      final data = Map<String, dynamic>.from(
        jsonDecode(utf8.decode(await readChunk(0))) as Map,
      );
      final id = data['id'];
      final length = data['fileSize'];
      if (id is! String ||
          !RegExp(r'^[a-zA-Z0-9_-]{1,160}$').hasMatch(id) ||
          data['senderId'] != peer ||
          data['text'] is! String ||
          data['createdAt'] is! int ||
          data['version'] is! int ||
          length is! int ||
          length < 0 ||
          length > maxBytes ||
          count != 1 + (length / chunkSize).ceil()) {
        throw StateError('Invalid encrypted message.');
      }
      final matches = existing.where((m) => m['id'] == id);
      final old = matches.isEmpty ? null : matches.first;
      if (old != null && old['senderId'] != peer)
        throw StateError('Message identity mismatch.');
      final oldVersion = (old?['version'] as int?) ?? -1;
      final receipts = <dynamic>[
        ...(old?['receivedDeliveries'] as List? ?? const []),
        envelope.id,
      ];
      if (oldVersion <= (data['version'] as int)) {
        String path = '';
        if (length > 0) {
          final root = await getApplicationSupportDirectory();
          final folder = Directory('${root.path}/worldvoice_peer_media/$uid');
          await folder.create(recursive: true);
          final ext = (data['fileName'] as String)
              .split('.')
              .last
              .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
              .substring(
                0,
                min(
                  12,
                  (data['fileName'] as String)
                      .split('.')
                      .last
                      .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
                      .length,
                ),
              );
          final target = File('${folder.path}/${envelope.id}.$ext');
          final temp = File('${target.path}.part');
          final sink = temp.openWrite();
          var total = 0;
          try {
            for (var i = 1; i < count; i++) {
              final bytes = await readChunk(i);
              total += bytes.length;
              if (total > length) throw StateError('Attachment size mismatch.');
              sink.add(bytes);
            }
            await sink.flush();
          } finally {
            await sink.close();
          }
          if (total != length) throw StateError('Attachment size mismatch.');
          await temp.rename(target.path);
          path = target.path;
        }
        if (_closed) return;
        await store.upsert({
          ...data,
          'filePath': path,
          'hidden': old?['hidden'] == true,
          'delivered': true,
          'read': false,
          'receivedDeliveries': receipts,
        });
      } else {
        await store.patch(id, {'receivedDeliveries': receipts});
      }
    }
    // ACK is only written AFTER the durable local copy and server payload deletion.
    for (var offset = 0; offset < count; offset += 200) {
      if (_closed) return;
      final batch = FirebaseFirestore.instance.batch();
      for (var i = offset; i < min(count, offset + 200); i++) {
        batch.delete(chunks.doc('$i'));
      }
      await batch.commit();
    }
    if (!_closed)
      await envelope.reference.update({
        'state': 'received',
        'updatedAt': FieldValue.serverTimestamp(),
      });
  }

  void close() {
    _closed = true;
    store.revision.removeListener(wake);
    _listener?.cancel();
    connected.value = false;
    // Notifiers may still be held by a screen while logout navigation completes.
  }
}
