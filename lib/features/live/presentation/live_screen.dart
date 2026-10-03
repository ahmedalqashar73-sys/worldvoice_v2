import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:share_plus/share_plus.dart';

import '../../rooms/services/agora_voice_room_controller.dart';
import '../../rooms/presentation/room_board_screen.dart';
import '../../rooms/presentation/room_captions_sheet.dart';
import '../../rooms/presentation/room_teacher_ai_sheet.dart';
import '../../rooms/presentation/unified_gift_panel.dart';
import '../../rooms/presentation/room_gift_overlay.dart';
import '../../rooms/data/room_caption.dart';
import '../../rooms/data/room_feature_models.dart';
import '../../rooms/services/room_feature_service.dart';
import '../../rooms/services/room_caption_service.dart';
import '../../rooms/services/room_live_caption_controller.dart';
import '../../rooms/services/room_teacher_ai_service.dart';
import '../../rooms/services/room_translation_service.dart';
import '../services/live_session_service.dart';

import '../../../core/localization/locale_controller.dart';
import '../../profile/services/profile_social_service.dart';
import '../../profile/data/profile_language_catalog.dart';

const MethodChannel _livePermissionChannel =
    MethodChannel('worldvoice/live_permissions');
const MethodChannel _liveTtsChannel = MethodChannel('worldvoice/live_tts');

Future<void> _speakLiveTeacher(String text, String languageCode) async {
  final value = text.trim();
  if (value.isEmpty || kIsWeb) return;
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    return;
  }
  try {
    await _liveTtsChannel.invokeMethod<void>('speak', {
      'text': value,
      'languageCode': languageCode,
    });
  } on PlatformException {
    // Voice is optional; Teacher AI text must still work.
  } on MissingPluginException {
    // Older builds can continue without spoken Teacher AI.
  }
}

Future<bool> _requestLiveCameraPermission() async {
  if (kIsWeb) return true;
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    return true;
  }
  try {
    return await _livePermissionChannel.invokeMethod<bool>('requestCamera') ??
        false;
  } on PlatformException {
    return false;
  } on MissingPluginException {
    return false;
  }
}

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
                    onPressed: () async {
                      final setup = await _showLiveSetup(
                        context,
                        ar: ar,
                        initialLanguageCode: language,
                      );
                      if (setup == null || !context.mounted) return;
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (_) => _LiveCameraGate(
                            ar: ar,
                            topic: setup.topic,
                            languageCode: setup.languageCode,
                          ),
                        ),
                      );
                    },
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
                final rawDocs = snapshot.data?.docs ??
                    const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                final docs = rawDocs
                    .where((doc) => LiveSessionService.isFresh(doc.data()))
                    .toList(growable: false);
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
                            '${(doc.data()['languageCode'] ?? 'en').toString().toUpperCase()} • '
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

class _LiveSetupResult {
  const _LiveSetupResult({required this.topic, required this.languageCode});
  final String topic;
  final String languageCode;
}

Future<List<String>> _myLearningLanguageCodes(String fallback) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return <String>[fallback];
  try {
    final snap =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final raw = snap.data()?['learningLanguageCodes'];
    final codes = raw is List
        ? raw
            .map((value) => value.toString().trim())
            .where((code) =>
                code.isNotEmpty && ProfileLanguageCatalog.byCode(code) != null)
            .toSet()
            .toList(growable: false)
        : const <String>[];
    if (codes.isNotEmpty) return codes;
  } catch (_) {
    // Keep Live usable if the profile read is temporarily unavailable.
  }
  return <String>[fallback];
}

Future<_LiveSetupResult?> _showLiveSetup(
  BuildContext context, {
  required bool ar,
  required String initialLanguageCode,
}) async {
  final fallback =
      ProfileLanguageCatalog.byCode(initialLanguageCode) == null
          ? 'en'
          : initialLanguageCode;
  final learningCodes = await _myLearningLanguageCodes(fallback);
  if (!context.mounted) return null;

  return showModalBottomSheet<_LiveSetupResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _LiveSetupSheet(
      ar: ar,
      learningCodes: learningCodes,
    ),
  );
}

class _LiveSetupSheet extends StatefulWidget {
  const _LiveSetupSheet({
    required this.ar,
    required this.learningCodes,
  });

  final bool ar;
  final List<String> learningCodes;

  @override
  State<_LiveSetupSheet> createState() => _LiveSetupSheetState();
}

class _LiveSetupSheetState extends State<_LiveSetupSheet> {
  final TextEditingController _topic = TextEditingController();
  late String _languageCode;

  Future<void> _toggleHostCamera() async {
    if (!_cameraReady || _controller.engine == null) return;
    final turnOff = !_cameraPaused;
    try {
      await _controller.setCameraPublishing(!turnOff);
      if (!mounted) return;
      setState(() => _cameraPaused = turnOff);
      if (turnOff) {
        _startCameraOffGracePeriod();
      } else {
        _cameraOffTimer?.cancel();
        _cameraOffSeconds = 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.ar
                  ? 'تم تشغيل الكاميرا من جديد.'
                  : 'Camera is back on.',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  void _startCameraOffGracePeriod() {
    _cameraOffTimer?.cancel();
    _cameraOffSeconds = 0;
    _cameraOffTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_cameraPaused || _sessionClosed) {
        timer.cancel();
        return;
      }
      _cameraOffSeconds += 1;
      if (_cameraOffSeconds == 20 ||
          _cameraOffSeconds == 60 ||
          _cameraOffSeconds == 120) {
        final remaining = 180 - _cameraOffSeconds;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 6),
            content: Text(
              widget.ar
                  ? 'الكاميرا مغلقة. شغّلها للاستمرار في اللايف. سيتم إنهاء اللايف بعد $remaining ثانية.'
                  : 'Your camera is off. Turn it back on to keep the Live running. Live ends in $remaining seconds.',
            ),
          ),
        );
      }
      if (_cameraOffSeconds >= 180) {
        timer.cancel();
        unawaited(_endLiveAndPop());
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _languageCode = widget.learningCodes.first;
  }

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.ar ? 'جهّز البث المباشر' : 'Set up your Live',
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _topic,
            maxLength: 80,
            decoration: InputDecoration(
              labelText: widget.ar ? 'موضوع البث' : 'Live topic',
              hintText: widget.ar
                  ? 'مثال: نتعلم الإنجليزية معًا'
                  : 'Example: Learn English together',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (widget.learningCodes.length == 1)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.school_rounded),
              title: Text(widget.ar ? 'لغة التعلم' : 'Learning language'),
              subtitle:
                  Text(ProfileLanguageCatalog.label(_languageCode)),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _languageCode,
              isExpanded: true,
              decoration: InputDecoration(
                labelText:
                    widget.ar ? 'اختر لغة التعلم' : 'Choose learning language',
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final code in widget.learningCodes)
                  DropdownMenuItem(
                    value: code,
                    child: Text(
                      ProfileLanguageCatalog.label(code),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _languageCode = value);
              },
            ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                final topic = _topic.text.trim();
                if (topic.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        widget.ar
                            ? 'اكتب موضوعًا للبث أولًا.'
                            : 'Add a Live topic first.',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop(
                  _LiveSetupResult(
                    topic: topic,
                    languageCode: _languageCode,
                  ),
                );
              },
              icon: const Icon(Icons.videocam_rounded),
              label: Text(
                widget.ar ? 'ابدأ بالكاميرا' : 'Start camera',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveCameraGate extends StatefulWidget {
  const _LiveCameraGate({
    required this.ar,
    required this.topic,
    required this.languageCode,
  });
  final bool ar;
  final String topic;
  final String languageCode;

  @override
  State<_LiveCameraGate> createState() => _LiveCameraGateState();
}

class _LiveCameraGateState extends State<_LiveCameraGate> {
  final AgoraVoiceRoomController _controller = AgoraVoiceRoomController();
  int _seconds = 20;
  bool _cameraReady = false;
  bool _starting = false;
  bool _cameraPaused = false;
  String? _cameraStartError;
  bool _micMuted = false;
  bool _beautyEnabled = false;
  String _filterPreset = 'off';
  bool _backgroundBlurEnabled = false;
  double _cameraZoom = 1;
  bool _requestsOpen = false;
  bool _boardOpen = false;
  bool _sessionClosed = false;
  Timer? _heartbeatTimer;
  Timer? _cameraFailureTimer;
  Timer? _cameraOffTimer;
  int _cameraOffSeconds = 0;
  String? _channelId;
  String? _liveId;
  final LiveSessionService _liveService = LiveSessionService();

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _cameraFailureTimer?.cancel();
    _cameraOffTimer?.cancel();
    final liveId = _liveId;
    if (liveId != null && !_sessionClosed) {
      unawaited(_liveService.end(liveId).catchError((Object _) {}));
    }
    unawaited(_controller.leave());
    _controller.dispose();
    super.dispose();
  }

  Future<void> _shareHostLive() async {
    final liveId = _liveId;
    if (liveId == null) return;
    final host =
        FirebaseAuth.instance.currentUser?.displayName ?? 'WorldVoice host';
    await SharePlus.instance.share(
      ShareParams(
        title: 'WorldVoice Live',
        text: 'WorldVoice Live • ${widget.topic} • $host • $liveId',
      ),
    );
  }

  Future<void> _endLiveAndPop() async {
    if (_sessionClosed) return;
    _sessionClosed = true;
    _heartbeatTimer?.cancel();
    _cameraOffTimer?.cancel();
    final liveId = _liveId;
    if (liveId != null) {
      try {
        await _liveService.end(liveId);
      } catch (_) {
        _sessionClosed = false;
        rethrow;
      }
    }
    await _controller.leave();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      final liveId = _liveId;
      if (liveId == null || _sessionClosed) return;
      unawaited(
        _liveService.touchHostHeartbeat(liveId).catchError((Object _) {}),
      );
    });
  }

  Future<void> _startCamera() async {
    if (_starting || _cameraReady) return;
    _cameraFailureTimer?.cancel();
    setState(() {
      _starting = true;
      _cameraStartError = null;
      _seconds = 20;
    });
    try {
      final cameraAllowed = await _requestLiveCameraPermission();
      if (!cameraAllowed) {
        throw StateError(
          widget.ar
              ? 'اسمح باستخدام الكاميرا لبدء البث المباشر.'
              : 'Camera permission is required to start Live.',
        );
      }
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
      await _controller.setCameraPublishing(true);
      final hostAgoraUid = _controller.localUid;
      if (hostAgoraUid == null || hostAgoraUid <= 0) {
        throw StateError('Agora did not return a valid host UID.');
      }
      _liveId = await _liveService.create(
        channelId: channel,
        languageCode: widget.languageCode,
        hostAgoraUid: hostAgoraUid,
        topic: widget.topic,
      );
      _startHeartbeat();
      if (!mounted) return;
      _cameraFailureTimer?.cancel();
      setState(() {
        _cameraReady = true;
        _starting = false;
        _cameraPaused = false;
        _cameraStartError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _cameraStartError = error.toString();
      });
      _startFailureCountdown();
    }
  }

  void _startFailureCountdown() {
    _cameraFailureTimer?.cancel();
    _seconds = 20;
    _cameraFailureTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _cameraReady || _starting) {
        timer.cancel();
        return;
      }
      if (_seconds <= 1) {
        timer.cancel();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_cameraReady && !_starting) {
            Navigator.of(context).maybePop();
          }
        });
        return;
      }
      setState(() => _seconds--);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_startCamera());
    });
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
                    Icon(
                      _cameraStartError == null
                          ? Icons.videocam_rounded
                          : Icons.videocam_off_rounded,
                      color: Colors.white70,
                      size: 72,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _starting
                          ? (widget.ar
                              ? 'جاري تشغيل الكاميرا تلقائيًا...'
                              : 'Starting camera automatically...')
                          : (widget.ar
                              ? 'تعذّر تشغيل الكاميرا'
                              : 'Could not start camera'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _starting
                          ? (widget.ar
                              ? 'لا تحتاج تضغط أي زر. يبدأ اللايف فور جاهزية الكاميرا.'
                              : 'No button needed. Live starts as soon as the camera is ready.')
                          : (widget.ar
                              ? '${_cameraStartError ?? ''}\nسيتم إغلاق الشاشة بعد $_seconds ثانية إذا لم تُعِد المحاولة.'
                              : '${_cameraStartError ?? ''}\nThis screen closes in $_seconds seconds unless you retry.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (!_starting && !_cameraReady) ...[
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: _startCamera,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(
                          widget.ar ? 'إعادة المحاولة' : 'Retry',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              top: 10,
              start: 10,
              child: IconButton.filledTonal(
                onPressed: _cameraReady
                    ? _endLiveAndPop
                    : () => Navigator.of(context).pop(),
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
                      _cameraPaused
                          ? ColoredBox(
                              color: Colors.black,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.videocam_off_rounded,
                                      color: Colors.white70,
                                      size: 56,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      widget.ar
                                          ? 'الكاميرا مغلقة'
                                          : 'Camera off',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _PinchZoomCameraView(
                              controller: _controller,
                              zoom: _cameraZoom,
                              onZoomChanged: (value) {
                                if (mounted) setState(() => _cameraZoom = value);
                              },
                              child: AgoraVideoView(
                                controller: VideoViewController(
                                  rtcEngine: _controller.engine!,
                                  canvas: const VideoCanvas(uid: 0),
                                ),
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
                        if (_boardOpen && _liveId != null)
                          Positioned.fill(
                            child: RoomBoardScreen(
                              roomId: _liveId!,
                              parentCollection: 'live_sessions',
                              canWrite: true,
                              isHost: true,
                              agoraController: _controller,
                              embedded: true,
                              onClose: () => setState(() => _boardOpen = false),
                            ),
                          ),
                        if (_boardOpen && _controller.engine != null)
                          PositionedDirectional(
                            top: 58,
                            end: 12,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                width: 110,
                                height: 150,
                                child: _cameraPaused
                                    ? const ColoredBox(
                                        color: Colors.black,
                                        child: Icon(
                                          Icons.videocam_off_rounded,
                                          color: Colors.white70,
                                        ),
                                      )
                                    : AgoraVideoView(
                                        controller: VideoViewController(
                                          rtcEngine: _controller.engine!,
                                          canvas: const VideoCanvas(uid: 0),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        Positioned.fill(
                          child: _LiveLanguageToolsOverlay(
                            liveId: _liveId ?? '',
                            roomLanguageCode: widget.languageCode,
                            canPublish: !_micMuted,
                            displayName:
                                FirebaseAuth.instance.currentUser?.displayName ??
                                    'WorldVoice host',
                            ar: widget.ar,
                          ),
                        ),
                        if (_liveId != null)
                          Positioned.fill(
                            child: _LiveGiftEffects(liveId: _liveId!),
                          ),
                        PositionedDirectional(
                          top: 12,
                          start: 12,
                          child: StreamBuilder<
                              DocumentSnapshot<Map<String, dynamic>>>(
                            stream: _liveId == null
                                ? null
                                : _liveService.watch(_liveId!),
                            builder: (context, snapshot) {
                              final viewers =
                                  snapshot.data?.data()?['viewerCount'] ?? 0;
                              final user = FirebaseAuth.instance.currentUser;
                              final photo = user?.photoURL?.trim() ?? '';
                              return DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0xB3000000),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                    6,
                                    5,
                                    10,
                                    5,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundImage: photo.isEmpty
                                            ? null
                                            : NetworkImage(photo),
                                        child: photo.isEmpty
                                            ? const Icon(
                                                Icons.person_rounded,
                                                size: 15,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 7),
                                      ConstrainedBox(
                                        constraints:
                                            const BoxConstraints(maxWidth: 120),
                                        child: Text(
                                          user?.displayName ??
                                              (widget.ar
                                                  ? 'المضيف'
                                                  : 'Host'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'LIVE • $viewers 👁 • ${tiles.length}/4',
                                        style: const TextStyle(
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        PositionedDirectional(
                          bottom: 18,
                          start: 18,
                          child: Row(
                            children: [
                              FilledButton.icon(
                                onPressed: () => setState(
                                  () => _requestsOpen = !_requestsOpen,
                                ),
                                icon: const Icon(Icons.group_add_rounded),
                                label: Text(widget.ar ? 'طلبات الانضمام' : 'Join requests'),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                tooltip: widget.ar ? 'دردشة اللايف' : 'Live chat',
                                onPressed: _liveId == null
                                    ? null
                                    : () => _showLiveChat(
                                          context,
                                          service: _liveService,
                                          liveId: _liveId!,
                                          ar: widget.ar,
                                        ),
                                icon: const Icon(Icons.chat_bubble_outline_rounded),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                tooltip: widget.ar ? 'السبورة' : 'Board',
                                onPressed: _liveId == null
                                    ? null
                                    : () => setState(() => _boardOpen = !_boardOpen),
                                icon: Icon(
                                  _boardOpen
                                      ? Icons.dashboard_rounded
                                      : Icons.dashboard_outlined,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                tooltip: widget.ar ? 'الهدايا' : 'Gifts',
                                onPressed: _liveId == null
                                    ? null
                                    : () => _showLiveGifts(
                                          context,
                                          liveId: _liveId!,
                                          service: _liveService,
                                          hostId:
                                              FirebaseAuth.instance.currentUser?.uid ??
                                                  '',
                                          hostName:
                                              FirebaseAuth.instance.currentUser
                                                      ?.displayName ??
                                                  'WorldVoice host',
                                          ar: widget.ar,
                                        ),
                                icon: const Icon(Icons.card_giftcard_rounded),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                tooltip: widget.ar ? 'مشاركة اللايف' : 'Share Live',
                                onPressed:
                                    _liveId == null ? null : _shareHostLive,
                                icon: const Icon(Icons.share_rounded),
                              ),
                            ],
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
                                tooltip: _cameraPaused
                                    ? (widget.ar ? 'تشغيل الكاميرا' : 'Turn camera on')
                                    : (widget.ar ? 'إيقاف الكاميرا' : 'Turn camera off'),
                                onPressed: _toggleHostCamera,
                                icon: Icon(
                                  _cameraPaused
                                      ? Icons.videocam_off_rounded
                                      : Icons.videocam_rounded,
                                ),
                              ),
                              const SizedBox(width: 8),
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
                                tooltip: widget.ar ? 'الفلاتر والكاميرا' : 'Filters & camera',
                                onPressed: _cameraPaused
                                    ? null
                                    : () => _showLiveCameraTools(
                                  context,
                                  controller: _controller,
                                  ar: widget.ar,
                                  beautyEnabled: _beautyEnabled,
                                  filterPreset: _filterPreset,
                                  backgroundBlurEnabled: _backgroundBlurEnabled,
                                  zoom: _cameraZoom,
                                  onBeautyChanged: (value) {
                                    if (mounted) {
                                      setState(() => _beautyEnabled = value);
                                    }
                                  },
                                  onFilterPresetChanged: (value) {
                                    if (mounted) {
                                      setState(() => _filterPreset = value);
                                    }
                                  },
                                  onBackgroundBlurChanged: (value) {
                                    if (mounted) {
                                      setState(
                                        () => _backgroundBlurEnabled = value,
                                      );
                                    }
                                  },
                                  onZoomChanged: (value) {
                                    if (mounted) {
                                      setState(() => _cameraZoom = value);
                                    }
                                  },
                                ),
                                icon: const Icon(Icons.auto_fix_high_rounded),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                tooltip: widget.ar ? 'إنهاء اللايف' : 'End live',
                                onPressed: _endLiveAndPop,
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
  bool _hostSeen = false;
  bool _guestMicMuted = false;
  bool _guestBeautyEnabled = false;
  String _guestFilterPreset = 'off';
  bool _guestBackgroundBlurEnabled = false;
  double _guestCameraZoom = 1;
  bool _boardOpen = false;
  bool _following = false;
  bool _followBusy = false;

  @override
  void initState() {
    super.initState();
    _join();
    _loadFollow();
  }

  Future<void> _loadFollow() async {
    final hostId = widget.data['hostId']?.toString() ?? '';
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (hostId.isEmpty || me == null || me == hostId) return;
    try {
      final value = await ProfileSocialService.isFollowing(hostId);
      if (mounted) setState(() => _following = value);
    } catch (_) {
      // Follow status must never block Live playback.
    }
  }

  Future<void> _toggleFollow() async {
    if (_followBusy) return;
    final hostId = widget.data['hostId']?.toString() ?? '';
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (hostId.isEmpty || me == null || me == hostId) return;
    setState(() => _followBusy = true);
    try {
      await ProfileSocialService.toggleFollow(hostId);
      if (!mounted) return;
      setState(() => _following = !_following);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  Future<void> _shareLive() async {
    final topic = (widget.data['topic'] ?? '').toString().trim();
    final host = (widget.data['hostName'] ?? 'WorldVoice host').toString();
    await SharePlus.instance.share(
      ShareParams(
        title: 'WorldVoice Live',
        text: topic.isEmpty
            ? 'WorldVoice Live • $host • ${widget.liveId}'
            : 'WorldVoice Live • $topic • $host • ${widget.liveId}',
      ),
    );
  }

  Future<void> _join() async {
    var countedViewer = false;
    try {
      await _service.enterViewer(widget.liveId);
      countedViewer = true;
      await _controller.ensureConnected(
        channelId: widget.liveId,
        role: AgoraRoomRole.listener,
      );
    } catch (_) {
      if (countedViewer) {
        await _service.leaveViewer(widget.liveId).catchError((Object _) {});
      }
      rethrow;
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  void dispose() {
    unawaited(_service.leaveGuest(widget.liveId).catchError((Object _) {}));
    unawaited(
      _service.cancelPendingRequest(widget.liveId).catchError((Object _) {}),
    );
    unawaited(_service.leaveViewer(widget.liveId).catchError((Object _) {}));
    unawaited(_controller.leave());
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
      stream: _service.watch(widget.liveId),
      builder: (context, liveSnapshot) {
        final live = liveSnapshot.data?.data();
        if (liveSnapshot.hasData && live?['isLive'] != true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
        }
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _service.watchMyRequest(widget.liveId),
      builder: (context, requestSnapshot) {
        final status = requestSnapshot.data?.data()?['status']?.toString();
        if (status == 'accepted' && !_guestPublishing) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _becomeGuest());
        }
        if ((status == 'declined' || status == 'left') && _requested) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _requested = false);
          });
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
                  final hostAgoraUid =
                      (live?['hostAgoraUid'] as num?)?.toInt() ??
                          (widget.data['hostAgoraUid'] as num?)?.toInt();
                  if (hostAgoraUid != null && remote.contains(hostAgoraUid)) {
                    _hostSeen = true;
                  } else if (_hostSeen && hostAgoraUid != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    });
                  }
                  final engine = _controller.engine;
                  final tiles = <Widget>[
                    if (_guestPublishing && engine != null)
                      _PinchZoomCameraView(
                        controller: _controller,
                        zoom: _guestCameraZoom,
                        onZoomChanged: (value) {
                          if (mounted) {
                            setState(() => _guestCameraZoom = value);
                          }
                        },
                        child: AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: engine,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        ),
                      ),
                    if (engine != null)
                      for (final uid in remote.take(_guestPublishing ? 3 : 4))
                        AgoraVideoView(
                          controller: VideoViewController.remote(
                            rtcEngine: engine,
                            canvas: VideoCanvas(uid: uid),
                            connection: RtcConnection(channelId: widget.liveId),
                          ),
                        ),
                  ];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      if (tiles.isNotEmpty)
                        _LiveVideoGrid(children: tiles)
                      else
                        const Center(
                          child: Icon(Icons.live_tv_rounded,
                              color: Colors.white54, size: 72),
                        ),
                      if (_boardOpen)
                        Positioned.fill(
                          child: RoomBoardScreen(
                            roomId: widget.liveId,
                            parentCollection: 'live_sessions',
                            canWrite: _guestPublishing &&
                                (live?['boardWriteEnabled'] != false),
                            isHost: false,
                            agoraController: _controller,
                            embedded: true,
                            onClose: () => setState(() => _boardOpen = false),
                          ),
                        ),
                      if (_boardOpen && engine != null && remote.isNotEmpty)
                        PositionedDirectional(
                          top: 58,
                          end: 12,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: 110,
                              height: 150,
                              child: AgoraVideoView(
                                controller: VideoViewController.remote(
                                  rtcEngine: engine,
                                  canvas: VideoCanvas(uid: remote.first),
                                  connection:
                                      RtcConnection(channelId: widget.liveId),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: _LiveLanguageToolsOverlay(
                          liveId: widget.liveId,
                          roomLanguageCode:
                              (live?['languageCode'] ?? widget.data['languageCode'] ?? 'en')
                                  .toString(),
                          canPublish: _guestPublishing,
                          displayName:
                              FirebaseAuth.instance.currentUser?.displayName ??
                                  'WorldVoice user',
                          ar: widget.ar,
                        ),
                      ),
                      Positioned.fill(
                        child: _LiveGiftEffects(liveId: widget.liveId),
                      ),
                      PositionedDirectional(
                        top: 10,
                        start: 10,
                        end: 10,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0x99000000),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 17,
                                  backgroundImage: (() {
                                    final url = (live?['hostPhotoUrl'] ??
                                            widget.data['hostPhotoUrl'] ??
                                            '')
                                        .toString()
                                        .trim();
                                    return url.isEmpty ? null : NetworkImage(url);
                                  })(),
                                  child: ((live?['hostPhotoUrl'] ??
                                                  widget.data['hostPhotoUrl'] ??
                                                  '')
                                              .toString()
                                              .trim()
                                              .isEmpty)
                                      ? const Icon(Icons.person_rounded, size: 18)
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        (live?['hostName'] ??
                                                widget.data['hostName'] ??
                                                'WorldVoice host')
                                            .toString(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        'LIVE • ${live?['viewerCount'] ?? widget.data['viewerCount'] ?? 0} 👁',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if ((widget.data['hostId'] ?? '').toString() !=
                                    FirebaseAuth.instance.currentUser?.uid)
                                  FilledButton.tonal(
                                    onPressed:
                                        _followBusy ? null : _toggleFollow,
                                    child: Text(
                                      _following
                                          ? (widget.ar ? 'متابَع' : 'Following')
                                          : (widget.ar ? 'متابعة' : 'Follow'),
                                    ),
                                  ),
                                IconButton(
                                  tooltip: widget.ar ? 'مشاركة' : 'Share',
                                  onPressed: _shareLive,
                                  icon: const Icon(
                                    Icons.share_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        bottom: 20,
                        start: 18,
                        end: 18,
                        child: Row(
                          children: [
                            if (!_guestPublishing) ...[
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _requested ? null : _requestCamera,
                                  icon: const Icon(Icons.group_add_rounded),
                                  label: Text(_requested
                                      ? (widget.ar
                                          ? 'تم إرسال الطلب'
                                          : 'Request sent')
                                      : (widget.ar
                                          ? 'اطلب الانضمام'
                                          : 'Request to join')),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            IconButton.filledTonal(
                              onPressed: () => _showLiveChat(
                                context,
                                service: _service,
                                liveId: widget.liveId,
                                ar: widget.ar,
                              ),
                              icon: const Icon(Icons.chat_bubble_outline_rounded),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              tooltip: widget.ar ? 'السبورة' : 'Board',
                              onPressed: () =>
                                  setState(() => _boardOpen = !_boardOpen),
                              icon: Icon(
                                _boardOpen
                                    ? Icons.dashboard_rounded
                                    : Icons.dashboard_outlined,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_guestPublishing) ...[
                              IconButton.filledTonal(
                                tooltip: widget.ar ? 'المايك' : 'Microphone',
                                onPressed: () async {
                                  final next = !_guestMicMuted;
                                  await _controller.setMuted(next);
                                  if (mounted) {
                                    setState(() => _guestMicMuted = next);
                                  }
                                },
                                icon: Icon(
                                  _guestMicMuted
                                      ? Icons.mic_off_rounded
                                      : Icons.mic_rounded,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                tooltip: widget.ar
                                    ? 'أدوات الكاميرا'
                                    : 'Camera tools',
                                onPressed: () => _showLiveCameraTools(
                                  context,
                                  controller: _controller,
                                  ar: widget.ar,
                                  beautyEnabled: _guestBeautyEnabled,
                                  filterPreset: _guestFilterPreset,
                                  backgroundBlurEnabled:
                                      _guestBackgroundBlurEnabled,
                                  zoom: _guestCameraZoom,
                                  onBeautyChanged: (value) {
                                    if (mounted) {
                                      setState(
                                        () => _guestBeautyEnabled = value,
                                      );
                                    }
                                  },
                                  onFilterPresetChanged: (value) {
                                    if (mounted) {
                                      setState(
                                        () => _guestFilterPreset = value,
                                      );
                                    }
                                  },
                                  onBackgroundBlurChanged: (value) {
                                    if (mounted) {
                                      setState(
                                        () => _guestBackgroundBlurEnabled =
                                            value,
                                      );
                                    }
                                  },
                                  onZoomChanged: (value) {
                                    if (mounted) {
                                      setState(
                                        () => _guestCameraZoom = value,
                                      );
                                    }
                                  },
                                ),
                                icon: const Icon(Icons.auto_fix_high_rounded),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                tooltip: widget.ar
                                    ? 'اخرج من الكاميرا'
                                    : 'Leave camera',
                                onPressed: _leaveGuestCamera,
                                icon: const Icon(Icons.videocam_off_rounded),
                              ),
                            ]
                            else
                              IconButton.filledTonal(
                                tooltip: widget.ar
                                    ? 'هدايا اللايف'
                                    : 'Live gifts',
                                onPressed: () => _showLiveGifts(
                                  context,
                                  liveId: widget.liveId,
                                  service: _service,
                                  hostId: (live?['hostId'] ??
                                          widget.data['hostId'] ??
                                          '')
                                      .toString(),
                                  hostName: (live?['hostName'] ??
                                          widget.data['hostName'] ??
                                          'WorldVoice host')
                                      .toString(),
                                  ar: widget.ar,
                                ),
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
      },
    );
  }

  Future<void> _leaveGuestCamera() async {
    if (!_guestPublishing || _controller.engine == null) return;
    try {
      await _controller.setCameraPublishing(false);
      await _controller.switchRole(AgoraRoomRole.listener);
      await _service.leaveGuest(widget.liveId);
      if (!mounted) return;
      setState(() {
        _guestPublishing = false;
        _guestMicMuted = false;
        _requested = false;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _becomeGuest() async {
    if (_guestPublishing || _controller.engine == null) return;
    _guestPublishing = true;
    try {
      final cameraAllowed = await _requestLiveCameraPermission();
      if (!cameraAllowed) {
        throw StateError(
          widget.ar
              ? 'اسمح باستخدام الكاميرا للانضمام إلى البث.'
              : 'Camera permission is required to join the Live camera.',
        );
      }
      await _controller.switchRole(AgoraRoomRole.speaker);
      if (_controller.role != AgoraRoomRole.speaker) {
        throw StateError(
          _controller.error ?? 'Could not receive broadcaster permission.',
        );
      }
      await _controller.setCameraPublishing(true);
      if (mounted) {
        setState(() => _guestMicMuted = false);
      }
    } catch (error) {
      _guestPublishing = false;
      await _service.leaveGuest(widget.liveId).catchError((Object _) {});
      if (!mounted) return;
      setState(() => _requested = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }
}

class _LiveLanguageToolsOverlay extends StatefulWidget {
  const _LiveLanguageToolsOverlay({
    required this.liveId,
    required this.roomLanguageCode,
    required this.canPublish,
    required this.displayName,
    required this.ar,
  });

  final String liveId;
  final String roomLanguageCode;
  final bool canPublish;
  final String displayName;
  final bool ar;

  @override
  State<_LiveLanguageToolsOverlay> createState() =>
      _LiveLanguageToolsOverlayState();
}

class _LiveLanguageToolsOverlayState extends State<_LiveLanguageToolsOverlay> {
  late final RoomCaptionService _captionService;
  late final RoomLiveCaptionController _captionController;
  late final RoomTranslationService _translationService;
  late final RoomTeacherAiService _teacherAi;
  StreamSubscription<List<RoomCaption>>? _captionSub;

  bool _enabled = false;
  bool _listening = false;
  bool _translationEnabled = false;
  bool _pronunciationEnabled = false;
  String _targetLanguage = 'en';
  bool _targetInitialized = false;
  String? _error;
  RoomCaption? _latest;
  String? _translated;
  String? _translatedCaptionId;

  @override
  void initState() {
    super.initState();
    _captionService = RoomCaptionService(
      roomId: widget.liveId,
      collectionName: 'live_sessions',
    );
    _translationService = RoomTranslationService();
    _teacherAi = RoomTeacherAiService(
      roomId: widget.liveId,
      collectionName: 'live_sessions',
    );
    _captionController = RoomLiveCaptionController(
      service: _captionService,
      onState: ({required bool listening, String? error}) {
        if (!mounted) return;
        setState(() {
          _listening = listening;
          if (error?.trim().isNotEmpty == true) _error = error;
        });
      },
    );
    if (widget.liveId.isNotEmpty) {
      _captionSub = _captionService.watchLatest().listen(
        _handleCaptions,
        onError: (Object error) {
          if (mounted) setState(() => _error = error.toString());
        },
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_targetInitialized) {
      _targetInitialized = true;
      _targetLanguage = widget.roomLanguageCode;
    }
  }

  @override
  void didUpdateWidget(covariant _LiveLanguageToolsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomLanguageCode != widget.roomLanguageCode) {
      _targetLanguage = widget.roomLanguageCode;
      _translated = null;
      _translatedCaptionId = null;
    }
    if (_enabled &&
        (oldWidget.canPublish != widget.canPublish ||
            oldWidget.displayName != widget.displayName ||
            oldWidget.roomLanguageCode != widget.roomLanguageCode)) {
      unawaited(_syncPublishing());
    }
  }

  void _handleCaptions(List<RoomCaption> captions) {
    if (!mounted) return;
    final latest = captions.isEmpty ? null : captions.first;
    setState(() {
      _latest = latest;
      if (latest == null) {
        _translated = null;
        _translatedCaptionId = null;
      }
    });
    if (latest != null &&
        _translationEnabled &&
        latest.id != _translatedCaptionId) {
      unawaited(_translate(latest));
    }
    if (latest != null &&
        _pronunciationEnabled &&
        latest.userId == FirebaseAuth.instance.currentUser?.uid) {
      unawaited(
        _teacherAi.submitCaption(
          caption: latest,
          roomLanguageCode: widget.roomLanguageCode,
        ),
      );
    }
  }

  Future<void> _translate(RoomCaption caption) async {
    _translatedCaptionId = caption.id;
    try {
      final value = await _translationService.translate(
        text: caption.text,
        sourceCode: caption.languageCode,
        targetCode: _targetLanguage,
      );
      if (!mounted || _latest?.id != caption.id) return;
      setState(() => _translated = value);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _syncPublishing() => _captionController.configure(
        enabled: _enabled,
        canPublish: widget.canPublish,
        languageCode: widget.roomLanguageCode,
        displayName: widget.displayName,
      );

  Future<void> _setEnabled(bool value) async {
    setState(() {
      _enabled = value;
      if (!value) {
        _translated = null;
        _error = null;
      }
    });
    await _syncPublishing();
  }

  Future<void> _showTeacherAi() async {
    if (!_teacherAi.isAskConfigured) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.ar
                ? 'Teacher AI يحتاج Backend مفعّل.'
                : 'Teacher AI needs the configured backend.',
          ),
        ),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => RoomTeacherAiSheet(
        service: _teacherAi,
        roomLanguageCode: widget.roomLanguageCode,
        closeAfterAnswer: true,
        onAnswer: (answer) {
          unawaited(
            _speakLiveTeacher(answer, widget.roomLanguageCode),
          );
        },
      ),
    );
  }

  Future<void> _showMoreTools() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.smart_toy_outlined),
              title: const Text('Teacher AI'),
              subtitle: Text(
                widget.ar
                    ? 'أسئلة ودروس وتصحيح داخل البث.'
                    : 'Questions, lessons and coaching inside Live.',
              ),
              onTap: () => Navigator.of(sheetContext).pop('teacher'),
            ),
            ListTile(
              leading: const Icon(Icons.language_rounded),
              title: Text(
                widget.ar ? 'الترجمة والسبتايتل' : 'Translation & subtitles',
              ),
              onTap: () => Navigator.of(sheetContext).pop('language'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'teacher') {
      await _showTeacherAi();
    } else if (action == 'language') {
      await _showSettings();
    }
  }

  Future<void> _showSettings() => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        useSafeArea: true,
        builder: (sheetContext) => StatefulBuilder(
          builder: (sheetContext, refresh) => RoomCaptionsSheet(
            enabled: _enabled,
            translationEnabled: _translationEnabled,
            pronunciationEnabled: _pronunciationEnabled,
            pronunciationNotes: _teacherAi.watchNotes(),
            targetLanguage: _targetLanguage,
            targetLanguages: [
              RoomCaptionLanguage(
                widget.roomLanguageCode,
                ProfileLanguageCatalog.label(widget.roomLanguageCode),
              ),
            ],
            canPublish: widget.canPublish,
            listening: _listening,
            error: _error,
            onEnabledChanged: (value) {
              unawaited(_setEnabled(value));
              refresh(() {});
            },
            onTranslationChanged: (value) {
              setState(() {
                _translationEnabled = value;
                _translated = null;
                _translatedCaptionId = null;
              });
              final latest = _latest;
              if (value && latest != null) unawaited(_translate(latest));
              refresh(() {});
            },
            onPronunciationChanged: (value) {
              setState(() {
                _pronunciationEnabled = value;
                _error = null;
              });
              refresh(() {});
            },
            onTargetLanguageChanged: (value) {
              setState(() {
                _targetLanguage = value;
                _translated = null;
                _translatedCaptionId = null;
              });
              final latest = _latest;
              if (_translationEnabled && latest != null) {
                unawaited(_translate(latest));
              }
              refresh(() {});
            },
          ),
        ),
      );

  @override
  void dispose() {
    unawaited(_captionSub?.cancel());
    unawaited(_captionController.dispose());
    unawaited(_translationService.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caption = _latest;
    return Stack(
      fit: StackFit.expand,
      children: [
        PositionedDirectional(
          top: 64,
          start: 12,
          child: Row(
            children: [
              IconButton.filledTonal(
                tooltip: widget.ar ? 'الترجمة والسبتايتل' : 'Language tools',
                onPressed: _showSettings,
                icon: const Icon(Icons.language_rounded),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                tooltip: widget.ar ? 'المزيد' : 'More',
                onPressed: _showMoreTools,
                icon: const Icon(Icons.more_horiz_rounded),
              ),
            ],
          ),
        ),
        if (_enabled && caption != null)
          PositionedDirectional(
            start: 28,
            end: 28,
            bottom: 88,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xB3000000),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text(
                    _translationEnabled && _translated?.trim().isNotEmpty == true
                        ? _translated!
                        : caption.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Future<void> _showLiveGifts(
  BuildContext context, {
  required String liveId,
  required LiveSessionService service,
  required String hostId,
  required String hostName,
  required bool ar,
}) {
  final myId = FirebaseAuth.instance.currentUser?.uid;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * .76,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: service.watchActiveGuests(liveId),
          builder: (context, snapshot) {
            final guests = snapshot.data?.docs ??
                const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
            final recipients = <String, String>{
              if (hostId.isNotEmpty && hostId != myId)
                hostId: hostName.trim().isEmpty ? 'WorldVoice host' : hostName,
              for (final doc in guests)
                if (doc.id != myId)
                  doc.id: (doc.data()['displayName'] ?? 'WorldVoice guest')
                      .toString(),
            };
            if (recipients.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    ar
                        ? 'لا يوجد شخص آخر على الكاميرا لإرسال هدية له الآن.'
                        : 'There is no other on-camera person to gift right now.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return UnifiedGiftPanel(
              contextType: 'live',
              contextId: liveId,
              recipients: recipients,
            );
          },
        ),
      ),
    ),
  );
}

class _LiveGiftEffects extends StatefulWidget {
  const _LiveGiftEffects({required this.liveId});
  final String liveId;

  @override
  State<_LiveGiftEffects> createState() => _LiveGiftEffectsState();
}

class _LiveGiftEffectsState extends State<_LiveGiftEffects> {
  StreamSubscription<List<RoomGiftEvent>>? _subscription;
  Timer? _timer;
  RoomGiftEvent? _event;
  String? _lastGiftId;
  bool _primed = false;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(covariant _LiveGiftEffects oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.liveId != widget.liveId) {
      unawaited(_subscription?.cancel());
      _timer?.cancel();
      _event = null;
      _lastGiftId = null;
      _primed = false;
      _listen();
    }
  }

  void _listen() {
    _subscription = RoomFeatureService.watchContextGifts(
      context: 'live',
      contextId: widget.liveId,
    ).listen(
      (gifts) {
        if (!mounted || gifts.isEmpty) return;
        final latest = gifts.first;
        if (!_primed) {
          _primed = true;
          _lastGiftId = latest.id;
          return;
        }
        if (latest.id == _lastGiftId) return;
        _lastGiftId = latest.id;
        _timer?.cancel();
        setState(() => _event = latest);
        final premium = const {'dragon', 'caraxes', 'vhagar'}
            .contains(latest.giftId.trim().toLowerCase());
        _timer = Timer(Duration(seconds: premium ? 5 : 3), () {
          if (mounted && _event?.id == latest.id) {
            setState(() => _event = null);
          }
        });
      },
      onError: (Object _) {
        // Gift effects are optional and must never interrupt the Live stream.
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    if (event == null) return const SizedBox.shrink();
    return RoomGiftOverlay(event: event);
  }
}

class _PinchZoomCameraView extends StatefulWidget {
  const _PinchZoomCameraView({
    required this.controller,
    required this.zoom,
    required this.onZoomChanged,
    required this.child,
  });

  final AgoraVoiceRoomController controller;
  final double zoom;
  final ValueChanged<double> onZoomChanged;
  final Widget child;

  @override
  State<_PinchZoomCameraView> createState() => _PinchZoomCameraViewState();
}

class _PinchZoomCameraViewState extends State<_PinchZoomCameraView> {
  double _startZoom = 1;
  double _maxZoom = 1;
  Timer? _zoomTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_loadMaxZoom());
  }

  Future<void> _loadMaxZoom() async {
    final value = await widget.controller.getCameraMaxZoom();
    if (mounted) setState(() => _maxZoom = value);
  }

  @override
  void dispose() {
    _zoomTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onScaleStart: (_) => _startZoom = widget.zoom,
      onScaleUpdate: (details) {
        if (details.pointerCount < 2 || _maxZoom <= 1) return;
        final next =
            (_startZoom * details.scale).clamp(1.0, _maxZoom).toDouble();
        widget.onZoomChanged(next);
        _zoomTimer?.cancel();
        _zoomTimer = Timer(const Duration(milliseconds: 45), () {
          unawaited(
            widget.controller.setCameraZoom(next).catchError((Object _) {}),
          );
        });
      },
      child: widget.child,
    );
  }
}

Future<void> _showLiveCameraTools(
  BuildContext context, {
  required AgoraVoiceRoomController controller,
  required bool ar,
  required bool beautyEnabled,
  required String filterPreset,
  required bool backgroundBlurEnabled,
  required double zoom,
  required ValueChanged<bool> onBeautyChanged,
  required ValueChanged<String> onFilterPresetChanged,
  required ValueChanged<bool> onBackgroundBlurChanged,
  required ValueChanged<double> onZoomChanged,
}) async {
  final engine = controller.engine;
  if (engine == null || !controller.cameraPublishing) return;

  final values = await Future.wait<Object>([
    controller.isBeautyAvailable(),
    controller.isVirtualBackgroundAvailable(),
    controller.getCameraMaxZoom(),
  ]);
  if (!context.mounted) return;

  final beautyAvailable = values[0] as bool;
  final blurAvailable = values[1] as bool;
  final maxZoom = values[2] as double;
  var localBeauty = beautyEnabled;
  var localPreset = filterPreset;
  var localBlur = backgroundBlurEnabled;
  var localZoom = zoom.clamp(1.0, maxZoom < 1 ? 1.0 : maxZoom).toDouble();

  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, refresh) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Text(
              ar ? 'الفلاتر والكاميرا' : 'Filters & camera',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.auto_awesome_rounded),
              title: Text(ar ? 'فلاتر الوجه' : 'Face filters'),
              subtitle: Text(
                beautyAvailable
                    ? (ar
                        ? 'اختر فلترًا لنفسك مثل تطبيقات اللايف.'
                        : 'Choose a subtle Live-style filter for yourself.')
                    : (ar
                        ? 'الفلاتر غير مدعومة على هذا الجهاز.'
                        : 'Filters are not supported on this device.'),
              ),
            ),
            if (beautyAvailable)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final preset in const <String>[
                      'off',
                      'natural',
                      'soft',
                      'bright',
                      'clean',
                    ]) ...[
                      ChoiceChip(
                        selected: localPreset == preset,
                        avatar: Icon(
                          preset == 'off'
                              ? Icons.block_rounded
                              : Icons.face_retouching_natural_rounded,
                          size: 17,
                        ),
                        label: Text(
                          switch (preset) {
                            'off' => ar ? 'بدون' : 'Off',
                            'natural' => ar ? 'طبيعي' : 'Natural',
                            'soft' => ar ? 'ناعم' : 'Soft',
                            'bright' => ar ? 'مشرق' : 'Bright',
                            _ => ar ? 'نظيف' : 'Clean',
                          },
                        ),
                        onSelected: (_) async {
                          try {
                            await controller.setBeautyPreset(preset);
                            localPreset = preset;
                            localBeauty = preset != 'off';
                            onFilterPresetChanged(preset);
                            onBeautyChanged(localBeauty);
                            refresh(() {});
                          } catch (error) {
                            if (!sheetContext.mounted) return;
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.blur_on_rounded),
              title: Text(ar ? 'تمويه الخلفية' : 'Background blur'),
              subtitle: Text(
                blurAvailable
                    ? (ar
                        ? 'يستخدمه الجهاز فقط إذا كان الأداء يدعمه.'
                        : 'Enabled only when the device supports it.')
                    : (ar
                        ? 'غير مدعوم على هذا الجهاز.'
                        : 'Not supported on this device.'),
              ),
              value: localBlur && blurAvailable,
              onChanged: !blurAvailable
                  ? null
                  : (value) async {
                      try {
                        await controller.setBackgroundBlurEnabled(value);
                        localBlur = value;
                        onBackgroundBlurChanged(value);
                        refresh(() {});
                      } catch (error) {
                        if (!sheetContext.mounted) return;
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                      }
                    },
            ),
            if (maxZoom > 1) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.zoom_in_rounded),
                title: Text(ar ? 'التقريب' : 'Zoom'),
                subtitle: Slider(
                  min: 1,
                  max: maxZoom,
                  divisions: ((maxZoom - 1) * 10).round().clamp(1, 70).toInt(),
                  value: localZoom.clamp(1.0, maxZoom).toDouble(),
                  label: '${localZoom.toStringAsFixed(1)}×',
                  onChanged: (value) {
                    localZoom = value;
                    refresh(() {});
                  },
                  onChangeEnd: (value) async {
                    try {
                      await controller.setCameraZoom(value);
                      onZoomChanged(value);
                    } catch (error) {
                      if (!sheetContext.mounted) return;
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                    }
                  },
                ),
              ),
            ] else
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.zoom_in_rounded),
                title: Text(ar ? 'التقريب غير مدعوم' : 'Zoom unavailable'),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await engine.switchCamera();
                        await controller.setCameraZoom(1);
                        localZoom = 1;
                        onZoomChanged(1);
                        refresh(() {});
                      } catch (error) {
                        if (!sheetContext.mounted) return;
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                      }
                    },
                    icon: const Icon(Icons.cameraswitch_rounded),
                    label: Text(ar ? 'أمامية / خلفية' : 'Front / back'),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: maxZoom <= 1
                      ? null
                      : () async {
                          try {
                            await controller.setCameraZoom(1);
                            localZoom = 1;
                            onZoomChanged(1);
                            refresh(() {});
                          } catch (error) {
                            if (!sheetContext.mounted) return;
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                          }
                        },
                  child: const Text('1×'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ar
                  ? 'يمكنك أيضًا استخدام إصبعين على فيديوك للتقريب.'
                  : 'You can also pinch your own video to zoom.',
              style: Theme.of(sheetContext).textTheme.bodySmall,
            ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _showLiveChat(
  BuildContext context, {
  required LiveSessionService service,
  required String liveId,
  required bool ar,
}) {
  final input = TextEditingController();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: Container(
        height: MediaQuery.sizeOf(sheetContext).height * .58,
        decoration: const BoxDecoration(
          color: Color(0xE6141414),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            ListTile(
              title: Text(
                ar ? 'دردشة اللايف' : 'Live chat',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              trailing: IconButton(
                onPressed: () => Navigator.pop(sheetContext),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: service.watchChat(liveId),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ??
                      const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${data['senderName'] ?? 'WorldVoice'}  ',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(
                                text: data['text']?.toString() ?? '',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: input,
                        maxLength: 500,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: ar ? 'اكتب رسالة...' : 'Message...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final value = input.text;
                        input.clear();
                        await service.sendChat(liveId, value);
                      },
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ).whenComplete(input.dispose);
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
                        onPressed: () async {
                          try {
                            await service.decideRequest(
                              liveId: liveId,
                              userId: doc.id,
                              accept: false,
                            );
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                          }
                        },
                        icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
                      ),
                      IconButton(
                        tooltip: ar ? 'قبول' : 'Accept',
                        onPressed: () async {
                          try {
                            await service.decideRequest(
                              liveId: liveId,
                              userId: doc.id,
                              accept: true,
                            );
                          } catch (error) {
                            if (!context.mounted) return;
                            final full = error.toString().contains(
                              'LIVE_GUEST_LIMIT_REACHED',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  full
                                      ? (ar
                                          ? 'وصل اللايف للحد الأقصى: المضيف + 3 ضيوف.'
                                          : 'Live is full: host + 3 guests.')
                                      : error.toString(),
                                ),
                              ),
                            );
                          }
                        },
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
