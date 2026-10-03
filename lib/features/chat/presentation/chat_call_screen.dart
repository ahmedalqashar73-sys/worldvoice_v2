import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../rooms/services/agora_voice_room_controller.dart';

const MethodChannel _chatCallPermissionChannel =
    MethodChannel('worldvoice/live_permissions');

class ChatCallScreen extends StatefulWidget {
  const ChatCallScreen({
    required this.callId,
    required this.initialData,
    super.key,
  });

  final String callId;
  final Map<String, dynamic> initialData;

  static Future<void> startOutgoing(
    BuildContext context, {
    required String peerId,
    required String peerName,
    required bool video,
  }) async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null || peerId.isEmpty || peerId == authUser.uid) return;

    final db = FirebaseFirestore.instance;
    final callerSnap = await db.collection('users').doc(authUser.uid).get();
    final peerSnap = await db.collection('users').doc(peerId).get();

    if (!context.mounted) return;

    final caller = callerSnap.data() ?? const <String, dynamic>{};
    final peer = peerSnap.data() ?? const <String, dynamic>{};

    final callerName = (caller['displayName'] ??
            caller['name'] ??
            authUser.displayName ??
            'WorldVoice')
        .toString();
    final callerPhoto =
        (caller['photoUrl'] ?? authUser.photoURL ?? '').toString();
    final resolvedPeerName =
        (peer['displayName'] ?? peer['name'] ?? peerName).toString();
    final peerPhoto = (peer['photoUrl'] ?? '').toString();

    final ref = db.collection('calls').doc();
    final channelId = 'call_${ref.id}';
    final data = <String, dynamic>{
      'callerId': authUser.uid,
      'calleeId': peerId,
      'callerName': callerName,
      'calleeName': resolvedPeerName,
      'callerPhotoUrl': callerPhoto,
      'calleePhotoUrl': peerPhoto,
      'callType': video ? 'video' : 'audio',
      'channelId': channelId,
      'status': 'ringing',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await ref.set(data);
    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => ChatCallScreen(
          callId: ref.id,
          initialData: data,
        ),
      ),
    );
  }

  static Future<void> acceptIncoming(
    BuildContext context, {
    required String callId,
    required Map<String, dynamic> data,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || data['calleeId'] != uid) return;

    final ref = FirebaseFirestore.instance.collection('calls').doc(callId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = snap.data();
      if (!snap.exists || current?['status'] != 'ringing') {
        throw StateError('CALL_NO_LONGER_RINGING');
      }
      tx.update(ref, {
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => ChatCallScreen(
          callId: callId,
          initialData: <String, dynamic>{
            ...data,
            'status': 'accepted',
          },
        ),
      ),
    );
  }

  static Future<void> declineIncoming({
    required String callId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ref = FirebaseFirestore.instance.collection('calls').doc(callId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists ||
          data?['calleeId'] != uid ||
          data?['status'] != 'ringing') {
        return;
      }
      tx.update(ref, {
        'status': 'declined',
        'endedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  State<ChatCallScreen> createState() => _ChatCallScreenState();
}

class _ChatCallScreenState extends State<ChatCallScreen> {
  final AgoraVoiceRoomController _controller = AgoraVoiceRoomController();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _callSub;
  late Map<String, dynamic> _call;
  bool _connecting = false;
  bool _connected = false;
  bool _ending = false;
  bool _micMuted = false;
  bool _remoteEnded = false;
  String? _error;

  String get _status => (_call['status'] ?? 'ringing').toString();
  bool get _video => (_call['callType'] ?? 'audio') == 'video';
  String get _channelId => (_call['channelId'] ?? '').toString();

  String get _peerId {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return (_call['callerId'] == uid
            ? _call['calleeId']
            : _call['callerId'])
        .toString();
  }

  String get _peerName {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return (_call['callerId'] == uid
            ? _call['calleeName']
            : _call['callerName'])
        .toString();
  }

  String get _peerPhoto {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return (_call['callerId'] == uid
            ? _call['calleePhotoUrl']
            : _call['callerPhotoUrl'])
        .toString();
  }

  bool get _isCaller =>
      _call['callerId'] == FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _call = Map<String, dynamic>.from(widget.initialData);
    _controller.addListener(_controllerChanged);
    _callSub = FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .snapshots()
        .listen(_onCallChanged);

    if (_status == 'accepted') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_connect());
      });
    }
  }

  void _controllerChanged() {
    if (mounted) setState(() {});
  }

  void _onCallChanged(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (!mounted || data == null) return;
    final oldStatus = _status;
    setState(() => _call = data);
    final status = (data['status'] ?? '').toString();

    if (status == 'accepted' && !_connected && !_connecting) {
      unawaited(_connect());
    }

    if (status == 'declined' ||
        status == 'cancelled' ||
        status == 'ended') {
      _remoteEnded = oldStatus != status;
      unawaited(_leaveMedia());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  Future<bool> _requestCamera() async {
    if (!_video || kIsWeb) return true;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return true;
    }
    try {
      return await _chatCallPermissionChannel
              .invokeMethod<bool>('requestCamera') ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> _connect() async {
    if (_connecting || _connected || _channelId.isEmpty) return;
    setState(() {
      _connecting = true;
      _error = null;
    });

    try {
      if (_video && !await _requestCamera()) {
        throw StateError('Camera permission is required for video calls.');
      }

      await _controller.ensureConnected(
        channelId: _channelId,
        role: AgoraRoomRole.speaker,
        previewCamera: _video,
      );

      if (!mounted) return;
      if (_video) {
        await _controller.setCameraPublishing(true);
      }
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _connected = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _error = error.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  Future<void> _leaveMedia() async {
    try {
      await _controller.leave();
    } catch (_) {
      // Cleanup is best effort.
    }
  }

  Future<void> _endCall() async {
    if (_ending) return;
    _ending = true;

    final ref =
        FirebaseFirestore.instance.collection('calls').doc(widget.callId);
    try {
      final snap = await ref.get();
      final data = snap.data();
      if (data != null) {
        final status = (data['status'] ?? '').toString();
        if (status == 'ringing' && _isCaller) {
          await ref.update({
            'status': 'cancelled',
            'endedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else if (status == 'ringing' && !_isCaller) {
          await ref.update({
            'status': 'declined',
            'endedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else if (status == 'accepted') {
          await ref.update({
            'status': 'ended',
            'endedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (_) {
      // The local call screen must still close if the status update fails.
    }

    await _leaveMedia();
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    unawaited(_callSub?.cancel());
    _controller.removeListener(_controllerChanged);
    if (!_remoteEnded && !_ending) {
      final ref =
          FirebaseFirestore.instance.collection('calls').doc(widget.callId);
      unawaited(ref.get().then((snap) async {
        final data = snap.data();
        if (data == null) return;
        final status = (data['status'] ?? '').toString();
        if (status == 'accepted') {
          await ref.update({
            'status': 'ended',
            'endedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else if (status == 'ringing' && _isCaller) {
          await ref.update({
            'status': 'cancelled',
            'endedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }).catchError((Object _) {}));
    }
    unawaited(_controller.leave());
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final statusText = switch (_status) {
      'ringing' => _isCaller
          ? (ar ? 'جاري الاتصال...' : 'Calling...')
          : (ar ? 'مكالمة واردة' : 'Incoming call'),
      'accepted' => _connecting
          ? (ar ? 'جاري الاتصال...' : 'Connecting...')
          : (ar ? 'متصل' : 'Connected'),
      'declined' => ar ? 'تم الرفض' : 'Declined',
      'cancelled' => ar ? 'تم الإلغاء' : 'Cancelled',
      'ended' => ar ? 'انتهت المكالمة' : 'Call ended',
      _ => ar ? 'مكالمة' : 'Call',
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_endCall());
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final engine = _controller.engine;
              final remote = _controller.remoteSpeakers;

              return Stack(
                fit: StackFit.expand,
                children: [
                  if (_video &&
                      _connected &&
                      engine != null &&
                      remote.isNotEmpty)
                    AgoraVideoView(
                      controller: VideoViewController.remote(
                        rtcEngine: engine,
                        canvas: VideoCanvas(uid: remote.first),
                        connection: RtcConnection(channelId: _channelId),
                      ),
                    )
                  else
                    _AudioCallBackground(
                      peerName: _peerName,
                      peerPhoto: _peerPhoto,
                      statusText: statusText,
                      video: _video,
                    ),
                  if (_video && _connected && engine != null)
                    PositionedDirectional(
                      top: 24,
                      end: 18,
                      width: 112,
                      height: 162,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: engine,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        ),
                      ),
                    ),
                  PositionedDirectional(
                    top: 14,
                    start: 14,
                    end: 14,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _video
                                ? (ar ? 'مكالمة فيديو' : 'Video call')
                                : (ar ? 'مكالمة صوتية' : 'Voice call'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null)
                    PositionedDirectional(
                      start: 24,
                      end: 24,
                      bottom: 150,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xCC7F1D1D),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  PositionedDirectional(
                    start: 20,
                    end: 20,
                    bottom: 28,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (_connected)
                          _CallCircleButton(
                            icon: _micMuted
                                ? Icons.mic_off_rounded
                                : Icons.mic_rounded,
                            label: ar ? 'المايك' : 'Mic',
                            onPressed: () async {
                              final next = !_micMuted;
                              await _controller.setMuted(next);
                              if (mounted) {
                                setState(() => _micMuted = next);
                              }
                            },
                          ),
                        if (_video && _connected)
                          _CallCircleButton(
                            icon: Icons.cameraswitch_rounded,
                            label: ar ? 'تبديل' : 'Flip',
                            onPressed: _controller.switchCamera,
                          ),
                        _CallCircleButton(
                          icon: Icons.call_end_rounded,
                          label: ar ? 'إنهاء' : 'End',
                          destructive: true,
                          onPressed: _endCall,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AudioCallBackground extends StatelessWidget {
  const _AudioCallBackground({
    required this.peerName,
    required this.peerPhoto,
    required this.statusText,
    required this.video,
  });

  final String peerName;
  final String peerPhoto;
  final String statusText;
  final bool video;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF123D31), Color(0xFF07110E)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 62,
                backgroundImage:
                    peerPhoto.trim().isEmpty ? null : NetworkImage(peerPhoto),
                child: peerPhoto.trim().isEmpty
                    ? const Icon(Icons.person_rounded, size: 60)
                    : null,
              ),
              const SizedBox(height: 18),
              Text(
                peerName.isEmpty ? 'WorldVoice' : peerName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                statusText,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
              if (video) ...[
                const SizedBox(height: 12),
                const Icon(
                  Icons.videocam_rounded,
                  color: Colors.white54,
                  size: 30,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CallCircleButton extends StatelessWidget {
  const _CallCircleButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final FutureOr<void> Function() onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor:
                destructive ? const Color(0xFFE53935) : const Color(0xCCFFFFFF),
            foregroundColor:
                destructive ? Colors.white : const Color(0xFF152019),
            minimumSize: const Size(58, 58),
          ),
          onPressed: () => onPressed(),
          icon: Icon(icon, size: 27),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
