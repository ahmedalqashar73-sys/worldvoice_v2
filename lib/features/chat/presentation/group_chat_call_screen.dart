import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';
import '../../home/presentation/home_screen.dart';
import '../../profile/presentation/public_profile_screen.dart';
import '../../rooms/services/agora_voice_room_controller.dart';
import '../services/group_call_service.dart';

/// Audio and video share the same authenticated group session. Each member
/// explicitly joins before publishing; leaving never removes group membership.
class GroupChatCallScreen extends StatefulWidget {
  const GroupChatCallScreen({required this.call, super.key});
  final GroupCallInfo call;

  @override
  State<GroupChatCallScreen> createState() => _GroupChatCallScreenState();
}

class _GroupChatCallScreenState extends State<GroupChatCallScreen> {
  final AgoraVoiceRoomController _controller = AgoraVoiceRoomController();
  final GroupCallService _service = GroupCallService();
  Timer? _poll;
  GroupCallInfo? _current;
  bool _connecting = true;
  bool _ending = false;
  bool _muted = false;
  bool _cameraOff = false;
  bool _speaker = true;
  bool _minimized = false;
  String? _error;
  OverlayEntry? _miniEntry;
  LocaleController? _miniLocale;

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';
  bool get _isOwner =>
      (_current ?? widget.call).ownerId == FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _current = widget.call;
    _controller.addListener(_onAgoraChanged);
    unawaited(_connect());
  }

  void _onAgoraChanged() {
    if (mounted) {
      setState(() {});
      _miniEntry?.markNeedsBuild();
    }
  }

  Future<void> _connect() async {
    if (!mounted) return;
    setState(() {
      _connecting = true;
      _error = null;
    });
    try {
      final call = await _service.join(widget.call.chatId);
      if (!mounted) return;
      if (!call.isActive) throw StateError('Group call ended.');
      await _controller.ensureConnected(
        channelId: call.channelId,
        role: AgoraRoomRole.speaker,
        previewCamera: call.isVideo,
      );
      if (call.isVideo) await _controller.setCameraPublishing(true);
      final engine = _controller.engine;
      if (engine != null) await engine.setEnableSpeakerphone(true);
      if (!mounted) return;
      setState(() {
        _current = call;
        _connecting = false;
        _cameraOff = !call.isVideo;
      });
      _poll?.cancel();
      _poll = Timer.periodic(const Duration(seconds: 3), (_) {
        unawaited(_refreshStatus());
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _error = error.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  Future<void> _refreshStatus() async {
    if (_ending) return;
    try {
      final result = await _service.status(widget.call.chatId);
      if (!mounted) return;
      if (result == null || !result.isActive) {
        unawaited(_leave(remoteEnded: true));
        return;
      }
      if (!result.joinedIds.contains(FirebaseAuth.instance.currentUser?.uid)) {
        unawaited(_leave(remoteEnded: true));
        return;
      }
      setState(() => _current = result);
      _miniEntry?.markNeedsBuild();
    } catch (_) {
      // Temporary status outage must not kill an active Agora connection.
    }
  }

  Future<void> _toggleMic() async {
    try {
      await _controller.setMuted(!_controller.muted);
      if (mounted) setState(() => _muted = _controller.muted);
    } catch (error) {
      _feedback(error);
    }
  }

  Future<void> _toggleCamera() async {
    if (!(_current ?? widget.call).isVideo) return;
    try {
      await _controller.setCameraPublishing(_cameraOff);
      if (mounted) {
        setState(() => _cameraOff = !_controller.cameraPublishing);
      }
    } catch (error) {
      _feedback(error);
    }
  }

  Future<void> _toggleSpeaker() async {
    final engine = _controller.engine;
    if (engine == null) return;
    final next = !_speaker;
    await engine.setEnableSpeakerphone(next);
    if (mounted) setState(() => _speaker = next);
  }

  void _feedback(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString())),
    );
  }

  Future<void> _leave({bool remoteEnded = false, bool endAll = false}) async {
    if (_ending) return;
    if (mounted) setState(() => _ending = true);
    _poll?.cancel();
    try {
      if (!remoteEnded) {
        if (endAll && _isOwner) {
          await _service.end(widget.call.chatId);
        } else {
          await _service.leave(widget.call.chatId);
        }
      }
    } catch (error) {
      debugPrint('WorldVoice group call leave: $error');
    }
    await _controller.leave().catchError((Object _) {});
    if (!mounted) return;
    final navigator = Navigator.of(context);
    final original = ModalRoute.of(context);
    if (_minimized && original != null) {
      navigator.popUntil((route) => identical(route, original));
    }
    await WidgetsBinding.instance.endOfFrame;
    if (mounted && navigator.canPop()) navigator.pop();
  }

  Future<void> _minimize() async {
    if (!mounted || _minimized || _ending || !_controller.joined) return;
    final route = ModalRoute.of(context);
    if (route == null) return;
    final locale = LocaleController();
    await locale.load();
    if (!mounted || _minimized || _ending) {
      locale.dispose();
      return;
    }
    final navigator = Navigator.of(context);
    _miniLocale = locale;
    setState(() => _minimized = true);
    final home = MaterialPageRoute<void>(
      builder: (_) => HomeScreen(localeController: locale),
    );
    unawaited(navigator.push<void>(home).whenComplete(() {
      _miniEntry?.remove();
      _miniEntry?.dispose();
      _miniEntry = null;
      _miniLocale?.dispose();
      _miniLocale = null;
      if (mounted) setState(() => _minimized = false);
    }));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_minimized || !home.isActive) return;
      _miniEntry = OverlayEntry(
        builder: (_) => PositionedDirectional(
          top: 105,
          end: 12,
          child: SafeArea(
            child: Material(
              color: const Color(0xFF0D4937),
              elevation: 12,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () => navigator.popUntil((r) => identical(r, route)),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon((_current ?? widget.call).isVideo
                          ? Icons.video_call_rounded : Icons.call_rounded,
                          color: Colors.white),
                      const SizedBox(width: 8),
                      Text(widget.call.groupName,
                          style: const TextStyle(color: Colors.white)),
                      const SizedBox(width: 6),
                      const Icon(Icons.open_in_full_rounded,
                          color: Color(0xFFEAD08D), size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      Overlay.of(context, rootOverlay: true).insert(_miniEntry!);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _miniEntry?.remove();
    _miniEntry?.dispose();
    _miniEntry = null;
    _miniLocale?.dispose();
    _miniLocale = null;
    _controller.removeListener(_onAgoraChanged);
    if (!_ending) unawaited(_service.leave(widget.call.chatId).catchError((Object _) {}));
    unawaited(_controller.leave().catchError((Object _) {}));
    _controller.dispose();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final call = _current ?? widget.call;
    final joined = call.joinedIds.toSet();
    final mine = FirebaseAuth.instance.currentUser?.uid;
    final engine = _controller.engine;
    final remote = _controller.remoteSpeakers;
    final video = call.isVideo && !_cameraOff && _controller.joined;
    return PopScope(
      canPop: _ending,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_ending) unawaited(_minimize());
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF081A16),
        appBar: AppBar(
          backgroundColor: const Color(0xFF081A16),
          foregroundColor: Colors.white,
          leading: IconButton(
            tooltip: _ar ? 'تصغير المكالمة' : 'Minimize call',
            onPressed: _minimize,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(call.groupName,
                  style: const TextStyle(fontSize: 17)),
              Text(
                _ar
                    ? '${joined.length} في المكالمة • ${call.memberIds.length} أعضاء'
                    : '${joined.length} in call • ${call.memberIds.length} members',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_error!,
                    style: const TextStyle(color: Colors.orangeAccent)),
                ),
              if (_connecting)
                const LinearProgressIndicator(minHeight: 2),
              if (call.isVideo && video && engine != null && remote.isNotEmpty)
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * .27,
                  child: Row(
                    children: [
                      for (final uid in remote.take(3))
                        Expanded(
                          child: AgoraVideoView(
                            controller: VideoViewController.remote(
                              rtcEngine: engine,
                              canvas: VideoCanvas(uid: uid),
                              connection: RtcConnection(channelId: call.channelId),
                            ),
                          ),
                        ),
                      if (mine != null && !_cameraOff)
                        Expanded(
                          child: AgoraVideoView(
                            controller: VideoViewController(
                              rtcEngine: engine,
                              canvas: const VideoCanvas(uid: 0),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, layout) => GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: layout.maxWidth < 410 ? 3 : 4,
                      childAspectRatio: .78,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: call.memberIds.length,
                    itemBuilder: (context, index) {
                      final id = call.memberIds[index];
                      final active = joined.contains(id);
                      return _GroupCallMember(
                        userId: id,
                        name: call.memberNames[id] ?? 'WorldVoice',
                        active: active,
                        isSelf: id == mine,
                        muted: id == mine && _muted,
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton.filledTonal(
                      tooltip: _ar ? 'المايك' : 'Microphone',
                      onPressed: _controller.joined ? _toggleMic : null,
                      icon: Icon(_muted
                          ? Icons.mic_off_rounded : Icons.mic_rounded),
                    ),
                    IconButton.filledTonal(
                      tooltip: _ar ? 'السماعة' : 'Speaker',
                      onPressed: _controller.joined ? _toggleSpeaker : null,
                      icon: Icon(_speaker
                          ? Icons.volume_up_rounded : Icons.hearing_rounded),
                    ),
                    if (call.isVideo)
                      IconButton.filledTonal(
                        tooltip: _ar ? 'الكاميرا' : 'Camera',
                        onPressed: _controller.joined ? _toggleCamera : null,
                        icon: Icon(_cameraOff
                            ? Icons.videocam_off_rounded
                            : Icons.videocam_rounded),
                      ),
                    if (call.isVideo)
                      IconButton.filledTonal(
                        tooltip: _ar ? 'تبديل الكاميرا' : 'Switch camera',
                        onPressed: _controller.joined
                            ? _controller.switchCamera : null,
                        icon: const Icon(Icons.cameraswitch_rounded),
                      ),
                    IconButton.filled(
                      tooltip: _ar ? 'مغادرة المكالمة' : 'Leave call',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => unawaited(_leave()),
                      icon: const Icon(Icons.call_end_rounded),
                    ),
                    if (_isOwner)
                      IconButton.filledTonal(
                        tooltip: _ar ? 'إنهاء للجميع' : 'End for everyone',
                        onPressed: () => unawaited(_leave(endAll: true)),
                        icon: const Icon(Icons.group_remove_rounded),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupCallMember extends StatelessWidget {
  const _GroupCallMember({
    required this.userId,
    required this.name,
    required this.active,
    required this.isSelf,
    required this.muted,
  });

  final String userId;
  final String name;
  final bool active;
  final bool isSelf;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users')
          .doc(userId).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? const <String, dynamic>{};
        final photo = (data['photoUrl'] ?? '').toString().trim();
        final memberName = (data['displayName'] ?? name).toString();
        return InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PublicProfileScreen(userId: userId),
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active
                            ? const Color(0xFF37D49B)
                            : Colors.white24,
                        width: active ? 3 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: CircleAvatar(
                      foregroundImage: photo.isEmpty ? null : NetworkImage(photo),
                      child: photo.isEmpty
                          ? Text(memberName.isEmpty ? '?' : memberName[0].toUpperCase())
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                isSelf ? '$memberName • You' : memberName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                muted ? 'Muted' : active ? 'Connected' : 'Invited',
                style: TextStyle(
                  color: active ? const Color(0xFF60E6B4) : Colors.white54,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
