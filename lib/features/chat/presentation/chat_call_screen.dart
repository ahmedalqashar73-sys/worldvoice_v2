import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

import '../../rooms/services/agora_voice_room_controller.dart';
import '../../../core/localization/locale_controller.dart';
import '../../home/presentation/home_screen.dart';
import '../services/chat_call_service.dart';

class ChatCallScreen extends StatefulWidget {
  const ChatCallScreen({
    required this.call,
    required this.peerName,
    required this.peerPhotoUrl,
    required this.accepted,
    super.key,
  });

  final ChatCallInfo call;
  final String peerName;
  final String peerPhotoUrl;
  final bool accepted;

  @override
  State<ChatCallScreen> createState() => _ChatCallScreenState();
}

class _ChatCallScreenState extends State<ChatCallScreen> {
  final ChatCallService _service = ChatCallService();
  final AgoraVoiceRoomController _controller = AgoraVoiceRoomController();
  Timer? _pollTimer;
  Timer? _clockTimer;
  Timer? _ringTimeout;
  DateTime? _connectedAt;
  bool _accepted = false;
  bool _ending = false;
  bool _minimized = false;
  OverlayEntry? _miniEntry;
  LocaleController? _miniLocale;
  bool _speaker = true;
  bool _camera = false;
  String? _error;

  bool get _isVideo => widget.call.isVideo;

  @override
  void initState() {
    super.initState();
    _accepted = widget.accepted;
    _controller.addListener(_onControllerChanged);
    if (_accepted) {
      unawaited(_connect());
    } else {
      _startPolling();
      _ringTimeout = Timer(const Duration(seconds: 45), () {
        if (mounted && !_accepted && !_ending) {
          unawaited(_end());
        }
      });
    }
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => unawaited(_pollStatus()),
    );
    unawaited(_pollStatus());
  }

  Future<void> _pollStatus() async {
    if (_ending) return;
    try {
      final status = await _service.status(widget.call.id);
      if (!mounted) return;
      if (status == 'accepted' && !_accepted) {
        _accepted = true;
        _ringTimeout?.cancel();
        _pollTimer?.cancel();
        await _connect();
        return;
      }
      if (status == 'declined' || status == 'ended') {
        await _closeAfterRemoteEnd();
      }
    } catch (_) {}
  }

  Future<void> _connect() async {
    try {
      await _controller.ensureConnected(
        channelId: widget.call.channelId,
        role: AgoraRoomRole.speaker,
        previewCamera: _isVideo,
      );
      if (!mounted) return;
      if (_isVideo) {
        await _controller.setCameraPublishing(true);
      }
      final engine = _controller.engine;
      if (engine != null) {
        await engine.setEnableSpeakerphone(true);
      }
      _connectedAt = DateTime.now();
      _clockTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) { if (mounted) setState(() {}); },
      );
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => unawaited(_pollStatus()),
      );
      setState(() {
        _camera = _isVideo;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  String _durationText() {
    final start = _connectedAt;
    if (start == null) return _accepted ? 'Connecting...' : 'Ringing...';
    final elapsed = DateTime.now().difference(start).inSeconds;
    final minutes = elapsed ~/ 60;
    final seconds = elapsed % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleSpeaker() async {
    final engine = _controller.engine;
    if (engine == null) return;
    final next = !_speaker;
    await engine.setEnableSpeakerphone(next);
    if (mounted) setState(() => _speaker = next);
  }

  Future<void> _toggleCamera() async {
    if (!_isVideo) return;
    final next = !_camera;
    await _controller.setCameraPublishing(next);
    if (mounted) setState(() => _camera = next);
  }

  Future<void> _closeAfterRemoteEnd() async {
    if (_ending) return;
    if (mounted) setState(() => _ending = true);
    await _controller.leave().catchError((Object _) {});
    await _popCallRoute();
  }

  Future<void> _popCallRoute() async {
    if (!mounted) return;
    final nav = Navigator.of(context);
    final callRoute = ModalRoute.of(context);
    if (_minimized && callRoute != null) {
      nav.popUntil((route) => identical(route, callRoute));
    }
    await WidgetsBinding.instance.endOfFrame;
    if (mounted && nav.canPop()) nav.pop();
  }

  /// Minimize within WorldVoice, without disposing the Agora engine or call.
  /// The caller can browse chats and other tabs while the mini card stays up.
  Future<void> _minimize() async {
    if (!mounted || _minimized || _ending || !_controller.joined) return;
    final callRoute = ModalRoute.of(context);
    if (callRoute == null) return;
    final locale = LocaleController();
    await locale.load();
    if (!mounted || _minimized || _ending) {
      locale.dispose();
      return;
    }
    final navigator = Navigator.of(context);
    _miniLocale = locale;
    setState(() => _minimized = true);
    final browsing = MaterialPageRoute<void>(
      builder: (_) => HomeScreen(
        localeController: locale, initialTab: 3,
      ),
    );
    unawaited(navigator.push<void>(browsing).whenComplete(() {
      _miniEntry?.remove();
      _miniEntry?.dispose();
      _miniEntry = null;
      _miniLocale?.dispose();
      _miniLocale = null;
      if (mounted) setState(() => _minimized = false);
    }));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_minimized || !browsing.isActive) return;
      _miniEntry = OverlayEntry(
        builder: (_) => PositionedDirectional(
          top: 105,
          end: 12,
          child: SafeArea(
            child: Material(
              elevation: 12,
              color: const Color(0xFF0D4937),
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                key: const ValueKey('restore-direct-call'),
                onTap: () => navigator.popUntil(
                    (route) => identical(route, callRoute)),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_isVideo
                          ? Icons.video_call_rounded : Icons.call_rounded,
                        color: Colors.white),
                      const SizedBox(width: 8),
                      Text(widget.peerName,
                        style: const TextStyle(color: Colors.white)),
                      const SizedBox(width: 8),
                      const Icon(Icons.open_in_full_rounded,
                        color: Color(0xFFEAD08D), size: 17),
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

  Future<void> _end() async {
    if (_ending) return;
    if (mounted) setState(() => _ending = true);
    try {
      await _service.end(widget.call.id);
    } catch (_) {}
    await _controller.leave().catchError((Object _) {});
    await _popCallRoute();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _clockTimer?.cancel();
    _ringTimeout?.cancel();
    _miniEntry?.remove();
    _miniEntry?.dispose();
    _miniEntry = null;
    _miniLocale?.dispose();
    _miniLocale = null;
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = _controller.engine;
    final remote = _controller.remoteSpeakers;
    final photo = widget.peerPhotoUrl.trim();
    final connected = _controller.joined;

    Widget center;
    if (_isVideo && connected && engine != null && remote.isNotEmpty) {
      center = Stack(
        fit: StackFit.expand,
        children: [
          AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: engine,
              canvas: VideoCanvas(uid: remote.first),
              connection: RtcConnection(channelId: widget.call.channelId),
            ),
          ),
          if (_camera)
            PositionedDirectional(
              end: 16,
              top: 16,
              width: 108,
              height: 152,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: engine,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                ),
              ),
            ),
        ],
      );
    } else {
      center = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 58,
            backgroundImage: photo.isEmpty ? null : NetworkImage(photo),
            child: photo.isEmpty
                ? const Icon(Icons.person_rounded, size: 58)
                : null,
          ),
          const SizedBox(height: 20),
          Text(
            widget.peerName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _durationText(),
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ],
      );
    }

    return PopScope(
      canPop: _ending,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_ending) unawaited(_minimize());
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF07120F),
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              center,
              PositionedDirectional(
                top: 10,
                start: 12,
                child: SafeArea(
                  child: IconButton.filledTonal(
                    tooltip: Localizations.localeOf(context).languageCode == 'ar'
                        ? 'تصغير المكالمة'
                        : 'Minimize call',
                    onPressed: connected ? _minimize : null,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CallButton(
                      icon: _controller.muted
                          ? Icons.mic_off_rounded
                          : Icons.mic_rounded,
                      onTap: connected
                          ? () => _controller.setMuted(!_controller.muted)
                          : null,
                    ),
                    _CallButton(
                      icon: _speaker
                          ? Icons.volume_up_rounded
                          : Icons.hearing_rounded,
                      onTap: connected ? _toggleSpeaker : null,
                    ),
                    if (_isVideo)
                      _CallButton(
                        icon: _camera
                            ? Icons.videocam_rounded
                            : Icons.videocam_off_rounded,
                        onTap: connected ? _toggleCamera : null,
                      ),
                    if (_isVideo)
                      _CallButton(
                        icon: Icons.cameraswitch_rounded,
                        onTap: connected ? _controller.switchCamera : null,
                      ),
                    _CallButton(
                      icon: Icons.call_end_rounded,
                      background: Colors.redAccent,
                      onTap: _end,
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

class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.icon,
    required this.onTap,
    this.background,
  });

  final IconData icon;
  final FutureOr<void> Function()? onTap;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      style: IconButton.styleFrom(
        backgroundColor: background ?? Colors.white24,
        foregroundColor: Colors.white,
        minimumSize: const Size.square(54),
      ),
      onPressed: onTap == null ? null : () => onTap!(),
      icon: Icon(icon),
    );
  }
}