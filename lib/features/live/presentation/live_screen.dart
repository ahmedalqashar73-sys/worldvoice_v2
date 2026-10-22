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
import '../../rooms/data/room_teacher_ai_note.dart';
import '../../rooms/data/room_backend_config.dart';
import '../../rooms/data/room_feature_models.dart';
import '../../rooms/services/room_feature_service.dart';
import '../../rooms/services/room_caption_service.dart';
import '../../rooms/services/room_live_caption_controller.dart';
import '../../rooms/services/room_teacher_ai_service.dart';
import '../../rooms/services/room_translation_service.dart';
import '../../rooms/services/room_quota_service.dart';
import '../../rooms/services/room_rewarded_ad_service.dart';
import '../services/live_session_service.dart';
import 'live_invitation_card.dart';

import '../../../core/localization/locale_controller.dart';
import '../../profile/services/profile_social_service.dart';
import '../../profile/data/profile_language_catalog.dart';
import '../../profile/presentation/public_profile_screen.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../stories/services/story_service.dart';
import '../../home/services/home_feed_service.dart';

const MethodChannel _livePermissionChannel =
    MethodChannel('worldvoice/live_permissions');
const MethodChannel _liveTtsChannel = MethodChannel('worldvoice/live_tts');
const MethodChannel _livePipChannel = MethodChannel('worldvoice/live_pip');

Future<void> _enterLiveMiniWindow(BuildContext context, bool ar) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ar
          ? 'النافذة العائمة متاحة على أندرويد المدعوم حاليًا.'
          : 'Picture-in-Picture currently requires a supported Android device.')),
    );
    return;
  }
  try {
    final opened = await _livePipChannel.invokeMethod<bool>('enter');
    if (opened == true || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ar
          ? 'هذا الجهاز لا يدعم النافذة العائمة.'
          : 'Picture-in-Picture is not supported on this device.')),
    );
  } on PlatformException catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message ?? error.code)),
    );
  } on MissingPluginException {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ar
          ? 'حدّث نسخة الأندرويد لتفعيل النافذة العائمة.'
          : 'Install the updated Android build to enable PiP.')),
    );
  }
}

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
/// Bump this when the Live UI materially changes so stale APKs are obvious.
const String worldVoiceLiveUiRevision = '2026.10.22.7';
const String worldVoiceBuildRevision =
    String.fromEnvironment('WORLDVOICE_BUILD_REVISION', defaultValue: 'local');

class LiveScreen extends StatefulWidget {
  const LiveScreen({required this.localeController, super.key});

  final LocaleController localeController;

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _sessions =
      LiveSessionService().watchOpen();
  final String? _myUid = FirebaseAuth.instance.currentUser?.uid;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _myProfile =
      FirebaseFirestore.instance.collection('users')
          .doc(_myUid ?? '__signed_out__').snapshots();
  String _languageFilter = 'all';
  OverlayEntry? _viewerOverlay;
  String? _playingLiveId;
  bool _mini = false;

  void _closeMiniLive() {
    final entry = _viewerOverlay;
    _viewerOverlay = null;
    _playingLiveId = null;
    _mini = false;
    entry?.remove();
    entry?.dispose();
    if (mounted) setState(() {});
  }

  void _toggleMiniLive() {
    if (_viewerOverlay == null) return;
    _mini = !_mini;
    _viewerOverlay?.markNeedsBuild();
    if (mounted) setState(() {});
  }

  void _watchLive(QueryDocumentSnapshot<Map<String, dynamic>> doc, bool ar) {
    if (_playingLiveId == doc.id) {
      if (_mini) _toggleMiniLive();
      return;
    }
    _closeMiniLive();
    _playingLiveId = doc.id;
    _viewerOverlay = OverlayEntry(
      builder: (overlayContext) => Positioned(
        top: _mini ? null : 0,
        bottom: _mini ? 96 : 0,
        left: _mini ? null : 0,
        right: _mini ? 14 : 0,
        width: _mini ? 182 : null,
        height: _mini ? 248 : null,
        child: Material(
          color: Colors.black,
          elevation: _mini ? 16 : 0,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(_mini ? 18 : 0),
          child: _LiveViewerScreen(
            key: ValueKey(doc.id),
            liveId: doc.id,
            data: doc.data(),
            ar: ar,
            miniMode: _mini,
            onMiniToggle: _toggleMiniLive,
            onClose: _closeMiniLive,
          ),
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_viewerOverlay!);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    final entry = _viewerOverlay;
    _viewerOverlay = null;
    entry?.remove();
    entry?.dispose();
    super.dispose();
  }

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
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 112),
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
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'WORLDVOICE LIVE · $worldVoiceLiveUiRevision'
                ' · ${worldVoiceBuildRevision.length > 8 ? worldVoiceBuildRevision.substring(0, 8) : worldVoiceBuildRevision}',
                style: const TextStyle(
                  color: Color(0xFF419875),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              ar ? 'البثوث المباشرة الآن' : 'Live now',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _myProfile,
              builder: (context, profileSnap) {
                final profile = profileSnap.data?.data() ??
                    const <String, dynamic>{};
                final native = ProfileLanguageCatalog.codeFromStored(
                  profile['nativeLanguageCode'] ?? profile['nativeLanguage']);
                final codes = ProfileLanguageCatalog.liveDiscoveryCodes(profile);
                if (!codes.contains(_languageFilter)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !codes.contains(_languageFilter)) {
                      setState(() => _languageFilter = 'all');
                    }
                  });
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ar ? 'اللغة الأم ولغات التعلّم' :
                          'Native and learning languages',
                        style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 7),
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: codes.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final code = codes[index];
                            final selected = _languageFilter == code;
                            final label = code == 'all'
                                ? (ar ? 'الكل' : 'All')
                                : code == native
                                    ? '${ar ? 'الأم' : 'Native'}: '
                                      '${ProfileLanguageCatalog.localizedName(code, language)}'
                                    : ProfileLanguageCatalog.localizedName(
                                        code, language);
                            return ChoiceChip(
                              key: ValueKey('live-language-$code'),
                              showCheckmark: false,
                              selected: selected,
                              selectedColor: const Color(0xFF116A4B),
                              onSelected: (_) =>
                                  setState(() => _languageFilter = code),
                              label: Text(label),
                              labelStyle: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: selected ? Colors.white : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
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
                    .where((doc) {
                      if (_languageFilter == 'all') return true;
                      final data = doc.data();
                      if ((data['languageCode'] ?? '').toString().toLowerCase() ==
                          _languageFilter ||
                          (data['nativeLanguageCode'] ?? '').toString()
                              .toLowerCase() == _languageFilter) {
                        return true;
                      }
                      final learning = data['learningLanguageCodes'];
                      return learning is List && learning.any(
                        (v) => v.toString().toLowerCase() == _languageFilter);
                    })
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
                return LayoutBuilder(
                  builder: (context, bounds) => GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: bounds.maxWidth > 640 ? 3 : 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: bounds.maxWidth > 640 ? .94 : .83,
                    ),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final photo = (data['hostPhotoUrl'] ?? '')
                          .toString().trim();
                      final name = (data['hostName'] ?? 'WorldVoice')
                          .toString();
                      final title = (data['topic'] ?? '').toString().trim();
                      final code = (data['languageCode'] ?? 'en')
                          .toString().toUpperCase();
                      final viewers = data['viewerCount'] ?? 0;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: ValueKey(doc.id),
                          onTap: () => _watchLive(doc, ar),
                          borderRadius: BorderRadius.circular(22),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFF0B2922),
                                Color(0xFF14513F),
                                Color(0xFF09382C),
                              ]),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0x5568D8B0)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.graphic_eq_rounded,
                                          color: Color(0xFF8FEAC4), size: 20),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xCC081E16),
                                          borderRadius:
                                              BorderRadius.circular(9)),
                                        child: Text(code,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800)),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  CircleAvatar(
                                    radius: 27,
                                    backgroundColor: const Color(0xFF2C8060),
                                    foregroundImage: photo.isEmpty
                                        ? null : NetworkImage(photo),
                                    child: photo.isEmpty
                                        ? const Icon(Icons.person_rounded,
                                            size: 32, color: Colors.white)
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(name, maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFC0E5D4),
                                      fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(title.isEmpty
                                      ? (ar ? 'بث مباشر' : 'Live broadcast')
                                      : title,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white, fontSize: 14,
                                      fontWeight: FontWeight.w900)),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      const Icon(Icons.circle,
                                          color: Colors.redAccent, size: 9),
                                      const SizedBox(width: 4),
                                      const Text('LIVE', style: TextStyle(
                                        color: Color(0xFFFFC1B1),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900)),
                                      const Spacer(),
                                      const Icon(Icons.visibility_rounded,
                                          color: Colors.white70, size: 16),
                                      const SizedBox(width: 4),
                                      Text('$viewers',
                                        style: const TextStyle(
                                          color: Colors.white70)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<int> _currentUserStageLevel() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return 1;
  try {
    final snap =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = snap.data() ?? const <String, dynamic>{};
    for (final key in const ['liveLevel', 'roomLevel', 'level']) {
      final value = (data[key] as num?)?.toInt();
      if (value != null && value > 0) return value.clamp(1, 999);
    }
  } catch (_) {
    // Level bonus is optional; the base daily allowance still works.
  }
  return 1;
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
  final RoomQuotaService _quota = RoomQuotaService();
  Timer? _quotaTimer;
  int _quotaLevel = 1;
  bool _quotaStarted = false;

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
    _quotaTimer?.cancel();
    if (_quotaStarted) {
      unawaited(_quota.endSession());
      _quotaStarted = false;
    }
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

  Future<void> _confirmEndLive() async {
    if (!_cameraReady) {
      Navigator.of(context).pop();
      return;
    }
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(widget.ar ? 'إنهاء البث المباشر؟' : 'End this Live?'),
        content: Text(widget.ar
            ? 'سيتم إيقاف اللايف لجميع المشاهدين والضيوف.'
            : 'This ends the Live for all viewers and guests.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(widget.ar ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC93838)),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(widget.ar ? 'إنهاء اللايف' : 'End Live'),
          ),
        ],
      ),
    );
    if (approved == true && mounted) await _endLiveAndPop();
  }

  Future<void> _showHostLiveMenu() async {
    if (_liveId == null) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: Text(widget.ar ? 'مشاركة اللايف' : 'Share Live'),
              subtitle: Text(widget.ar
                  ? 'كمنشور، عبر الدردشة، ستوري، أو نسخ الرابط'
                  : 'Post, direct chat, story or copy link'),
              onTap: () {
                Navigator.pop(sheetContext);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) unawaited(_shareHostLive());
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_in_picture_alt_rounded),
              title: Text(widget.ar ? 'تصغير اللايف' : 'Minimize Live'),
              onTap: () {
                Navigator.pop(sheetContext);
                unawaited(_enterLiveMiniWindow(context, widget.ar));
              },
            ),
            ListTile(
              leading: const Icon(Icons.explore_rounded),
              title: Text(widget.ar ? 'استكشاف بثوث أخرى'
                : 'Explore other Lives'),
              subtitle: Text(widget.ar
                ? 'تصفح دون إيقاف الكاميرا أو اللايف'
                : 'Browse without interrupting your broadcast'),
              onTap: () {
                Navigator.pop(sheetContext);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _liveId != null) {
                    unawaited(_showLiveExploreDrawer(context,
                      currentLiveId: _liveId!, ar: widget.ar));
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_rounded),
              title: Text(widget.ar ? 'إدارة اللايف' : 'Live moderators'),
              onTap: () {
                Navigator.pop(sheetContext);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _liveId != null) {
                    unawaited(_showLiveModeratorManagement(context,
                      liveId: _liveId!, service: _liveService, ar: widget.ar));
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule_rounded),
              title: Text(widget.ar ? 'وقت اللايف' : 'Live time'),
              onTap: () {
                Navigator.pop(sheetContext);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) unawaited(_showHostQuotaStatus());
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.power_settings_new_rounded,
                  color: Colors.redAccent),
              title: Text(widget.ar ? 'إنهاء البث للجميع' : 'End Live for everyone',
                style: const TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(sheetContext);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) unawaited(_confirmEndLive());
                });
              },
            ),
            const SizedBox(height: 4),
            Text('WorldVoice Live UI • 2026.10.22.5',
              style: Theme.of(sheetContext).textTheme.labelSmall),
          ],
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
    _quotaTimer?.cancel();
    if (_quotaStarted) {
      await _quota.endSession();
      _quotaStarted = false;
    }
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

  void _startHostQuotaTimer() {
    _quotaTimer?.cancel();
    _quotaTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(_checkHostQuota()),
    );
  }

  Future<void> _checkHostQuota() async {
    if (!_quotaStarted || _sessionClosed) return;
    final status = await _quota.currentSessionStatus();
    if (status.allowed || status.isUnlimited || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.ar
              ? 'انتهى وقت استضافة اللايف اليوم.'
              : 'Your Live hosting time for today has ended.',
        ),
      ),
    );
    await _endLiveAndPop();
  }

  Future<void> _showHostQuotaStatus() async {
    final status = await _quota.currentSessionStatus();
    if (!mounted) return;
    String formatSeconds(int value) {
      final hours = value ~/ 3600;
      final minutes = (value % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(widget.ar ? 'وقت اللايف اليومي' : 'Daily Live time'),
        content: Text(
          status.isUnlimited
              ? (widget.ar ? 'VIP: وقت اللايف غير محدود.' : 'VIP: Live time is unlimited.')
              : (widget.ar
                  ? 'المتبقي: ${formatSeconds(status.remainingSeconds)}'
                  : 'Remaining: ${formatSeconds(status.remainingSeconds)}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(widget.ar ? 'إغلاق' : 'Close'),
          ),
        ],
      ),
    );
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
      _quotaLevel = await _currentUserStageLevel();
      final quotaStatus = await _quota.startSession(
        asHost: true,
        roomLevel: _quotaLevel,
      );
      if (!quotaStatus.allowed) {
        throw StateError(
          widget.ar
              ? 'انتهى وقت استضافة اللايف المتاح لك اليوم.'
              : 'Your Live hosting time for today has been used.',
        );
      }
      _quotaStarted = true;

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
      _startHostQuotaTimer();
      setState(() {
        _cameraReady = true;
        _starting = false;
        _cameraPaused = false;
        _cameraStartError = null;
      });
    } catch (error) {
      if (_quotaStarted) {
        await _quota.endSession();
        _quotaStarted = false;
      }
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
            if (!_cameraReady)
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
                        if (!_boardOpen)
                          Positioned.fill(
                            bottom: tiles.length >= 3
                                ? MediaQuery.sizeOf(context).height * .41
                                : 0,
                            child: _LiveVideoGrid(
                              labels: [
                                FirebaseAuth.instance.currentUser?.displayName ??
                                    (widget.ar ? 'المضيف' : 'Host'),
                                ...remote.map((_) => widget.ar ? 'ضيف' : 'Guest'),
                              ],
                              children: tiles,
                            ),
                          )
                        else
                          const ColoredBox(color: Color(0xFF081A15)),
                        if (_boardOpen)
                          PositionedDirectional(
                            top: 66,
                            end: 16,
                            child: Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: const Color(0xFF65E3B4),
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x55000000),
                                    blurRadius: 16,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _cameraPaused
                                  ? _LiveBoardAvatar(
                                      photoUrl: FirebaseAuth
                                              .instance.currentUser?.photoURL ??
                                          '',
                                    )
                                  : AgoraVideoView(
                                      controller: VideoViewController(
                                        rtcEngine: _controller.engine!,
                                        canvas: const VideoCanvas(uid: 0),
                                      ),
                                    ),
                            ),
                          ),
                        if (_boardOpen && _liveId != null)
                          Positioned(
                            left: 12,
                            right: 12,
                            top: 170,
                            height: MediaQuery.sizeOf(context).height * .40,
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
                            audioFrames: _controller.audioFrames,
                            ar: widget.ar,
                            onLiveOptions: _showHostLiveMenu,
                          ),
                        ),
                        if (_liveId != null)
                          Positioned.fill(
                            child: _LiveGiftEffects(liveId: _liveId!),
                          ),
                        if (_liveId != null)
                          PositionedDirectional(
                            top: 92,
                            end: 12,
                            child: _LiveProfileLanguages(
                              hostId: FirebaseAuth.instance.currentUser?.uid ?? '',
                              ar: widget.ar,
                            ),
                          ),
                        if (_chatOpen && _liveId != null)
                          PositionedDirectional(
                            start: 10,
                            end: 68,
                            bottom: 78 + MediaQuery.viewInsetsOf(context).bottom,
                            height: _boardOpen ? 98 : 124,
                            child: _LiveChatOverlay(
                              service: _liveService,
                              liveId: _liveId!,
                              ar: widget.ar,
                              showComposer: false,
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
                            composer: _liveId == null
                                ? null
                                : _LiveInlineComposer(
                                    service: _liveService,
                                    liveId: _liveId!,
                                    ar: widget.ar,
                                    onOpenChat: () {
                                      if (mounted && !_chatOpen) {
                                        setState(() => _chatOpen = true);
                                      }
                                    },
                                  ),
                            children: [
                              IconButton(
                                tooltip: widget.ar ? 'الشات' : 'Chat',
                                onPressed: () => setState(
                                  () => _chatOpen = !_chatOpen),
                                icon: const Icon(Icons.chat_bubble_outline_rounded,
                                  color: Colors.white),
                              ),
                              IconButton(
                                tooltip: widget.ar ? 'السبورة' : 'Whiteboard',
                                onPressed: _liveId == null ? null
                                  : () => setState(() => _boardOpen = !_boardOpen),
                                icon: Icon(_boardOpen
                                  ? Icons.dashboard_rounded
                                  : Icons.dashboard_outlined,
                                  color: Colors.white),
                              ),
                              IconButton(
                                tooltip: widget.ar ? 'طلبات الضيوف' : 'Guest requests',
                                onPressed: () => setState(
                                  () => _requestsOpen = !_requestsOpen),
                                icon: const Icon(Icons.group_add_rounded,
                                  color: Colors.white),
                              ),
                              IconButton(
                                tooltip: widget.ar ? 'الهدايا' : 'Gifts',
                                onPressed: _liveId == null ? null
                                  : () => _showLiveGifts(context,
                                    liveId: _liveId!, service: _liveService,
                                    hostId: FirebaseAuth.instance.currentUser?.uid ?? '',
                                    hostName: FirebaseAuth.instance.currentUser?.displayName ??
                                        'WorldVoice host', ar: widget.ar),
                                icon: const Icon(Icons.card_giftcard_rounded,
                                  color: Color(0xFFFFC857)),
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
                                onPressed: _confirmEndLive,
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

class _LiveInlineComposer extends StatefulWidget {
  const _LiveInlineComposer({
    required this.service,
    required this.liveId,
    required this.ar,
    required this.onOpenChat,
  });

  final LiveSessionService service;
  final String liveId;
  final bool ar;
  final VoidCallback onOpenChat;

  @override
  State<_LiveInlineComposer> createState() => _LiveInlineComposerState();
}

class _LiveInlineComposerState extends State<_LiveInlineComposer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _sending = false;

  Future<void> _send() async {
    final value = _controller.text.trim();
    if (value.isEmpty || _sending) return;
    setState(() => _sending = true);
    widget.onOpenChat();
    try {
      await widget.service.sendChat(widget.liveId, value);
      if (!mounted) return;
      _controller.clear();
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLength: 500,
        maxLines: 1,
        textInputAction: TextInputAction.send,
        onTap: widget.onOpenChat,
        onSubmitted: (_) => _send(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          counterText: '',
          hintText: widget.ar ? 'تعليق...' : 'Comment...',
          hintStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: const Color(0xB50B1511),
          isDense: true,
          contentPadding: const EdgeInsetsDirectional.fromSTEB(
            14,
            11,
            4,
            11,
          ),
          suffixIcon: IconButton(
            tooltip: widget.ar ? 'إرسال' : 'Send',
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox.square(
                    dimension: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.arrow_upward_rounded,
                    color: Color(0xFF65E3B4),
                  ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: .08),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: .08),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(
              color: Color(0xFF65E3B4),
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveControlDock extends StatelessWidget {
  const _LiveControlDock({
    required this.children,
    this.composer,
  });

  final List<Widget> children;
  final Widget? composer;
  final EdgeInsetsGeometry padding =
      const EdgeInsets.symmetric(horizontal: 8, vertical: 7);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xD9081712),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0x335FE6B5),
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 22,
            offset: Offset(0, 10),
            color: Color(0x44000000),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            if (composer != null) ...[
              Expanded(
                flex: 4,
                child: composer!,
              ),
              const SizedBox(width: 7),
            ],
            Expanded(
              flex: composer == null ? 1 : 7,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: children,
                ),
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
    this.miniMode = false,
    this.onMiniToggle,
    this.onClose,
    super.key,
  });
  final String liveId;
  final Map<String, dynamic> data;
  final bool ar;
  final bool miniMode;
  final VoidCallback? onMiniToggle;
  final VoidCallback? onClose;

  @override
  State<_LiveViewerScreen> createState() => _LiveViewerScreenState();
}

class _LiveViewerScreenState extends State<_LiveViewerScreen> {
  final AgoraVoiceRoomController _controller = AgoraVoiceRoomController();
  final LiveSessionService _service = LiveSessionService();
  final RoomQuotaService _guestQuota = RoomQuotaService();
  final RoomRewardedAdService _rewardedAds = RoomRewardedAdService();
  Timer? _guestQuotaTimer;
  int _guestQuotaLevel = 1;
  bool _guestQuotaStarted = false;
  bool _guestQuotaHandling = false;
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

  Future<void> _closeViewer() async {
    if (widget.onClose != null) {
      widget.onClose!();
    } else if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Widget _miniPlayer(Map<String, dynamic>? live) {
    return Scaffold(
      backgroundColor: const Color(0xFF081B16),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final engine = _controller.engine;
              final remote = _controller.remoteSpeakers;
              if (_joining || engine == null || remote.isEmpty) {
                return const Center(
                  child: Icon(Icons.live_tv_rounded,
                    color: Color(0xFF81E3BD), size: 55),
                );
              }
              final hostAgoraUid =
                  (live?['hostAgoraUid'] as num?)?.toInt() ??
                  (widget.data['hostAgoraUid'] as num?)?.toInt();
              final selected = hostAgoraUid != null &&
                      remote.contains(hostAgoraUid)
                  ? hostAgoraUid : remote.first;
              return AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: engine,
                  canvas: VideoCanvas(uid: selected),
                  connection: RtcConnection(channelId: widget.liveId),
                ),
              );
            },
          ),
          const IgnorePointer(
            child: DecoratedBox(decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xAD000000), Color(0x00000000),
                  Color(0xA6000000)],
              ),
            )),
          ),
          PositionedDirectional(
            top: 4, start: 4, end: 4,
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFBC2832),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('LIVE', style: TextStyle(
                  color: Colors.white, fontSize: 10,
                  fontWeight: FontWeight.w900)),
              ),
              const Spacer(),
              IconButton(
                constraints: const BoxConstraints(minWidth: 30,
                  minHeight: 30),
                visualDensity: VisualDensity.compact,
                onPressed: widget.onMiniToggle,
                icon: const Icon(Icons.open_in_full_rounded,
                  color: Colors.white, size: 18),
              ),
              IconButton(
                constraints: const BoxConstraints(minWidth: 30,
                  minHeight: 30),
                visualDensity: VisualDensity.compact,
                onPressed: _closeViewer,
                icon: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 18),
              ),
            ]),
          ),
          PositionedDirectional(
            bottom: 8, start: 9, end: 9,
            child: Text(
              (live?['hostName'] ?? widget.data['hostName'] ??
                 'WorldVoice LIVE').toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

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

  Future<void> _showViewerLiveMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.share_rounded),
            title: Text(widget.ar ? 'مشاركة اللايف' : 'Share Live'),
            subtitle: Text(widget.ar
                ? 'كمنشور أو عبر الدردشة أو الستوري'
                : 'Post, direct chat or story'),
            onTap: () {
              Navigator.pop(sheetContext);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) unawaited(_shareLive());
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.picture_in_picture_alt_rounded),
            title: Text(widget.ar ? 'تصغير اللايف' : 'Minimize Live'),
            onTap: () {
              Navigator.pop(sheetContext);
              if (widget.onMiniToggle != null) {
                widget.onMiniToggle!();
              } else {
                unawaited(_enterLiveMiniWindow(context, widget.ar));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.explore_rounded),
            title: Text(widget.ar ? 'استكشف بثوثًا أخرى'
                : 'Explore other Lives'),
            onTap: () {
              Navigator.pop(sheetContext);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                unawaited(_showLiveExploreDrawer(
                  context, currentLiveId: widget.liveId,
                  ar: widget.ar, onChooseLive: (newId) async {
                    final navigator = Navigator.of(context);
                    await _closeViewer();
                    // The previous Agora session releases during dispose.
                    await Future<void>.delayed(
                      const Duration(milliseconds: 120));
                    if (!navigator.mounted) return;
                    await navigator.push<void>(MaterialPageRoute(
                      builder: (_) => WorldVoiceLiveInvitationPage(
                        liveId: newId),
                    ));
                  },
                ));
              });
            },
          ),
          if (_isModerator)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_rounded),
              title: Text(widget.ar ? 'طلبات الضيوف' : 'Guest requests'),
              onTap: () {
                Navigator.pop(sheetContext);
                if (mounted) {
                  setState(() =>
                    _moderatorRequestsOpen = !_moderatorRequestsOpen);
                }
              },
            ),
          if (_guestPublishing) ...[
            ListTile(
              leading: Icon(_guestMicMuted ? Icons.mic_off_rounded
                  : Icons.mic_rounded),
              title: Text(widget.ar ? 'الميكروفون' : 'Microphone'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final next = !_guestMicMuted;
                await _controller.setMuted(next);
                if (mounted) setState(() => _guestMicMuted = next);
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_fix_high_rounded),
              title: Text(widget.ar ? 'فلاتر الكاميرا' : 'Camera & filters'),
              onTap: () {
                Navigator.pop(sheetContext);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  unawaited(_showLiveCameraTools(
                    context,
                    controller: _controller,
                    ar: widget.ar,
                    beautyEnabled: _guestBeautyEnabled,
                    filterPreset: _guestFilterPreset,
                    backgroundBlurEnabled: _guestBackgroundBlurEnabled,
                    zoom: _guestCameraZoom,
                    onBeautyChanged: (value) {
                      if (mounted) setState(() => _guestBeautyEnabled = value);
                    },
                    onFilterPresetChanged: (value) {
                      if (mounted) setState(() => _guestFilterPreset = value);
                    },
                    onBackgroundBlurChanged: (value) {
                      if (mounted) {
                        setState(() => _guestBackgroundBlurEnabled = value);
                      }
                    },
                    onZoomChanged: (value) {
                      if (mounted) setState(() => _guestCameraZoom = value);
                    },
                  ));
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_off_rounded),
              title: Text(widget.ar ? 'النزول من الكاميرا'
                  : 'Leave the camera stage'),
              onTap: () {
                Navigator.pop(sheetContext);
                unawaited(_leaveGuestCamera());
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule_rounded),
              title: Text(widget.ar ? 'وقت الضيف' : 'Guest time'),
              onTap: () {
                Navigator.pop(sheetContext);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) unawaited(_showGuestQuotaStatus());
                });
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: Text(widget.ar ? 'مغادرة اللايف' : 'Leave Live'),
            onTap: () {
              Navigator.pop(sheetContext);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) unawaited(_closeViewer());
              });
            },
          ),
          Text('WorldVoice Live UI • 2026.10.22.5',
              style: Theme.of(sheetContext).textTheme.labelSmall),
        ]),
      ),
    );
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
    _guestQuotaTimer?.cancel();
    if (_guestQuotaStarted) {
      unawaited(_guestQuota.endSession());
      _guestQuotaStarted = false;
    }
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

  void _startGuestQuotaTimer() {
    _guestQuotaTimer?.cancel();
    _guestQuotaTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(_checkGuestQuota()),
    );
  }

  Future<bool> _askGuestRewardedAd(RoomQuotaStatus status) async {
    final next = (status.adsWatched + 1).clamp(1, 3);
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              widget.ar ? 'وقت إضافي للايف' : 'Get more Live time',
            ),
            content: Text(
              widget.ar
                  ? 'شاهد الإعلان $next من 3 كاملًا. بعد 3 إعلانات تحصل على 3 ساعات إضافية اليوم.'
                  : 'Watch rewarded ad $next of 3 completely. Completing all 3 adds 3 extra hours today.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(widget.ar ? 'البقاء كمشاهد' : 'Stay as viewer'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(dialogContext, true),
                icon: const Icon(Icons.ondemand_video_rounded),
                label: Text(widget.ar ? 'مشاهدة الإعلان' : 'Watch ad'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _extendGuestQuotaWithAds() async {
    var current = await _guestQuota.check(
      asHost: false,
      roomLevel: _guestQuotaLevel,
    );
    if (current.isUnlimited || current.allowed) return true;

    while (mounted &&
        current.adsWatched < 3 &&
        current.adBonusSeconds < 3 * 60 * 60) {
      final watch = await _askGuestRewardedAd(current);
      if (!watch || !mounted) return false;

      final earned = await _rewardedAds.show();
      if (!mounted) return false;
      if (!earned) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.ar
                  ? 'لم يكتمل الإعلان، لذلك لم يتم احتسابه.'
                  : 'The ad was not completed, so it was not counted.',
            ),
          ),
        );
        continue;
      }
      current = await _guestQuota.recordRewardedAdWatched();
    }

    current = await _guestQuota.check(
      asHost: false,
      roomLevel: _guestQuotaLevel,
    );
    return current.allowed || current.isUnlimited;
  }

  Future<void> _checkGuestQuota() async {
    if (!_guestPublishing ||
        !_guestQuotaStarted ||
        _guestQuotaHandling ||
        !mounted) {
      return;
    }
    final status = await _guestQuota.currentSessionStatus();
    if (status.allowed || status.isUnlimited || !mounted) return;

    _guestQuotaHandling = true;
    try {
      await _controller.setCameraPublishing(false);
      await _controller.switchRole(AgoraRoomRole.listener);
      await _guestQuota.endSession();
      _guestQuotaStarted = false;

      final extended = await _extendGuestQuotaWithAds();
      if (!extended || !mounted) {
        await _service.leaveGuest(widget.liveId);
        if (!mounted) return;
        setState(() {
          _guestPublishing = false;
          _guestMicMuted = false;
          _requested = false;
        });
        return;
      }

      final restarted = await _guestQuota.startSession(
        asHost: false,
        roomLevel: _guestQuotaLevel,
      );
      if (!restarted.allowed || !mounted) {
        await _service.leaveGuest(widget.liveId);
        if (mounted) {
          setState(() {
            _guestPublishing = false;
            _requested = false;
          });
        }
        return;
      }
      _guestQuotaStarted = true;
      await _controller.switchRole(AgoraRoomRole.speaker);
      await _controller.setCameraPublishing(true);
      if (mounted) {
        setState(() {
          _guestPublishing = true;
          _guestMicMuted = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.ar
                  ? 'تمت إضافة 3 ساعات إضافية للايف اليوم.'
                  : '3 extra Live hours were added for today.',
            ),
          ),
        );
      }
    } finally {
      _guestQuotaHandling = false;
    }
  }

  Future<void> _showGuestQuotaStatus() async {
    final status = await _guestQuota.currentSessionStatus();
    if (!mounted) return;

    String formatSeconds(int value) {
      final hours = value ~/ 3600;
      final minutes = (value % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(widget.ar ? 'وقت الضيف اليومي' : 'Daily guest time'),
        content: status.isUnlimited
            ? Text(
                widget.ar
                    ? 'VIP: وقت الصعود في اللايف غير محدود.'
                    : 'VIP: Live guest time is unlimited.',
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.ar
                        ? 'المتبقي: ${formatSeconds(status.remainingSeconds)}'
                        : 'Remaining: ${formatSeconds(status.remainingSeconds)}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.ar
                        ? 'الإعلانات المكتملة: ${status.adsWatched}/3'
                        : 'Rewarded ads completed: ${status.adsWatched}/3',
                  ),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(widget.ar ? 'إغلاق' : 'Close'),
          ),
        ],
      ),
    );
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
            if (mounted) _closeViewer();
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
        if (widget.miniMode) return _miniPlayer(live);
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
                      if (mounted) _closeViewer();
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
                      if (!_boardOpen)
                        if (tiles.isNotEmpty)
                          Positioned.fill(
                            bottom: tiles.length >= 3
                                ? MediaQuery.sizeOf(context).height * .41
                                : 0,
                            child: _LiveVideoGrid(
                              labels: [
                                if (_guestPublishing)
                                  FirebaseAuth.instance.currentUser?.displayName ??
                                      (widget.ar ? 'أنا' : 'Me'),
                                ...remote.take(_guestPublishing ? 3 : 4).map(
                                  (id) => id == hostAgoraUid
                                    ? (live?['hostName'] ?? widget.data['hostName'] ??
                                        'Host').toString()
                                    : (widget.ar ? 'ضيف' : 'Guest'),
                                ),
                              ],
                              children: tiles,
                            ),
                          )
                        else
                          const Center(
                            child: Icon(
                              Icons.live_tv_rounded,
                              color: Colors.white54,
                              size: 72,
                            ),
                          )
                      else
                        const ColoredBox(color: Color(0xFF081A15)),
                      if (_boardOpen)
                        PositionedDirectional(
                          top: 66,
                          end: 16,
                          child: Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0xFF65E3B4),
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x55000000),
                                  blurRadius: 16,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: engine != null &&
                                    (hostAgoraUid != null
                                        ? remote.contains(hostAgoraUid)
                                        : remote.isNotEmpty)
                                ? AgoraVideoView(
                                    controller: VideoViewController.remote(
                                      rtcEngine: engine,
                                      canvas: VideoCanvas(
                                        uid: hostAgoraUid ??
                                            remote.first,
                                      ),
                                      connection: RtcConnection(
                                        channelId: widget.liveId,
                                      ),
                                    ),
                                  )
                                : _LiveBoardAvatar(
                                    photoUrl:
                                        (live?['hostPhotoUrl'] ??
                                                widget.data['hostPhotoUrl'] ??
                                                '')
                                            .toString(),
                                  ),
                          ),
                        ),
                      if (_boardOpen)
                        Positioned(
                          left: 12,
                          right: 12,
                          top: 170,
                          height: MediaQuery.sizeOf(context).height * .40,
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
                          audioFrames: _controller.audioFrames,
                          ar: widget.ar,
                          onLiveOptions: _showViewerLiveMenu,
                        ),
                      ),
                      Positioned.fill(
                        child: _LiveGiftEffects(liveId: widget.liveId),
                      ),
                      PositionedDirectional(
                        top: 92,
                        end: 12,
                        child: _LiveProfileLanguages(
                          hostId: (live?['hostId'] ?? widget.data['hostId'] ?? '').toString(),
                          ar: widget.ar,
                        ),
                      ),
                      if (_chatOpen)
                        PositionedDirectional(
                          start: 10,
                          end: 68,
                          bottom: 78 + MediaQuery.viewInsetsOf(context).bottom,
                          height: _boardOpen ? 98 : 124,
                          child: _LiveChatOverlay(
                            service: _service,
                            liveId: widget.liveId,
                            ar: widget.ar,
                            showComposer: false,
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
                                  onPressed: _closeViewer,
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

                          composer: _LiveInlineComposer(
                            service: _service,
                            liveId: widget.liveId,
                            ar: widget.ar,
                            onOpenChat: () {
                              if (mounted && !_chatOpen) {
                                setState(() => _chatOpen = true);
                              }
                            },
                          ),
                          children: [
                            IconButton(
                              tooltip: widget.ar ? 'الشات' : 'Chat',
                              onPressed: () => setState(() => _chatOpen = !_chatOpen),
                              icon: const Icon(Icons.chat_bubble_outline_rounded,
                                  color: Colors.white),
                            ),
                            IconButton(
                              tooltip: widget.ar ? 'السبورة' : 'Whiteboard',
                              onPressed: () => setState(() {
                                _boardOpen = !_boardOpen;
                                if (_boardOpen) _chatOpen = true;
                              }),
                              icon: Icon(_boardOpen ? Icons.dashboard_rounded
                                  : Icons.dashboard_outlined, color: Colors.white),
                            ),
                            IconButton(
                              tooltip: widget.ar ? 'الهدايا' : 'Gifts',
                              onPressed: () => _showLiveGifts(context,
                                liveId: widget.liveId, service: _service,
                                hostId: (live?['hostId'] ??
                                    widget.data['hostId'] ?? '').toString(),
                                hostName: (live?['hostName'] ??
                                    widget.data['hostName'] ??
                                    'WorldVoice host').toString(),
                                ar: widget.ar),
                              icon: const Icon(Icons.card_giftcard_rounded,
                                color: Color(0xFFFFC857)),
                            ),
                            if (!_guestPublishing)
                              IconButton(
                                tooltip: _requested
                                    ? (widget.ar ? 'تم طلب الانضمام' : 'Request sent')
                                    : (widget.ar ? 'طلب الصعود' : 'Join stage'),
                                onPressed: _requested ? null : _requestCamera,
                                icon: Icon(_requested
                                    ? Icons.hourglass_top_rounded
                                    : Icons.group_add_rounded,
                                  color: Colors.white),
                              )
                            else
                              IconButton(
                                tooltip: widget.ar ? 'الميكروفون' : 'Microphone',
                                onPressed: () async {
                                  final next = !_guestMicMuted;
                                  await _controller.setMuted(next);
                                  if (mounted) setState(() => _guestMicMuted = next);
                                },
                                icon: Icon(_guestMicMuted
                                    ? Icons.mic_off_rounded
                                    : Icons.mic_rounded, color: Colors.white),
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
      _guestQuotaTimer?.cancel();
      if (_guestQuotaStarted) {
        await _guestQuota.endSession();
        _guestQuotaStarted = false;
      }
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
      _guestQuotaLevel = await _currentUserStageLevel();
      var quotaStatus = await _guestQuota.startSession(
        asHost: false,
        roomLevel: _guestQuotaLevel,
      );
      if (!quotaStatus.allowed) {
        final extended = await _extendGuestQuotaWithAds();
        if (!extended) {
          throw StateError(
            widget.ar
                ? 'انتهى وقت صعودك في اللايف اليوم.'
                : 'Your Live guest time for today has been used.',
          );
        }
        quotaStatus = await _guestQuota.startSession(
          asHost: false,
          roomLevel: _guestQuotaLevel,
        );
      }
      if (!quotaStatus.allowed) {
        throw StateError(
          widget.ar
              ? 'لا يوجد وقت صعود متاح الآن.'
              : 'No Live guest time is available right now.',
        );
      }
      _guestQuotaStarted = true;

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
      _startGuestQuotaTimer();
      if (mounted) {
        setState(() => _guestMicMuted = false);
      }
    } catch (error) {
      _guestPublishing = false;
      _guestQuotaTimer?.cancel();
      if (_guestQuotaStarted) {
        await _guestQuota.endSession().catchError((Object _) {});
        _guestQuotaStarted = false;
      }
      await _service.leaveGuest(widget.liveId).catchError((Object _) {});
      if (!mounted) return;
      setState(() => _requested = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }
}

class _LiveBoardAvatar extends StatelessWidget {
  const _LiveBoardAvatar({required this.photoUrl});

  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl.trim();
    return ColoredBox(
      color: const Color(0xFF17372D),
      child: Center(
        child: CircleAvatar(
          radius: 32,
          backgroundImage: url.isEmpty ? null : NetworkImage(url),
          child: url.isEmpty
              ? const Icon(Icons.person_rounded, size: 34)
              : null,
        ),
      ),
    );
  }
}

class _LiveLanguageToolsOverlay extends StatefulWidget {
  const _LiveLanguageToolsOverlay({
    required this.liveId,
    required this.roomLanguageCode,
    required this.canPublish,
    required this.displayName,
    required this.audioFrames,
    required this.ar,
    this.onLiveOptions,
  });

  final String liveId;
  final String roomLanguageCode;
  final bool canPublish;
  final String displayName;
  final Stream<AgoraRoomAudioFrame> audioFrames;
  final bool ar;
  final VoidCallback? onLiveOptions;

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
  StreamSubscription<List<RoomTeacherAiSpokenAnswer>>? _teacherVoiceSub;

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
  String? _lastPronunciationCaptionId;
  final ValueNotifier<RoomTeacherAiNote?> _pronunciationNote =
      ValueNotifier<RoomTeacherAiNote?>(null);
  bool _teacherVoicePrimed = false;
  String? _lastTeacherVoiceId;
  bool _teacherConversationActive = false;
  bool _teacherAskBusy = false;
  RoomCaption? _queuedTeacherCaption;
  String? _lastTeacherPromptCaptionId;
  final ValueNotifier<bool> _teacherOnline =
      ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _captionService = RoomCaptionService(
      roomId: widget.liveId,
      collectionName: 'live_sessions',
    );
    _translationService = RoomTranslationService(
      roomId: widget.liveId,
      collectionName: 'live_sessions',
    );
    _teacherAi = RoomTeacherAiService(
      roomId: widget.liveId,
      collectionName: 'live_sessions',
    );
    _captionController = RoomLiveCaptionController(
      service: _captionService,
      audioFrames: widget.audioFrames,
      onState: ({required bool listening, String? error}) {
        if (!mounted) return;
        setState(() {
          _listening = listening;
          if (error?.trim().isNotEmpty == true) _error = error;
        });
      },
    );
    unawaited(_loadNativeLanguage());
    unawaited(_syncPublishing());
    if (widget.liveId.isNotEmpty) {
      _captionSub = _captionService.watchLatest().listen(
        _handleCaptions,
        onError: (Object error) {
          if (mounted) setState(() => _error = error.toString());
        },
      );
      _teacherVoiceSub =
          _teacherAi.watchSpokenAnswers().listen(_handleTeacherVoice);
    }
  }

  Future<void> _loadNativeLanguage() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = snapshot.data();
      final raw =
          (data?['nativeLanguageCode'] ?? data?['nativeLanguage'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
      if (raw.isEmpty) return;
      final code = raw.split(RegExp(r'[-_]')).first;
      if (!roomCaptionLanguages.any((item) => item.code == code)) return;
      if (!mounted) return;
      setState(() {
        _targetLanguage = code;
        _targetInitialized = true;
        _translated = null;
        _translatedCaptionId = null;
      });
      if (_translationEnabled) {
        unawaited(_prepareTranslationModels());
      }
    } catch (error) {
      debugPrint('WorldVoice Live native language unavailable: $error');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_targetInitialized) {
      _targetInitialized = true;
      final uiLanguage =
          Localizations.localeOf(context).languageCode.toLowerCase();
      _targetLanguage = roomCaptionLanguages.any(
        (item) => item.code == uiLanguage,
      )
          ? uiLanguage
          : 'en';
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
    if (oldWidget.canPublish != widget.canPublish ||
        oldWidget.displayName != widget.displayName ||
        oldWidget.roomLanguageCode != widget.roomLanguageCode) {
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
        latest.userId == FirebaseAuth.instance.currentUser?.uid &&
        latest.id != _lastPronunciationCaptionId) {
      _lastPronunciationCaptionId = latest.id;
      final note = _teacherAi.localPronunciationNote(
        caption: latest,
        roomLanguageCode: widget.roomLanguageCode,
      );
      _pronunciationNote.value = note;
      if (_teacherAi.isConfigured) {
        unawaited(
          _teacherAi
              .submitCaption(
                caption: latest,
                roomLanguageCode: widget.roomLanguageCode,
              )
              .catchError((Object _) => false),
        );
      }
    }

    if (_teacherConversationActive &&
        latest != null &&
        latest.userId == FirebaseAuth.instance.currentUser?.uid &&
        latest.id != _lastTeacherPromptCaptionId &&
        latest.text.trim().isNotEmpty) {
      _lastTeacherPromptCaptionId = latest.id;
      unawaited(_queueLiveTeacherReply(latest));
    }
  }

  Future<void> _queueLiveTeacherReply(RoomCaption caption) async {
    if (_teacherAskBusy) {
      _queuedTeacherCaption = caption;
      return;
    }

    _teacherAskBusy = true;
    try {
      var current = caption;
      while (mounted && _teacherConversationActive) {
        final prompt = current.text.trim();
        if (prompt.isNotEmpty) {
          try {
            await _teacherAi.ask(
              prompt: prompt,
              roomLanguageCode: widget.roomLanguageCode,
            );
            _teacherOnline.value = true;
          } catch (error) {
            final message = error.toString();
            if (message.contains('AI_SERVICE_UNAVAILABLE')) {
              _teacherOnline.value = false;
              if (mounted) {
                setState(() {
                  _error = widget.ar
                      ? 'Teacher AI غير متصل الآن بخدمة الذكاء.'
                      : 'Teacher AI is offline right now.';
                });
              }
              break;
            }
            if (mounted) {
              setState(() {
                _error = message.replaceFirst('Bad state: ', '');
              });
            }
          }
        }

        final next = _queuedTeacherCaption;
        _queuedTeacherCaption = null;
        if (next == null || next.id == current.id) break;
        current = next;
      }
    } finally {
      _teacherAskBusy = false;
    }
  }

  void _handleTeacherVoice(List<RoomTeacherAiSpokenAnswer> messages) {
    if (!mounted) return;
    if (messages.isEmpty) {
      _teacherVoicePrimed = true;
      return;
    }
    final latest = messages.first;
    if (!_teacherVoicePrimed) {
      _teacherVoicePrimed = true;
      _lastTeacherVoiceId = latest.id;
      return;
    }
    if (latest.id == _lastTeacherVoiceId) return;
    _lastTeacherVoiceId = latest.id;
    final roomLanguage = widget.roomLanguageCode.trim().toLowerCase();
    final answerLanguage = latest.languageCode.trim().toLowerCase();
    if (answerLanguage.isNotEmpty && answerLanguage != roomLanguage) return;
    unawaited(_speakLiveTeacher(latest.answer, roomLanguage));
  }

  Future<void> _translate(RoomCaption caption) async {
    _translatedCaptionId = caption.id;
    try {
      final value = await _translationService.translateAuto(
        text: caption.text,
        targetCode: _targetLanguage,
        fallbackSourceCode: caption.languageCode,
      );
      if (!mounted || _latest?.id != caption.id) return;
      setState(() => _translated = value);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _syncPublishing() => _captionController.configure(
        enabled: widget.canPublish,
        canPublish: widget.canPublish,
        captureRemote: false,
        languageCode: widget.roomLanguageCode,
        displayName: widget.displayName,
      );

  Future<void> _prepareTranslationModels() async {
    try {
      await _translationService.preparePair(
        sourceCode: widget.roomLanguageCode,
        targetCode: _targetLanguage,
      );
      if (!mounted) return;
      setState(() => _error = null);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  Future<void> _setEnabled(bool value) async {
    setState(() {
      _enabled = value;
      if (!value) {
        _translated = null;
        _error = null;
      }
    });
    // Caption publishing for speakers is kept active independently of
    // whether this viewer chose to display subtitles.
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

    final online = await _teacherAi.probeAvailability();
    if (!mounted) return;
    _teacherOnline.value = online;

    if (!online) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => RoomTeacherAiSheet(
          service: _teacherAi,
          roomLanguageCode: widget.roomLanguageCode,
          canSpeak: widget.canPublish,
          listening: false,
          online: false,
          onlineListenable: _teacherOnline,
          closeAfterAnswer: true,
        ),
      );
      return;
    }

    setState(() {
      _teacherConversationActive = true;
      _error = null;
    });
    await _syncPublishing();
    if (!mounted) return;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => RoomTeacherAiSheet(
          service: _teacherAi,
          roomLanguageCode: widget.roomLanguageCode,
          canSpeak: widget.canPublish,
          listening: widget.canPublish,
          online: true,
          onlineListenable: _teacherOnline,
          closeAfterAnswer: true,
          onVoicePressed: () => unawaited(_syncPublishing()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _teacherConversationActive = false;
          _queuedTeacherCaption = null;
        });
        await _syncPublishing();
      }
    }
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
            pronunciationNotes: _teacherAi.watchNotes().map(
              (notes) => notes
                  .where(
                    (note) =>
                        note.userId == FirebaseAuth.instance.currentUser?.uid,
                  )
                  .toList(growable: false),
            ),
            pronunciationNote: _pronunciationNote,
            targetLanguage: _targetLanguage,
            targetLanguages: roomCaptionLanguages,
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
              if (value) {
                unawaited(_prepareTranslationModels());
              }
              final latest = _latest;
              if (value && latest != null) unawaited(_translate(latest));
              refresh(() {});
            },
            onPronunciationChanged: (value) {
              setState(() {
                _pronunciationEnabled = value;
                _lastPronunciationCaptionId = null;
                _error = null;
              });
              if (!value) {
                _pronunciationNote.value = null;
              }
              final latest = _latest;
              if (value &&
                  latest != null &&
                  latest.userId == FirebaseAuth.instance.currentUser?.uid) {
                _lastPronunciationCaptionId = latest.id;
                _pronunciationNote.value = _teacherAi.localPronunciationNote(
                  caption: latest,
                  roomLanguageCode: widget.roomLanguageCode,
                );
              }
              refresh(() {});
            },
            onTargetLanguageChanged: (value) {
              setState(() {
                _targetLanguage = value;
                _translated = null;
                _translatedCaptionId = null;
              });
              if (_translationEnabled) {
                unawaited(_prepareTranslationModels());
              }
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
    unawaited(_teacherVoiceSub?.cancel());
    unawaited(_captionController.dispose());
    unawaited(_translationService.dispose());
    _pronunciationNote.dispose();
    _teacherOnline.dispose();
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
                tooltip: widget.ar ? 'الترجمة والـ AI' : 'Language & AI tools',
                onPressed: _showMoreTools,
                icon: const Icon(Icons.language_rounded),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                tooltip: widget.ar ? 'خيارات اللايف' : 'Live options',
                onPressed: widget.onLiveOptions ?? _showMoreTools,
                icon: const Icon(Icons.more_horiz_rounded),
              ),
            ],
          ),
        ),
        if ((_enabled || _translationEnabled) && caption != null)
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_enabled)
                        Text(
                          caption.text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      if (_translationEnabled &&
                          _translated?.trim().isNotEmpty == true) ...[
                        if (_enabled) const SizedBox(height: 5),
                        Text(
                          _translated!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF8EEAD0),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
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
            // Keep the catalog available to a solo host for free effect
            // previews; paid delivery stays disabled without a recipient.
            // Viewers default to the host, and can switch to an active guest.
            return UnifiedGiftPanel(
              contextType: 'live',
              contextId: liveId,
              recipients: recipients,
              initialRecipientId: myId == hostId ? null : hostId,
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

class _LiveProfileLanguages extends StatelessWidget {
  const _LiveProfileLanguages({required this.hostId, required this.ar});
  final String hostId;
  final bool ar;

  @override
  Widget build(BuildContext context) {
    if (hostId.isEmpty) return const SizedBox.shrink();
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(hostId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        if (data == null) return const SizedBox.shrink();
        final native = (data['nativeLanguageCode'] ?? '').toString().trim();
        final raw = data['learningLanguageCodes'];
        final learning = raw is List
            ? raw.map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty && e != native).toSet().take(3).toList()
            : <String>[];
        if (native.isEmpty && learning.isEmpty) return const SizedBox.shrink();
        final nativeLabel = native.isEmpty ? '' : ProfileLanguageCatalog.label(native);
        final learningLabel = learning.map(ProfileLanguageCatalog.label).join(' · ');
        return IgnorePointer(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 228),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xB3082D21),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              [
                if (native.isNotEmpty) '${ar ? 'الأم' : 'Native'}: $nativeLabel',
                if (learning.isNotEmpty) '${ar ? 'أتعلم' : 'Learning'}: $learningLabel',
              ].join('  •  '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 11,
                fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }
}

/// Opens a shared Live from a story, feed post, or chat message.
Future<void> openWorldVoiceLive(BuildContext context, {
  required String liveId,
}) => openSharedWorldVoiceLive(context, liveId,
    ar: Localizations.localeOf(context).languageCode == 'ar');

String? worldVoiceLiveIdInText(String text) =>
    WorldVoiceLiveLinks.extract(text);

Future<void> _publishLiveStory(BuildContext context, {
  required String liveId,
  required bool ar,
}) async {
  try {
    await StoryService().shareLive(liveId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ar
          ? 'تم نشر دعوة اللايف في الستوري.'
          : 'Live invitation shared to your story.')),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))),
    );
  }
}

String _liveShareUri(String liveId) => WorldVoiceLiveLinks.web(liveId);

String _liveShareText({
  required String liveId,
  required String topic,
  required String hostName,
}) {
  final cleanTopic = topic.trim();
  final title = cleanTopic.isEmpty ? 'WorldVoice Live' : cleanTopic;
  return '🔴 WorldVoice Live\n$title\n$hostName\n${_liveShareUri(liveId)}';
}

/// Browse other Live streams without interrupting the currently joined
/// Agora session. This panel sits above the video, like a compact discovery
/// drawer; it never touches or rebuilds the voice-room screen.
Future<void> _showLiveExploreDrawer(
  BuildContext context, {
  required String currentLiveId,
  required bool ar,
  Future<void> Function(String id)? onChooseLive,
}) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: true,
  barrierLabel: ar ? 'إغلاق الاستكشاف' : 'Close discovery',
  barrierColor: Colors.black54,
  transitionDuration: const Duration(milliseconds: 230),
  transitionBuilder: (context, animation, _, child) =>
    SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: child,
    ),
  pageBuilder: (dialogContext, _, _) => Align(
    alignment: Alignment.centerLeft,
    child: FractionallySizedBox(
      widthFactor: .84,
      heightFactor: 1,
      child: Material(
        color: const Color(0xFF0A1F1A),
        child: SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.live_tv_rounded,
                color: Color(0xFFFFD67D)),
              const SizedBox(width: 8),
              Expanded(child: Text(
                ar ? 'استكشف البثوث المباشرة' : 'Explore live broadcasts',
                style: const TextStyle(color: Colors.white,
                  fontSize: 17, fontWeight: FontWeight.w900))),
              IconButton(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close_rounded,
                  color: Colors.white),
              ),
            ]),
            const SizedBox(height: 10),
            Expanded(child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: LiveSessionService().watchOpen(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text(ar
                    ? 'تعذر تحميل اللايفات.' : 'Could not load Lives.',
                    style: const TextStyle(color: Colors.white70)));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs.where((doc) =>
                    doc.id != currentLiveId &&
                    LiveSessionService.isFresh(doc.data()))
                    .toList(growable: false);
                if (docs.isEmpty) {
                  return Center(child: Text(ar
                    ? 'لا توجد بثوث أخرى الآن.'
                    : 'No other active Lives yet.',
                    style: const TextStyle(color: Colors.white70)));
                }
                return GridView.builder(
                  itemCount: docs.length,
                  gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 9,
                      mainAxisSpacing: 9,
                      childAspectRatio: .72,
                    ),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final live = doc.data();
                    final photo = (live['hostPhotoUrl'] ?? '').toString();
                    final name = (live['hostName'] ?? 'WorldVoice')
                        .toString();
                    final topic = (live['topic'] ?? '').toString();
                    final count = live['viewerCount'] ?? 0;
                    final code =
                        (live['languageCode'] ?? '').toString().toUpperCase();
                    return InkWell(
                      onTap: onChooseLive == null ? null : () {
                        Navigator.pop(dialogContext);
                        unawaited(onChooseLive(doc.id));
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: const Color(0xFF174234),
                          border: Border.all(
                            color: const Color(0xFF33775D)),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(9),
                          child: Column(children: [
                            Row(children: [
                              const Icon(Icons.circle,
                                size: 8, color: Colors.redAccent),
                              const Spacer(),
                              const Icon(Icons.visibility_rounded,
                                size: 15, color: Colors.white70),
                              const SizedBox(width: 3),
                              Text('$count', style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                            ]),
                            const Spacer(),
                            CircleAvatar(radius: 27,
                              foregroundImage: photo.isEmpty
                                ? null : NetworkImage(photo),
                              backgroundColor: const Color(0xFF35725C),
                              child: photo.isEmpty
                                ? const Icon(Icons.person_rounded,
                                    color: Colors.white)
                                : null,
                            ),
                            const SizedBox(height: 7),
                            Text(name, maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFFFDA87),
                                fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(topic, textAlign: TextAlign.center,
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                            const Spacer(),
                            Text(code, style: const TextStyle(
                              color: Color(0xFFA8E8CC),
                              fontWeight: FontWeight.w900)),
                          ]),
                        ),
                      ),
                    );
                  },
                );
              },
            )),
            const SizedBox(height: 10),
            Text(
              onChooseLive == null
                ? (ar ? 'أنت تبث الآن؛ يمكنك الاستكشاف دون إيقاف بثك.'
                    : 'Explore without ending your broadcast.')
                : (ar ? 'اختر لايف للانتقال إليه.'
                    : 'Select a Live to switch streams.'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFD2E8DC), fontSize: 12),
            ),
          ]),
        )),
      ),
    ),
  ),
);

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
              child: Icon(Icons.post_add_rounded),
            ),
            title: Text(
              ar ? 'نشر اللايف كمنشور' : 'Share Live as a post',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              ar
                  ? 'انشره في الصفحة الرئيسية ليتمكن الآخرون من الدخول.'
                  : 'Publish in the Home feed so others can join.',
            ),
            onTap: () async {
              Navigator.of(sheetContext).pop();
              await _publishLivePost(
                context,
                shareText: shareText,
                ar: ar,
              );
            },
          ),
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.auto_stories_rounded),
            ),
            title: Text(ar ? 'مشاركة اللايف كستوري' : 'Share Live to story',
              style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(ar
              ? 'يظهر في الستوري مع زر دخول مباشر إلى اللايف.'
              : 'A story card lets friends join the Live.'),
            onTap: () async {
              Navigator.of(sheetContext).pop();
              await _publishLiveStory(context, liveId: liveId, ar: ar);
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

/// Publish a live invitation through the existing authenticated feed API.
Future<void> _publishLivePost(
  BuildContext context, {
  required String shareText,
  required bool ar,
}) async {
  try {
    await HomeFeedService().createPost(text: shareText);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ar
          ? 'تم نشر دعوة اللايف في الصفحة الرئيسية.'
          : 'Live invitation published to the Home feed.')),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))),
    );
  }
}

/// The route reached from an external HTTPS invitation. Existing live
/// viewer ownership/lifecycle stays with the normal Agora viewer widget.
class WorldVoiceLiveInvitationPage extends StatefulWidget {
  const WorldVoiceLiveInvitationPage({required this.liveId, super.key});
  final String liveId;

  @override
  State<WorldVoiceLiveInvitationPage> createState() =>
      _WorldVoiceLiveInvitationPageState();
}

class _WorldVoiceLiveInvitationPageState
    extends State<WorldVoiceLiveInvitationPage> {
  late final Future<DocumentSnapshot<Map<String, dynamic>>> _live =
      FirebaseFirestore.instance.collection('live_sessions')
          .doc(widget.liveId).get();

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _live,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data?.data();
        if (!LiveSessionService.isFresh(data)) {
          return Scaffold(
            appBar: AppBar(title: Text(ar ? 'دعوة لايف' : 'Live invitation')),
            body: Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.live_tv_outlined, size: 58),
                const SizedBox(height: 12),
                Text(ar ? 'هذا اللايف انتهى أو غير متاح الآن.'
                    : 'This Live has ended or is unavailable.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(ar ? 'العودة' : 'Back'),
                ),
              ],
            )),
          );
        }
        return _LiveViewerScreen(
          liveId: widget.liveId, data: data!, ar: ar,
        );
      },
    );
  }
}

Future<void> openSharedWorldVoiceLive(
  BuildContext context,
  String liveId, {
  required bool ar,
}) async {
  final id = liveId.trim();
  if (id.isEmpty || id.contains('/')) return;
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('live_sessions').doc(id).get();
    if (!context.mounted) return;
    final data = snapshot.data();
    if (!LiveSessionService.isFresh(data)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ar
            ? 'انتهى هذا البث المباشر.'
            : 'This Live has ended.')),
      );
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _LiveViewerScreen(liveId: id, data: data!, ar: ar),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ar
          ? 'تعذر فتح البث الآن.'
          : 'Could not open this Live.')),
    );
  }
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
    this.showComposer = true,
  });

  final LiveSessionService service;
  final String liveId;
  final bool ar;
  final bool showComposer;

  @override
  State<_LiveChatOverlay> createState() => _LiveChatOverlayState();
}

class _LiveChatOverlayState extends State<_LiveChatOverlay> {
  // One read per distinct sender while the chat is open, not per message.
  final Map<String, Future<Map<String, dynamic>>> _profiles = {};
  Future<Map<String, dynamic>> _profile(String uid) =>
      _profiles.putIfAbsent(uid, () async {
        if (uid.isEmpty) return const <String, dynamic>{};
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users').doc(uid).get();
          return doc.data() ?? const <String, dynamic>{};
        } catch (_) {
          return const <String, dynamic>{};
        }
      });

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
    return Column(
      children: [
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
                padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final type = (data['type'] ?? 'message').toString();
                  final name =
                      (data['senderName'] ?? 'WorldVoice').toString();
                  final photo =
                      (data['senderPhotoUrl'] ?? '').toString().trim();
                  final message = (data['text'] ?? '').toString();

                  if (type == 'join') {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0x66000000),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Text(
                              widget.ar
                                  ? '✨ $name انضم إلى اللايف'
                                  : '✨ $name joined the Live',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0x77444444),
                            foregroundImage:
                                photo.isEmpty ? null : NetworkImage(photo),
                            child: photo.isEmpty
                                ? const Icon(
                                    Icons.person_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 330),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x99000000),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFFFD77A),
                                      fontWeight: FontWeight.w900,
                                    )),
                                  FutureBuilder<Map<String, dynamic>>(
                                    future: _profile(
                                      (data['senderId'] ?? '').toString()),
                                    builder: (context, profileSnapshot) {
                                      final profile = profileSnapshot.data;
                                      if (profile == null) {
                                        return const SizedBox.shrink();
                                      }
                                      final locale =
                                        Localizations.localeOf(context).languageCode;
                                      final native =
                                          ProfileLanguageCatalog.localizedStoredName(
                                        (profile['nativeLanguageCode'] ??
                                         profile['nativeLanguage'])?.toString(),
                                        locale,
                                      );
                                      final preferred =
                                          profile['learningLanguageCodes'];
                                      final saved = preferred is List &&
                                              preferred.isNotEmpty
                                          ? preferred
                                          : (profile['learningLanguages'] as List?) ??
                                              const <dynamic>[];
                                      final learning = saved
                                          .map((v) => ProfileLanguageCatalog
                                              .localizedStoredName(v.toString(), locale))
                                          .where((v) => v.trim().isNotEmpty)
                                          .take(5).toList();
                                      if (native.isEmpty && learning.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 3),
                                        child: Text(
                                          [
                                            if (native.isNotEmpty)
                                              '${widget.ar ? 'الأم' : 'Native'}: $native',
                                            if (learning.isNotEmpty)
                                              '${widget.ar ? 'يتعلم' : 'Learning'}: ${learning.join(' • ')}',
                                          ].join('  |  '),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF9CE8C6),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  Text(message, maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white, height: 1.25,
                                    )),
                                ],
                              ),
                            ),
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
        if (widget.showComposer)
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
                    fillColor: const Color(0xA6141C19),
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
                  backgroundColor: const Color(0xE0188A63),
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
    );
  }}

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
                          onTap: () {
                            Navigator.of(sheetContext).push(
                              MaterialPageRoute<void>(
                                builder: (_) => PublicProfileScreen(
                                  userId: entry.key,
                                  languageCode: Localizations.localeOf(
                                    sheetContext,
                                  ).languageCode.toLowerCase(),
                                  onInviteToStage: () => service.inviteViewer(
                                    liveId: liveId,
                                    userId: entry.key,
                                  ),
                                  inviteToStageLabel: ar
                                      ? 'دعوة للكاميرا'
                                      : 'Invite to Live stage',
                                ),
                              ),
                            );
                          },
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
  const _LiveVideoGrid({required this.children, this.labels = const []});
  final List<Widget> children;
  final List<String> labels;

  String? _labelAt(int index) =>
      index < labels.length && labels[index].trim().isNotEmpty
          ? labels[index].trim() : null;

  Widget _tile(Widget child, int index) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF071B16),
        border: Border.all(
          color: Colors.white.withValues(alpha: .06),
          width: .8,
        ),
      ),
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            SizedBox.expand(child: child),
            if (_labelAt(index) != null)
              PositionedDirectional(
                start: 8, bottom: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xB8000000),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 5),
                    child: Text(_labelAt(index)!,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white,
                        fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x20000000),
                      Color(0x00000000),
                      Color(0x30000000),
                    ],
                    stops: [0, .62, 1],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = children.take(4).toList(growable: false);

    if (items.isEmpty) {
      return const ColoredBox(
        color: Color(0xFF071B16),
        child: Center(
          child: Icon(
            Icons.live_tv_rounded,
            color: Colors.white30,
            size: 64,
          ),
        ),
      );
    }

    if (items.length == 1) {
      return _tile(items.first, 0);
    }

    if (items.length == 2) {
      return Row(
        children: [
          Expanded(child: _tile(items[0], 0)),
          const SizedBox(width: 2),
          Expanded(child: _tile(items[1], 1)),
        ],
      );
    }

    if (items.length == 3) {
      return Row(
        textDirection: TextDirection.ltr,
        children: [
          Expanded(
            flex: 44,
            child: Column(
              children: [
                Expanded(child: _tile(items[1], 1)),
                const SizedBox(height: 2),
                Expanded(child: _tile(items[2], 2)),
              ],
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            flex: 56,
            child: _tile(items[0], 0),
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _tile(items[0], 0)),
              const SizedBox(width: 2),
              Expanded(child: _tile(items[1], 1)),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _tile(items[2], 2)),
              const SizedBox(width: 2),
              Expanded(child: _tile(items[3], 3)),
            ],
          ),
        ),
      ],
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