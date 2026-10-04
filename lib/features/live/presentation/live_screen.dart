import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

import '../../rooms/services/agora_voice_room_controller.dart';
import '../../rooms/presentation/room_board_screen.dart';
import '../../rooms/presentation/room_captions_sheet.dart';
import '../../rooms/presentation/room_teacher_ai_sheet.dart';
import '../../rooms/presentation/unified_gift_panel.dart';
import '../../rooms/presentation/room_gift_overlay.dart';
import '../../rooms/data/room_caption.dart';
import '../../rooms/data/room_backend_config.dart';
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
import '../../profile/presentation/public_profile_screen.dart';
import '../../chat/presentation/chat_screen.dart';

const MethodChannel _livePermissionChannel =
    MethodChannel('worldvoice/live_permissions');
const MethodChannel _liveTtsChannel = MethodChannel('worldvoice/live_tts');

Future<void> _warmLiveBackend() async {
  final endpoint = RoomBackendConfig.endpoint('/health');
  final uri = Uri.tryParse(endpoint);
  if (uri == null) return;
  try {
    await http.get(uri).timeout(const Duration(seconds: 20));
  } catch (_) {
    // Warming is opportunistic; camera preview and Agora worker still proceed.
  }
}

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
class LiveScreen extends StatefulWidget {
  const LiveScreen({required this.localeController, super.key});

  final LocaleController localeController;

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _sessions =
      LiveSessionService().watchOpen();

  @override
  Widget build(BuildContext context) {
    final language = widget.localeController.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    final ar = language == 'ar';
    final rtl = const {'ar', 'ur', 'fa'}.contains(language);

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFFDCF4EA),
                    child: Icon(
                      Icons.videocam_rounded,
                      color: Color(0xFF0B7A58),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ar ? 'أنشئ بثك المباشر' : 'Create your live',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ar
                              ? 'افتح الكاميرا وابدأ مباشرة.'
                              : 'Open the camera and go live.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    key: const ValueKey('start-live'),
                    onPressed: () {
                      unawaited(_warmLiveBackend());
                      final fallback =
                          ProfileLanguageCatalog.byCode(language) == null
                              ? 'en'
                              : language;
                      Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (_) => _LiveCameraGate(
                            ar: ar,
                            initialLanguageCode: fallback,
                          ),
                        ),
                      );
                    },
                    child: Text(ar ? 'إنشاء' : 'Create'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              ar ? 'البثوث المباشرة الآن' : 'Live now',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _sessions,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(ar ? 'تعذر تحميل البثوث. تحقق من الاتصال.' : 'Could not load live sessions. Check your connection.');
                }
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
                      color: Theme.of(context).colorScheme.surface,
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
          ],
        ),
      ),
    );
  }
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


class _LiveCameraGate extends StatefulWidget {
  const _LiveCameraGate({
    required this.ar,
    required this.initialLanguageCode,
  });
  final bool ar;
  final String initialLanguageCode;

  @override
  State<_LiveCameraGate> createState() => _LiveCameraGateState();
}

class _LiveCameraGateState extends State<_LiveCameraGate> {
  final AgoraVoiceRoomController _controller = AgoraVoiceRoomController();
  final TextEditingController _topicController = TextEditingController();
  late String _languageCode;
  late List<String> _learningCodes;
  bool _previewReady = false;
  bool _preparingPreview = false;
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
  bool _chatOpen = true;
  bool _sessionClosed = false;
  Timer? _heartbeatTimer;
  Timer? _cameraOffTimer;
  int _cameraOffSeconds = 0;
  String? _channelId;
  String? _liveId;
  final LiveSessionService _liveService = LiveSessionService();

  void _onControllerChanged() {
    if (mounted && _starting && !_cameraReady) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    _controller.removeListener(_onControllerChanged);
    _heartbeatTimer?.cancel();
    _cameraOffTimer?.cancel();
    final liveId = _liveId;
    if (liveId != null && !_sessionClosed) {
      unawaited(_liveService.end(liveId).catchError((Object _) {}));
    }
    unawaited(_controller.leave());
    _controller.dispose();
    super.dispose();
  }

  void _openViewerProfile({
    required String userId,
    required String displayName,
  }) {
    final liveId = _liveId;
    if (liveId == null || userId.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublicProfileScreen(
          userId: userId,
          languageCode:
              Localizations.localeOf(context).languageCode.toLowerCase(),
          onInviteToStage: () => _liveService.inviteViewer(
            liveId: liveId,
            userId: userId,
          ),
          inviteToStageLabel:
              widget.ar ? 'دعوة للكاميرا' : 'Invite to Live stage',
        ),
      ),
    );
  }

  Future<void> _shareHostLive() async {
    final liveId = _liveId;
    if (liveId == null) return;
    final host =
        FirebaseAuth.instance.currentUser?.displayName ?? 'WorldVoice host';
    await _showLiveShareSheet(
      context,
      liveId: liveId,
      topic: _resolvedTopic,
      hostName: host,
      ar: widget.ar,
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

  String get _resolvedTopic {
    final typed = _topicController.text.trim();
    if (typed.isNotEmpty) return typed;
    final language = ProfileLanguageCatalog.label(_languageCode);
    return widget.ar ? 'نتعلم $language معًا' : 'Practice $language together';
  }

  Future<void> _loadLearningLanguages() async {
    final codes = await _myLearningLanguageCodes(widget.initialLanguageCode);
    if (!mounted || codes.isEmpty) return;
    setState(() {
      _learningCodes = codes;
      if (!_learningCodes.contains(_languageCode)) {
        _languageCode = _learningCodes.first;
      }
    });
  }

  Future<void> _preparePreview() async {
    if (_previewReady || _preparingPreview) return;
    setState(() {
      _preparingPreview = true;
      _cameraStartError = null;
    });
    try {
      final cameraAllowed = await _requestLiveCameraPermission();
      if (!cameraAllowed) {
        throw StateError(
          widget.ar
              ? 'اسمح باستخدام الكاميرا لفتح معاينة اللايف.'
              : 'Camera permission is required for the Live preview.',
        );
      }
      await _controller.prepareCameraPreview();
      if (!mounted) return;
      setState(() {
        _previewReady = true;
        _preparingPreview = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _preparingPreview = false;
        _cameraStartError = error.toString();
      });
    }
  }

  Future<void> _startCamera() async {
    if (_starting || _cameraReady) return;
    if (!_previewReady) {
      await _preparePreview();
      if (!_previewReady) return;
    }
    setState(() {
      _starting = true;
      _cameraStartError = null;
    });
    try {
      final channel = 'live_${DateTime.now().millisecondsSinceEpoch}';
      _channelId = channel;
      await _controller.ensureConnected(
        channelId: channel,
        role: AgoraRoomRole.speaker,
        previewCamera: true,
      );
      if (!mounted) { await _controller.leave(); return; }
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
        languageCode: _languageCode,
        hostAgoraUid: hostAgoraUid,
        topic: _resolvedTopic,
      );
      if (!mounted) {
        await _liveService.end(_liveId!);
        await _controller.leave();
        return;
      }
      _startHeartbeat();
      setState(() {
        _cameraReady = true;
        _starting = false;
        _cameraPaused = false;
        _cameraStartError = null;
      });
    } catch (error) {
      await _controller.leave();
      if (!mounted) return;
      setState(() {
        _starting = false;
        _previewReady = false;
        _cameraStartError = error.toString();
      });
    }
  }

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
    _languageCode = widget.initialLanguageCode;
    _learningCodes = <String>[_languageCode];
    _controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_preparePreview());
      unawaited(_loadLearningLanguages());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!_cameraReady && _controller.engine != null)
              Positioned.fill(
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _controller.engine!,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                ),
              ),
            if (!_cameraReady && _controller.engine == null)
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF1A211E), Color(0xFF090B0A)],
                    ),
                  ),
                ),
              ),
            if (!_cameraReady)
              PositionedDirectional(
                start: 14,
                end: 14,
                bottom: 14 + MediaQuery.viewInsetsOf(context).bottom,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xCC101713),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * .58,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            widget.ar ? 'إنشاء بثك المباشر' : 'Create your live',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            widget.ar
                                ? 'جهّز العنوان ولغة التعلم. اللايف يدعمك مع 3 ضيوف — 4 أشخاص كحد أقصى.'
                                : 'Set the topic and learning language. Live supports you plus 3 guests — 4 people maximum.',
                            style: const TextStyle(
                              color: Colors.white70,
                              height: 1.35,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_preparingPreview)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                const SizedBox.square(
                                  dimension: 15,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF3CD6A0),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.ar
                                      ? 'جاري تجهيز الكاميرا...'
                                      : 'Preparing camera...',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        TextField(
                          controller: _topicController,
                          enabled: !_starting,
                          maxLength: 80,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            counterText: '',
                            labelText:
                                widget.ar ? 'موضوع اللايف' : 'Live topic',
                            labelStyle:
                                const TextStyle(color: Colors.white70),
                            hintText: widget.ar
                                ? 'اختياري — سننشئ عنوانًا تلقائيًا'
                                : 'Optional — we can create one automatically',
                            hintStyle:
                                const TextStyle(color: Colors.white54),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                                  const BorderSide(color: Colors.white30),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  const BorderSide(color: Color(0xFF3CD6A0)),
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_learningCodes.length > 1)
                          DropdownButtonFormField<String>(
                            initialValue: _languageCode,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF17211C),
                            decoration: InputDecoration(
                              labelText: widget.ar
                                  ? 'لغة التعلم'
                                  : 'Learning language',
                              labelStyle:
                                  const TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Colors.white30),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Color(0xFF3CD6A0)),
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                            items: [
                              for (final code in _learningCodes)
                                DropdownMenuItem(
                                  value: code,
                                  child: Text(
                                    ProfileLanguageCatalog.label(code),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: _starting
                                ? null
                                : (value) {
                                    if (value != null) {
                                      setState(() => _languageCode = value);
                                    }
                                  },
                          )
                        else
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.school_rounded,
                              color: Colors.white70,
                            ),
                            title: Text(
                              widget.ar ? 'لغة التعلم' : 'Learning language',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            subtitle: Text(
                              ProfileLanguageCatalog.label(_languageCode),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton.filledTonal(
                              tooltip: widget.ar
                                  ? 'الفلاتر'
                                  : 'Filters',
                              onPressed: (_starting || !_previewReady)
                                  ? null
                                  : () => _showLiveCameraTools(
                                        context,
                                        controller: _controller,
                                        ar: widget.ar,
                                        beautyEnabled: _beautyEnabled,
                                        filterPreset: _filterPreset,
                                        backgroundBlurEnabled:
                                            _backgroundBlurEnabled,
                                        zoom: _cameraZoom,
                                        onBeautyChanged: (value) {
                                          if (mounted) {
                                            setState(
                                              () => _beautyEnabled = value,
                                            );
                                          }
                                        },
                                        onFilterPresetChanged: (value) {
                                          if (mounted) {
                                            setState(
                                              () => _filterPreset = value,
                                            );
                                          }
                                        },
                                        onBackgroundBlurChanged: (value) {
                                          if (mounted) {
                                            setState(
                                              () => _backgroundBlurEnabled =
                                                  value,
                                            );
                                          }
                                        },
                                        onZoomChanged: (value) {
                                          if (mounted) {
                                            setState(
                                              () => _cameraZoom = value,
                                            );
                                          }
                                        },
                                      ),
                              icon:
                                  const Icon(Icons.auto_fix_high_rounded),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              tooltip: widget.ar
                                  ? 'تبديل الكاميرا'
                                  : 'Switch camera',
                              onPressed: (_starting || !_previewReady)
                                  ? null
                                  : () => _controller.switchCamera(),
                              icon:
                                  const Icon(Icons.cameraswitch_rounded),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _starting ? null : _startCamera,
                                icon: _starting
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.live_tv_rounded),
                                label: Text(
                                  _starting
                                      ? (widget.ar
                                          ? 'جاري بدء اللايف...'
                                          : 'Starting Live...')
                                      : (widget.ar
                                          ? 'ابدأ اللايف'
                                          : 'Go LIVE'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_cameraStartError?.trim().isNotEmpty == true &&
                            !_starting) ...[
                          const SizedBox(height: 8),
                          Text(
                            _cameraStartError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        ],
                      ),
                    ),
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
                          Positioned(
                            left: 12, right: 12, top: 110,
                            height: MediaQuery.sizeOf(context).height * .5,
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
                        Positioned.fill(
                          child: _LiveLanguageToolsOverlay(
                            liveId: _liveId ?? '',
                            roomLanguageCode: _languageCode,
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
                        if (_chatOpen && _liveId != null)
                          PositionedDirectional(
                            start: 10,
                            end: 68,
                            bottom: 78 + MediaQuery.viewInsetsOf(context).bottom,
                            height: 250,
                            child: _LiveChatOverlay(
                              service: _liveService,
                              liveId: _liveId!,
                              ar: widget.ar,
                              onClose: () {
                                if (mounted) {
                                  setState(() => _chatOpen = false);
                                }
                              },
                            ),
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
                                      if (_liveId != null) ...[
                                        _LiveViewerFaces(
                                          service: _liveService,
                                          liveId: _liveId!,
                                          onViewerTap: (userId, name, photo) =>
                                              _openViewerProfile(
                                            userId: userId,
                                            displayName: name,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
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
                          start: 12,
                          end: 12,
                          child: _LiveControlDock(
                            children: [
                              IconButton(
                                tooltip: widget.ar
                                    ? 'طلبات الانضمام'
                                    : 'Join requests',
                                onPressed: () => setState(
                                  () => _requestsOpen = !_requestsOpen,
                                ),
                                icon: const Icon(
                                  Icons.group_add_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              IconButton(
                                tooltip: widget.ar
                                    ? 'المودريتر'
                                    : 'Moderators',
                                onPressed: _liveId == null
                                    ? null
                                    : () => _showLiveModeratorManagement(
                                          context,
                                          liveId: _liveId!,
                                          service: _liveService,
                                          ar: widget.ar,
                                        ),
                                icon: const Icon(
                                  Icons.admin_panel_settings_rounded,
                                  color: Color(0xFFFFD77A),
                                ),
                              ),
                              IconButton(
                                tooltip: widget.ar
                                    ? 'دردشة اللايف'
                                    : 'Live chat',
                                onPressed: _liveId == null
                                    ? null
                                    : () => setState(
                                          () => _chatOpen = !_chatOpen,
                                        ),
                                icon: Icon(
                                  _chatOpen
                                      ? Icons.chat_bubble_rounded
                                      : Icons.chat_bubble_outline_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              IconButton(
                                tooltip: widget.ar ? 'السبورة' : 'Board',
                                onPressed: _liveId == null
                                    ? null
                                    : () => setState(
                                          () => _boardOpen = !_boardOpen,
                                        ),
                                icon: Icon(
                                  _boardOpen
                                      ? Icons.dashboard_rounded
                                      : Icons.dashboard_outlined,
                                  color: Colors.white,
                                ),
                              ),
                              IconButton(
                                tooltip: widget.ar ? 'الهدايا' : 'Gifts',
                                onPressed: _liveId == null
                                    ? null
                                    : () => _showLiveGifts(
                                          context,
                                          liveId: _liveId!,
                                          service: _liveService,
                                          hostId: FirebaseAuth
                                                  .instance.currentUser?.uid ??
                                              '',
                                          hostName: FirebaseAuth.instance
                                                  .currentUser?.displayName ??
                                              'WorldVoice host',
                                          ar: widget.ar,
                                        ),
                                icon: const Icon(
                                  Icons.card_giftcard_rounded,
                                  color: Color(0xFFFFC857),
                                ),
                              ),
                              IconButton(
                                tooltip: widget.ar
                                    ? 'مشاركة اللايف'
                                    : 'Share Live',
                                onPressed:
                                    _liveId == null ? null : _shareHostLive,
                                icon: const Icon(
                                  Icons.share_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_requestsOpen && _liveId != null)
                          PositionedDirectional(
                            bottom: 86,
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
                              IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xB3000000),
                                  foregroundColor: Colors.white,
                                ),
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
                              IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xB3000000),
                                  foregroundColor: Colors.white,
                                ),
                                tooltip: widget.ar ? 'المايك' : 'Microphone',
                                onPressed: () async {
                                  final next = !_micMuted;
                                  await _controller.setMuted(next);
                                  if (mounted) setState(() => _micMuted = next);
                                },
                                icon: Icon(_micMuted ? Icons.mic_off_rounded : Icons.mic_rounded),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xB3000000),
                                  foregroundColor: Colors.white,
                                ),
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
                              IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xCC8B1E1E),
                                  foregroundColor: Colors.white,
                                ),
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

class _LiveControlDock extends StatelessWidget {
  const _LiveControlDock({
    required this.children,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 8);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xB8141816),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 8),
            color: Color(0x33000000),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
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
  String? _joinError;
  bool _requested = false;
  bool _guestPublishing = false;
  bool _hostSeen = false;
  bool _guestMicMuted = false;
  bool _guestBeautyEnabled = false;
  String _guestFilterPreset = 'off';
  bool _guestBackgroundBlurEnabled = false;
  double _guestCameraZoom = 1;
  bool _boardOpen = false;
  bool _chatOpen = true;
  bool _following = false;
  bool _followBusy = false;
  bool _isModerator = false;
  bool _moderatorRequestsOpen = false;
  bool _invitePromptOpen = false;
  String? _lastInviteMarker;
  StreamSubscription<bool>? _moderatorSub;

  @override
  void initState() {
    super.initState();
    _join();
    _loadFollow();
    final hostId = widget.data['hostId']?.toString() ?? '';
    if (hostId.isNotEmpty) {
      _moderatorSub = _service.watchMyModeratorStatus(hostId).listen((value) {
        if (mounted && value != _isModerator) {
          setState(() {
            _isModerator = value;
            if (!value) _moderatorRequestsOpen = false;
          });
        }
      });
    }
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

  void _openViewerProfile({
    required String userId,
    required String displayName,
  }) {
    if (userId.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublicProfileScreen(
          userId: userId,
          languageCode:
              Localizations.localeOf(context).languageCode.toLowerCase(),
          onInviteToStage: !_isModerator
              ? null
              : () => _service.inviteViewer(
                    liveId: widget.liveId,
                    userId: userId,
                  ),
          inviteToStageLabel:
              widget.ar ? 'دعوة للكاميرا' : 'Invite to Live stage',
        ),
      ),
    );
  }

  Future<void> _showLiveInvitePrompt(
    Map<String, dynamic> requestData,
  ) async {
    if (_invitePromptOpen || !mounted) return;
    final invitedAt = requestData['invitedAt'];
    final marker = invitedAt is Timestamp
        ? '${invitedAt.millisecondsSinceEpoch}:${requestData['invitedBy']}'
        : requestData['invitedBy']?.toString() ?? 'invite';
    if (_lastInviteMarker == marker) return;
    _lastInviteMarker = marker;
    _invitePromptOpen = true;
    try {
      final accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            widget.ar ? 'دعوة للصعود في اللايف' : 'Live stage invitation',
          ),
          content: Text(
            widget.ar
                ? 'المضيف أو المودريتر دعاك للكاميرا. هل تريد الصعود؟'
                : 'The host or moderator invited you on camera. Join the Live stage?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(widget.ar ? 'رفض' : 'Decline'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.videocam_rounded),
              label: Text(widget.ar ? 'قبول والصعود' : 'Accept & join'),
            ),
          ],
        ),
      );
      if (accepted == null) return;
      await _service.respondToInvite(
        liveId: widget.liveId,
        accept: accepted,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      _invitePromptOpen = false;
    }
  }

  Future<void> _shareLive() async {
    final topic = (widget.data['topic'] ?? '').toString().trim();
    final host = (widget.data['hostName'] ?? 'WorldVoice host').toString();
    await _showLiveShareSheet(
      context,
      liveId: widget.liveId,
      topic: topic,
      hostName: host,
      ar: widget.ar,
    );
  }

  Future<void> _join() async {
    if (mounted) setState(() { _joining = true; _joinError = null; });
    var countedViewer = false;
    try {
      await _service.enterViewer(widget.liveId);
      countedViewer = true;
      if (!mounted) {
        await _service.leaveViewer(widget.liveId);
        return;
      }
      await _controller.ensureConnected(
        channelId: widget.liveId,
        role: AgoraRoomRole.listener,
      );
    } catch (error) {
      await _controller.leave();
      if (mounted) _joinError = error.toString();
      if (countedViewer) {
        await _service.leaveViewer(widget.liveId).catchError((Object _) {});
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  void dispose() {
    unawaited(_moderatorSub?.cancel());
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
        final requestData =
            requestSnapshot.data?.data() ?? const <String, dynamic>{};
        final status = requestData['status']?.toString();
        if (status == 'invited') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) unawaited(_showLiveInvitePrompt(requestData));
          });
        }
        if (status == 'accepted' && !_guestPublishing) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _becomeGuest());
        }
        if ((status == 'declined' || status == 'left') && _requested) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _requested = false);
          });
        }
        return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _joining
            ? const Center(child: CircularProgressIndicator())
            : _joinError != null
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(widget.ar ? 'تعذر الاتصال بالبث' : 'Could not connect to Live', style: const TextStyle(color: Colors.white)),
                    FilledButton(onPressed: _join, child: Text(widget.ar ? 'إعادة المحاولة' : 'Retry')),
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(widget.ar ? 'رجوع' : 'Back')),
                  ]))
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
                        Positioned(
                          left: 12, right: 12, top: 110,
                          height: MediaQuery.sizeOf(context).height * .5,
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
                      if (_chatOpen)
                        PositionedDirectional(
                          start: 10,
                          end: 68,
                          bottom: 78 + MediaQuery.viewInsetsOf(context).bottom,
                          height: 250,
                          child: _LiveChatOverlay(
                            service: _service,
                            liveId: widget.liveId,
                            ar: widget.ar,
                            onClose: () {
                              if (mounted) {
                                setState(() => _chatOpen = false);
                              }
                            },
                          ),
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
                                _LiveViewerFaces(
                                  service: _service,
                                  liveId: widget.liveId,
                                  onViewerTap: (userId, name, photo) =>
                                      _openViewerProfile(
                                    userId: userId,
                                    displayName: name,
                                  ),
                                ),
                                const SizedBox(width: 4),
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
                      if (_isModerator &&
                          _moderatorRequestsOpen)
                        PositionedDirectional(
                          bottom: 84,
                          start: 14,
                          end: 14,
                          child: _HostJoinRequests(
                            liveId: widget.liveId,
                            service: _service,
                            ar: widget.ar,
                          ),
                        ),
                      PositionedDirectional(
                        bottom: 16,
                        start: 12,
                        end: 12,
                        child: _LiveControlDock(
                          children: [
                            if (!_guestPublishing)
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: _requested
                                      ? const Color(0x663A8068)
                                      : const Color(0xFF1EA972),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(128, 44),
                                ),
                                onPressed: _requested ? null : _requestCamera,
                                icon: Icon(
                                  _requested
                                      ? Icons.hourglass_top_rounded
                                      : Icons.group_add_rounded,
                                ),
                                label: Text(
                                  _requested
                                      ? (widget.ar ? 'تم الطلب' : 'Requested')
                                      : (widget.ar ? 'انضمام' : 'Join'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            if (_isModerator)
                              IconButton(
                                tooltip: widget.ar
                                    ? 'طلبات الانضمام'
                                    : 'Join requests',
                                onPressed: () => setState(
                                  () => _moderatorRequestsOpen =
                                      !_moderatorRequestsOpen,
                                ),
                                icon: const Icon(
                                  Icons.admin_panel_settings_rounded,
                                  color: Color(0xFFFFD77A),
                                ),
                              ),
                            IconButton(
                              tooltip: widget.ar ? 'الشات' : 'Chat',
                              onPressed: () => setState(
                                () => _chatOpen = !_chatOpen,
                              ),
                              icon: Icon(
                                _chatOpen
                                    ? Icons.chat_bubble_rounded
                                    : Icons.chat_bubble_outline_rounded,
                                color: Colors.white,
                              ),
                            ),
                            IconButton(
                              tooltip: widget.ar ? 'السبورة' : 'Board',
                              onPressed: () =>
                                  setState(() => _boardOpen = !_boardOpen),
                              icon: Icon(
                                _boardOpen
                                    ? Icons.dashboard_rounded
                                    : Icons.dashboard_outlined,
                                color: Colors.white,
                              ),
                            ),
                            if (_guestPublishing) ...[
                              IconButton(
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
                                  color: Colors.white,
                                ),
                              ),
                              IconButton(
                                tooltip: widget.ar
                                    ? 'الفلاتر والكاميرا'
                                    : 'Filters & camera',
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
                                icon: const Icon(
                                  Icons.auto_fix_high_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              IconButton(
                                tooltip: widget.ar
                                    ? 'اخرج من الكاميرا'
                                    : 'Leave camera',
                                onPressed: _leaveGuestCamera,
                                icon: const Icon(
                                  Icons.videocam_off_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ] else
                              IconButton(
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
                                icon: const Icon(
                                  Icons.card_giftcard_rounded,
                                  color: Color(0xFFFFC857),
                                ),
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
  if (engine == null ||
      (!controller.cameraPublishing && !controller.localPreviewPrepared)) {
    return;
  }

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
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, refresh) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .45,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
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
    ),
  );
}

String _liveShareUri(String liveId) => 'worldvoice://live/$liveId';

String _liveShareText({
  required String liveId,
  required String topic,
  required String hostName,
}) {
  final cleanTopic = topic.trim();
  final title = cleanTopic.isEmpty ? 'WorldVoice Live' : cleanTopic;
  return '🔴 WorldVoice Live\n$title\n$hostName\n${_liveShareUri(liveId)}';
}

Future<void> _showLiveShareSheet(
  BuildContext context, {
  required String liveId,
  required String topic,
  required String hostName,
  required bool ar,
}) {
  final shareText = _liveShareText(
    liveId: liveId,
    topic: topic,
    hostName: hostName,
  );
  final link = _liveShareUri(liveId);

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.chat_bubble_rounded),
            ),
            title: Text(
              ar ? 'إرسال داخل شات WorldVoice' : 'Send in WorldVoice chat',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              ar
                  ? 'اختر شخصًا من محادثاتك وأرسل له اللايف.'
                  : 'Choose a conversation and send the Live.',
            ),
            onTap: () async {
              Navigator.of(sheetContext).pop();
              await Future<void>.delayed(Duration.zero);
              if (!context.mounted) return;
              await _showLiveShareToChat(
                context,
                shareText: shareText,
                ar: ar,
              );
            },
          ),
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.link_rounded),
            ),
            title: Text(
              ar ? 'نسخ رابط اللايف' : 'Copy Live link',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              link,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: link));
              if (!sheetContext.mounted) return;
              Navigator.of(sheetContext).pop();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ar ? 'تم نسخ رابط اللايف.' : 'Live link copied.',
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.ios_share_rounded),
            ),
            title: Text(
              ar ? 'مشاركة الرابط' : 'Share link',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              ar
                  ? 'شارك اللايف في أي تطبيق.'
                  : 'Share the Live in any app.',
            ),
            onTap: () async {
              Navigator.of(sheetContext).pop();
              await SharePlus.instance.share(
                ShareParams(
                  title: 'WorldVoice Live',
                  text: shareText,
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> _showLiveShareToChat(
  BuildContext context, {
  required String shareText,
  required bool ar,
}) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ar ? 'سجّل دخولك أولًا.' : 'Sign in first.'),
      ),
    );
    return Future<void>.value();
  }

  String? sendingChatId;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (innerContext, setSheetState) => SizedBox(
        height: MediaQuery.sizeOf(innerContext).height * .68,
        child: Column(
          children: [
            ListTile(
              title: Text(
                ar ? 'إرسال اللايف إلى...' : 'Send Live to...',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text(
                ar
                    ? 'اختر محادثة موجودة.'
                    : 'Choose an existing conversation.',
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .where('memberIds', arrayContains: uid)
                    .where('active', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        ar
                            ? 'تعذر تحميل المحادثات.'
                            : 'Could not load conversations.',
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final chats = snapshot.data!.docs.toList()
                    ..sort((a, b) {
                      final aTime = a.data()['lastMessageAt'];
                      final bTime = b.data()['lastMessageAt'];
                      final aMs =
                          aTime is Timestamp ? aTime.millisecondsSinceEpoch : 0;
                      final bMs =
                          bTime is Timestamp ? bTime.millisecondsSinceEpoch : 0;
                      return bMs.compareTo(aMs);
                    });
                  if (chats.isEmpty) {
                    return Center(
                      child: Text(
                        ar
                            ? 'لا توجد محادثات لإرسال اللايف إليها.'
                            : 'No conversations available for Live sharing.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final doc = chats[index];
                      final data = doc.data();
                      final memberIds =
                          List<String>.from(data['memberIds'] ?? const []);
                      final peerId = memberIds.firstWhere(
                        (value) => value != uid,
                        orElse: () => '',
                      );
                      final names = Map<String, dynamic>.from(
                        data['memberNames'] as Map? ?? <String, dynamic>{},
                      );
                      final peerName = (names[peerId] ?? 'WorldVoice').toString();
                      final sending = sendingChatId == doc.id;

                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person_rounded),
                        ),
                        title: Text(
                          peerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          (data['latestText'] ?? '').toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: sending
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        onTap: sendingChatId != null
                            ? null
                            : () async {
                                setSheetState(() => sendingChatId = doc.id);
                                try {
                                  await ChatScreen.sendTextMessageToConversation(
                                    chatId: doc.id,
                                    text: shareText,
                                  );
                                  if (!sheetContext.mounted) return;
                                  Navigator.of(sheetContext).pop();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ar
                                            ? 'تم إرسال اللايف في الشات.'
                                            : 'Live sent in chat.',
                                      ),
                                    ),
                                  );
                                } catch (error) {
                                  if (!sheetContext.mounted) return;
                                  setSheetState(() => sendingChatId = null);
                                  ScaffoldMessenger.of(sheetContext)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        error
                                            .toString()
                                            .replaceFirst('Bad state: ', ''),
                                      ),
                                    ),
                                  );
                                }
                              },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LiveChatOverlay extends StatefulWidget {
  const _LiveChatOverlay({
    required this.service,
    required this.liveId,
    required this.ar,
    required this.onClose,
  });

  final LiveSessionService service;
  final String liveId;
  final bool ar;
  final VoidCallback onClose;

  @override
  State<_LiveChatOverlay> createState() => _LiveChatOverlayState();
}

class _LiveChatOverlayState extends State<_LiveChatOverlay> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _sending = false;

  Future<void> _send() async {
    final value = _input.text.trim();
    if (value.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.service.sendChat(widget.liveId, value);
      if (!mounted) return;
      _input.clear();
      _focusNode.requestFocus();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color(0x8A000000),
            Color(0x38000000),
            Color(0x00000000),
          ],
          stops: [0, .55, 1],
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: AlignmentDirectional.topEnd,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0x42000000),
                foregroundColor: Colors.white,
              ),
              tooltip: widget.ar ? 'إخفاء الشات' : 'Hide chat',
              onPressed: widget.onClose,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: widget.service.watchChat(widget.liveId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const SizedBox.shrink();
                }
                final docs = snapshot.data?.docs ??
                    const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final name =
                        (data['senderName'] ?? 'WorldVoice').toString();
                    final photo =
                        (data['senderPhotoUrl'] ?? '').toString().trim();
                    final message = (data['text'] ?? '').toString();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: const Color(0x88444444),
                            foregroundImage:
                                photo.isEmpty ? null : NetworkImage(photo),
                            child: photo.isEmpty
                                ? const Icon(
                                    Icons.person_rounded,
                                    size: 15,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$name  ',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  TextSpan(
                                    text: message,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      height: 1.28,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                shadows: [
                                  Shadow(
                                    color: Colors.black87,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  focusNode: _focusNode,
                  maxLength: 500,
                  maxLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: widget.ar ? 'تعليق...' : 'Comment...',
                    hintStyle: const TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: const Color(0x66000000),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xCC11835D),
                  foregroundColor: Colors.white,
                ),
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox.square(
                        dimension: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _showLiveModeratorManagement(
  BuildContext context, {
  required String liveId,
  required LiveSessionService service,
  required bool ar,
}) {
  final hostId = FirebaseAuth.instance.currentUser?.uid ?? '';
  if (hostId.isEmpty) return Future<void>.value();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      height: MediaQuery.sizeOf(sheetContext).height * .72,
      decoration: const BoxDecoration(
        color: Color(0xF2141716),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 10, 8),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFF174D3D),
                  child: Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Color(0xFFFFD77A),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ar ? 'مودريتر WorldVoice' : 'WorldVoice moderators',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        ar
                            ? 'المودريتر الذي تعيّنه هنا يبقى مودريتر في اللايف والرومات الصوتية التابعة لك.'
                            : 'A moderator assigned here stays moderator across your Live and voice rooms.',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: service.watchGlobalModerators(hostId),
              builder: (context, moderatorSnapshot) {
                final moderatorDocs = moderatorSnapshot.data?.docs ??
                    const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                final moderatorIds =
                    moderatorDocs.map((doc) => doc.id).toSet();
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: service.watchViewers(liveId),
                  builder: (context, viewerSnapshot) {
                    final viewers = viewerSnapshot.data?.docs ??
                        const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                    if (viewers.isEmpty && moderatorDocs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Text(
                            ar
                                ? 'عندما يدخل المشاهدون تقدر تعيّن الموثوقين كمودريتر.'
                                : 'When viewers join, you can assign trusted people as moderators.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white60),
                          ),
                        ),
                      );
                    }

                    final byId = <String, Map<String, dynamic>>{
                      for (final doc in moderatorDocs)
                        doc.id: <String, dynamic>{...doc.data()},
                      for (final doc in viewers)
                        doc.id: <String, dynamic>{...doc.data()},
                    };
                    final entries = byId.entries.toList()
                      ..sort((a, b) {
                        final am = moderatorIds.contains(a.key);
                        final bm = moderatorIds.contains(b.key);
                        if (am != bm) return am ? -1 : 1;
                        return (a.value['displayName'] ?? '')
                            .toString()
                            .compareTo(
                              (b.value['displayName'] ?? '').toString(),
                            );
                      });

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: Colors.white10),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final data = entry.value;
                        final selected = moderatorIds.contains(entry.key);
                        final name =
                            (data['displayName'] ?? 'WorldVoice user')
                                .toString();
                        final photo =
                            (data['photoUrl'] ?? '').toString().trim();
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                photo.isEmpty ? null : NetworkImage(photo),
                            child: photo.isEmpty
                                ? const Icon(Icons.person_rounded)
                                : null,
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(
                            selected
                                ? (ar
                                    ? 'مودريتر في Live + Voice Rooms'
                                    : 'Moderator in Live + Voice Rooms')
                                : (ar
                                    ? 'مشاهد'
                                    : 'Viewer'),
                            style: TextStyle(
                              color: selected
                                  ? const Color(0xFFFFD77A)
                                  : Colors.white54,
                            ),
                          ),
                          trailing: Switch(
                            value: selected,
                            onChanged: (value) async {
                              try {
                                await service.setGlobalModerator(
                                  liveId: liveId,
                                  targetUserId: entry.key,
                                  displayName: name,
                                  photoUrl: photo,
                                  value: value,
                                );
                              } catch (error) {
                                if (!sheetContext.mounted) return;
                                ScaffoldMessenger.of(sheetContext)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(error.toString()),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
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

class _LiveViewerFaces extends StatelessWidget {
  const _LiveViewerFaces({
    required this.service,
    required this.liveId,
    this.onViewerTap,
  });

  final LiveSessionService service;
  final String liveId;
  final void Function(String userId, String displayName, String photoUrl)?
      onViewerTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.watchViewers(liveId),
      builder: (context, snapshot) {
        final viewers = snapshot.data?.docs.take(3).toList(growable: false) ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        if (viewers.isEmpty) return const SizedBox.shrink();

        final width = 24.0 + ((viewers.length - 1) * 15);
        return SizedBox(
          width: width,
          height: 26,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var index = 0; index < viewers.length; index++)
                Positioned(
                  left: index * 15,
                  child: Builder(
                    builder: (context) {
                      final data = viewers[index].data();
                      final photo =
                          (data['photoUrl'] ?? '').toString().trim();
                      final name =
                          (data['displayName'] ?? 'WorldVoice user').toString();
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onViewerTap == null
                            ? null
                            : () => onViewerTap!(
                                  viewers[index].id,
                                  name,
                                  photo,
                                ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 11,
                            backgroundColor: const Color(0xFF245A49),
                            foregroundImage:
                                photo.isEmpty ? null : NetworkImage(photo),
                            child: photo.isEmpty
                                ? const Icon(
                                    Icons.person_rounded,
                                    color: Colors.white,
                                    size: 13,
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}