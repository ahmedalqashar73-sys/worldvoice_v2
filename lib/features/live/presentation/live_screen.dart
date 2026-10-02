import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import '../../rooms/services/agora_voice_room_controller.dart';
import '../services/live_session_service.dart';

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
            Text(
              ar ? 'البثوث المباشرة الآن' : 'Live now',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: LiveSessionService().watchOpen(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ??
                    const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(ar
                        ? 'لا يوجد بث مباشر الآن. ابدأ أول Live.'
                        : 'No one is live yet. Start the first Live.'),
                  );
                }
                return Column(
                  children: [
                    for (final doc in docs)
                      Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.videocam_rounded),
                          ),
                          title: Text(
                            (doc.data()['topic'] as String?)?.trim().isNotEmpty == true
                                ? doc.data()['topic'].toString()
                                : doc.data()['hostName']?.toString() ??
                                    'WorldVoice Live',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            '${doc.data()['hostName'] ?? 'WorldVoice host'} • '
                            '${doc.data()['viewerCount'] ?? 0} 👁',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (_) => _LiveViewerScreen(
                                liveId: doc.id,
                                data: doc.data(),
                                ar: ar,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
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
  bool _micMuted = false;
  bool _requestsOpen = false;
  String? _channelId;
  String? _liveId;
  final LiveSessionService _liveService = LiveSessionService();

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
      _channelId = channel;
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
      final languageCode = Localizations.localeOf(context).languageCode;
      _liveId = await _liveService.create(
        channelId: channel,
        languageCode: languageCode,
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
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final remote = _controller.remoteSpeakers.take(3).toList();
                    final tiles = <Widget>[
                      AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: _controller.engine!,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      ),
                      for (final uid in remote)
                        AgoraVideoView(
                          controller: VideoViewController.remote(
                            rtcEngine: _controller.engine!,
                            canvas: VideoCanvas(uid: uid),
                            connection: RtcConnection(
                              channelId: _channelId ?? '',
                            ),
                          ),
                        ),
                    ];
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        _LiveVideoGrid(children: tiles),
                        PositionedDirectional(
                          top: 12,
                          start: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'LIVE  •  ${tiles.length}/4',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          bottom: 18,
                          start: 18,
                          child: FilledButton.icon(
                            onPressed: () => setState(
                              () => _requestsOpen = !_requestsOpen,
                            ),
                            icon: const Icon(Icons.group_add_rounded),
                            label: Text(widget.ar ? 'طلبات الانضمام' : 'Join requests'),
                          ),
                        ),
                        if (_requestsOpen && _liveId != null)
                          PositionedDirectional(
                            bottom: 72,
                            start: 14,
                            end: 14,
                            child: _HostJoinRequests(
                              liveId: _liveId!,
                              service: _liveService,
                              ar: widget.ar,
                            ),
                          ),
                        PositionedDirectional(
                          top: 12,
                          end: 12,
                          child: Row(
                            children: [
                              IconButton.filled(
                                tooltip: widget.ar ? 'المايك' : 'Microphone',
                                onPressed: () async {
                                  final next = !_micMuted;
                                  await _controller.setMuted(next);
                                  if (mounted) setState(() => _micMuted = next);
                                },
                                icon: Icon(_micMuted ? Icons.mic_off_rounded : Icons.mic_rounded),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                tooltip: widget.ar ? 'تبديل الكاميرا' : 'Switch camera',
                                onPressed: () => _controller.engine?.switchCamera(),
                                icon: const Icon(Icons.cameraswitch_rounded),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                tooltip: widget.ar ? 'إنهاء اللايف' : 'End live',
                                onPressed: () async {
                                  if (_liveId != null) await _liveService.end(_liveId!);
                                  await _controller.leave();
                                  if (!context.mounted) return;
                                  Navigator.of(context).pop();
                                },
                                icon: const Icon(Icons.stop_circle_rounded),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LiveViewerScreen extends StatefulWidget {
  const _LiveViewerScreen({
    required this.liveId,
    required this.data,
    required this.ar,
  });
  final String liveId;
  final Map<String, dynamic> data;
  final bool ar;

  @override
  State<_LiveViewerScreen> createState() => _LiveViewerScreenState();
}

class _LiveViewerScreenState extends State<_LiveViewerScreen> {
  final AgoraVoiceRoomController _controller = AgoraVoiceRoomController();
  final LiveSessionService _service = LiveSessionService();
  bool _joining = true;
  bool _requested = false;
  bool _guestPublishing = false;

  @override
  void initState() {
    super.initState();
    _join();
  }

  Future<void> _join() async {
    try {
      await _service.enterViewer(widget.liveId);
      await _controller.ensureConnected(
        channelId: widget.liveId,
        role: AgoraRoomRole.listener,
      );
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  void dispose() {
    _controller.leave();
    _service.leaveViewer(widget.liveId);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _requestCamera() async {
    await _service.requestToJoin(widget.liveId);
    if (mounted) setState(() => _requested = true);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _service.watchMyRequest(widget.liveId),
      builder: (context, requestSnapshot) {
        final status = requestSnapshot.data?.data()?['status']?.toString();
        if (status == 'accepted' && !_guestPublishing) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _becomeGuest());
        }
        return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _joining
            ? const Center(child: CircularProgressIndicator())
            : AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final remote = _controller.remoteSpeakers;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      if (remote.isNotEmpty && _controller.engine != null)
                        AgoraVideoView(
                          controller: VideoViewController.remote(
                            rtcEngine: _controller.engine!,
                            canvas: VideoCanvas(uid: remote.first),
                            connection: RtcConnection(channelId: widget.liveId),
                          ),
                        )
                      else
                        const Center(
                          child: Icon(Icons.live_tv_rounded,
                              color: Colors.white54, size: 72),
                        ),
                      PositionedDirectional(
                        top: 12,
                        start: 12,
                        child: IconButton.filledTonal(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                      PositionedDirectional(
                        bottom: 20,
                        start: 18,
                        end: 18,
                        child: Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _requested ? null : _requestCamera,
                                icon: const Icon(Icons.group_add_rounded),
                                label: Text(_requested
                                    ? (widget.ar ? 'تم إرسال الطلب' : 'Request sent')
                                    : (widget.ar ? 'اطلب الانضمام' : 'Request to join')),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton.filledTonal(
                              onPressed: () {},
                              icon: const Icon(Icons.chat_bubble_outline_rounded),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              onPressed: () {},
                              icon: const Icon(Icons.card_giftcard_rounded),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
      },
    );
  }

  Future<void> _becomeGuest() async {
    if (_guestPublishing || _controller.engine == null) return;
    _guestPublishing = true;
    try {
      final engine = _controller.engine!;
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
      if (mounted) setState(() {});
    } catch (_) {
      _guestPublishing = false;
      if (mounted) setState(() {});
    }
  }
}

class _HostJoinRequests extends StatelessWidget {
  const _HostJoinRequests({
    required this.liveId,
    required this.service,
    required this.ar,
  });

  final String liveId;
  final LiveSessionService service;
  final bool ar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      borderRadius: BorderRadius.circular(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 260),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: service.watchJoinRequests(liveId),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ??
                const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
            if (docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  ar ? 'لا توجد طلبات الآن.' : 'No requests right now.',
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_rounded),
                  ),
                  title: Text(
                    data['displayName']?.toString() ?? 'WorldVoice user',
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: ar ? 'رفض' : 'Decline',
                        onPressed: () => service.decideRequest(
                          liveId: liveId,
                          userId: doc.id,
                          accept: false,
                        ),
                        icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
                      ),
                      IconButton(
                        tooltip: ar ? 'قبول' : 'Accept',
                        onPressed: () => service.decideRequest(
                          liveId: liveId,
                          userId: doc.id,
                          accept: true,
                        ),
                        icon: const Icon(Icons.check_rounded, color: Colors.greenAccent),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _LiveVideoGrid extends StatelessWidget {
  const _LiveVideoGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.length == 1) return children.first;
    if (children.length == 2) {
      return Column(children: [
        Expanded(child: children[0]),
        Expanded(child: children[1]),
      ]);
    }
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: children.length == 3 ? .72 : .58,
      children: children,
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
