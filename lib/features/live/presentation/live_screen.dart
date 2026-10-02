import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import '../../rooms/services/agora_voice_room_controller.dart';

import '../../../core/localization/locale_controller.dart';

/// WorldVoice Live entry point.
///
/// Phase 1 deliberately keeps the existing voice-room implementation isolated:
/// Live is video-first and has no seats. The camera publishing screen is wired
/// separately so room audio behavior cannot regress.
class LiveScreen extends StatelessWidget {
  const LiveScreen({required this.localeController, super.key});

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final language = localeController.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    final ar = language == 'ar';
    final rtl = const {'ar', 'ur', 'fa'}.contains(language);

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFFF6FAF8),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B5D46), Color(0xFF11835D)],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.live_tv_rounded,
                      size: 42, color: Color(0xFFFFD57F)),
                  const SizedBox(height: 14),
                  Text(
                    ar ? 'WorldVoice Live' : 'WorldVoice Live',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ar
                        ? 'بث فيديو مباشر بدون مقاعد. الضيوف ينضمون بطلب، والأدوات تبقى مخفية حتى تحتاجها.'
                        : 'Seat-free live video. Guests join by request and tools stay hidden until needed.',
                    style: const TextStyle(color: Colors.white70, height: 1.45),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    key: const ValueKey('start-live'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0B5D46),
                    ),
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => _LiveCameraGate(ar: ar),
                      ),
                    ),
                    icon: const Icon(Icons.videocam_rounded),
                    label: Text(
                      ar ? 'ابدأ بثًا مباشرًا' : 'Start live',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _FeatureRow(
              icon: Icons.groups_2_rounded,
              title: ar ? 'حتى 4 أشخاص' : 'Up to 4 people',
              subtitle: ar
                  ? 'بدون مقاعد فارغة؛ الفيديو يتوزع تلقائيًا عند قبول الضيوف.'
                  : 'No empty seats; video lays out automatically as guests are accepted.',
            ),
            _FeatureRow(
              icon: Icons.dashboard_customize_rounded,
              title: ar ? 'أدوات مخفية' : 'Hidden tools',
              subtitle: ar
                  ? 'الشات، البورد، Teacher AI، الترجمة والهدايا تظهر من الأزرار فقط.'
                  : 'Chat, Board, Teacher AI, translation and gifts open only from controls.',
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveCameraGate extends StatefulWidget {
  const _LiveCameraGate({required this.ar});
  final bool ar;

  @override
  State<_LiveCameraGate> createState() => _LiveCameraGateState();
}

class _LiveCameraGateState extends State<_LiveCameraGate> {
  final AgoraVoiceRoomController _controller = AgoraVoiceRoomController();
  int _seconds = 20;
  bool _cameraReady = false;
  bool _starting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startCamera() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      // Use a unique preview channel for now. The Live session document will
      // provide the persistent channel id when discovery/guest join is wired.
      final channel = 'live_${DateTime.now().millisecondsSinceEpoch}';
      await _controller.ensureConnected(
        channelId: channel,
        role: AgoraRoomRole.speaker,
      );
      final engine = _controller.engine;
      if (engine == null || !_controller.joined) {
        throw StateError(_controller.error ?? 'Could not start Live.');
      }
      await engine.enableVideo();
      await engine.startPreview();
      await engine.updateChannelMediaOptions(
        const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          enableAudioRecordingOrPlayout: true,
        ),
      );
      if (!mounted) return;
      setState(() {
        _cameraReady = true;
        _starting = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _starting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _tick();
  }

  Future<void> _tick() async {
    while (mounted && !_cameraReady && _seconds > 0) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted || _cameraReady) return;
      setState(() => _seconds--);
      if (_seconds == 15) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.ar
                ? 'شغّل الكاميرا للاستمرار في البث.'
                : 'Turn on your camera to continue the live.'),
          ),
        );
      }
    }
    if (mounted && !_cameraReady && _seconds == 0) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_off_rounded,
                        color: Colors.white54, size: 72),
                    const SizedBox(height: 18),
                    Text(
                      widget.ar
                          ? 'شغّل الكاميرا قبل بدء اللايف'
                          : 'Turn on camera before going live',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.ar
                          ? 'سيتم إغلاق شاشة اللايف تلقائيًا بعد $_seconds ثانية إذا لم تعمل الكاميرا.'
                          : 'Live closes automatically in $_seconds seconds if the camera is not running.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: _starting ? null : _startCamera,
                      icon: const Icon(Icons.videocam_rounded),
                      label: Text(_starting
                          ? (widget.ar ? 'جاري تشغيل الكاميرا...' : 'Starting camera...')
                          : (widget.ar ? 'تشغيل الكاميرا' : 'Turn on camera')),
                    ),
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              top: 10,
              start: 10,
              child: IconButton.filledTonal(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            if (_cameraReady && _controller.engine != null)
              Positioned.fill(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _controller.engine!,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    ),
                    PositionedDirectional(
                      top: 12,
                      end: 12,
                      child: Row(
                        children: [
                          IconButton.filled(
                            tooltip: widget.ar ? 'تبديل الكاميرا' : 'Switch camera',
                            onPressed: () => _controller.engine?.switchCamera(),
                            icon: const Icon(Icons.cameraswitch_rounded),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            tooltip: widget.ar ? 'إنهاء اللايف' : 'End live',
                            onPressed: () async {
                              await _controller.leave();
                              if (mounted) Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.stop_circle_rounded),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE4F3ED),
        foregroundColor: const Color(0xFF11835D),
        child: Icon(icon),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
    );
  }
}
