import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../profile/data/profile_language_catalog.dart';
import '../../profile/presentation/public_profile_screen.dart';
import '../../profile/presentation/world_bond_screen.dart';
import '../../rooms/presentation/room_world_bond_section.dart';
import '../../profile/services/profile_social_service.dart';
import '../services/live_session_service.dart';

/// Display-only projection of the actual WorldVoice user profile. The
/// viewer-presence document is not authoritative for a person's languages.
class LiveAudienceLanguages {
  const LiveAudienceLanguages({required this.native, required this.learning});

  final String native;
  final List<String> learning;

  /// Compact language metadata loaded from the real user profile.
  String get audienceLabel {
    if (learning.isEmpty) return native;
    if (native.isEmpty) return learning.join(' • ');
    final more = learning.length > 1 ? ' +${learning.length - 1}' : '';
    return '${learning.first} ⇄ $native$more';
  }

  factory LiveAudienceLanguages.fromProfile(
    Map<String, dynamic> profile,
    String uiLanguage,
  ) {
    final native = ProfileLanguageCatalog.localizedStoredName(
      (profile['nativeLanguageCode'] ?? profile['nativeLanguage'])?.toString(),
      uiLanguage,
    );
    final saved = (profile['learningLanguageCodes'] as List?)?.isNotEmpty == true
        ? profile['learningLanguageCodes'] as List
        : (profile['learningLanguages'] as List?) ?? const [];
    final seen = <String>{};
    final learning = <String>[];
    for (final raw in saved) {
      final name = ProfileLanguageCatalog.localizedStoredName(
        raw.toString(),
        uiLanguage,
      );
      if (name.isNotEmpty && seen.add(name)) learning.add(name);
    }
    return LiveAudienceLanguages(
      native: native,
      learning: List<String>.unmodifiable(learning),
    );
  }
}

/// Audience sheet is placed over the existing Live route. It never leaves
/// Agora, changes a role, or navigates away from the running broadcast.
Future<void> showLiveAudienceSheet({
  required BuildContext context,
  required LiveSessionService service,
  required String liveId,
  required bool ar,
  Future<void> Function(String userId)? onInviteToStage,
}) {
  final liveRoute = ModalRoute.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: const Color(0xFF16121F),
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: .76,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 12, 12),
            child: Row(
              children: [
                const Icon(Icons.groups_rounded, color: Color(0xFFEAD08D)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ar ? 'مشاهدو اللايف' : 'Live viewers',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: ar ? 'العودة للايف' : 'Return to Live',
                  onPressed: () => Navigator.pop(sheetContext),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: service.watchViewers(liveId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      ar ? 'تعذر تحميل المشاهدين.' : 'Unable to load viewers.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final viewers = snapshot.data!.docs.toList()
                  ..sort((a, b) {
                    final aAt = a.data()['joinedAt'];
                    final bAt = b.data()['joinedAt'];
                    if (aAt is Timestamp && bAt is Timestamp) {
                      return bAt.compareTo(aAt);
                    }
                    return a.id.compareTo(b.id);
                  });
                if (viewers.isEmpty) {
                  return Center(
                    child: Text(
                      ar ? 'لا يوجد مشاهدون حاليًا.' : 'No viewers yet.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: viewers.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: Colors.white12),
                  itemBuilder: (context, index) {
                    final viewer = viewers[index];
                    final data = viewer.data();
                    final name = (data['displayName'] ?? '').toString().trim();
                    final photo = (data['photoUrl'] ?? '').toString().trim();
                    return _LiveAudienceViewerRow(
                      key: ValueKey('live-viewer-${viewer.id}'),
                      userId: viewer.id,
                      fallbackName: name,
                      fallbackPhotoUrl: photo,
                      ar: ar,
                      onTap: (displayName, photoUrl) =>
                          showLiveAudiencePersonCard(
                        context: sheetContext,
                        userId: viewer.id,
                        fallbackName: displayName,
                        fallbackPhotoUrl: photoUrl,
                        ar: ar,
                        liveRoute: liveRoute,
                        onInviteToStage: onInviteToStage,
                      ),
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

/// Each visible audience row reads its real profile once, independent
/// of the viewer counter. The fallback keeps the list usable offline.
class _LiveAudienceViewerRow extends StatefulWidget {
  const _LiveAudienceViewerRow({
    required this.userId,
    required this.fallbackName,
    required this.fallbackPhotoUrl,
    required this.ar,
    required this.onTap,
    super.key,
  });

  final String userId;
  final String fallbackName;
  final String fallbackPhotoUrl;
  final bool ar;
  final void Function(String name, String photoUrl) onTap;

  @override
  State<_LiveAudienceViewerRow> createState() =>
      _LiveAudienceViewerRowState();
}

class _LiveAudienceViewerRowState extends State<_LiveAudienceViewerRow> {
  late Future<Map<String, dynamic>> _profile;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void didUpdateWidget(covariant _LiveAudienceViewerRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) _fetchProfile();
  }

  void _fetchProfile() {
    _profile = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get()
        .then((snap) => snap.data() ?? const <String, dynamic>{})
        .catchError((Object _) => <String, dynamic>{});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _profile,
      builder: (context, snapshot) {
        final profile = snapshot.data ?? const <String, dynamic>{};
        final name = (profile['displayName'] ?? profile['name'] ??
            widget.fallbackName).toString().trim();
        final photo = (profile['photoUrl'] ?? profile['avatarUrl'] ??
            widget.fallbackPhotoUrl).toString().trim();
        final languages = LiveAudienceLanguages.fromProfile(
          profile, widget.ar ? 'ar' : 'en',
        );
        final summary = languages.audienceLabel;
        return ListTile(
          leading: _AudienceAvatar(photoUrl: photo, radius: 22),
          title: Text(
            name.isEmpty ? 'WorldVoice user' : name,
            style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            summary.isEmpty
                ? (widget.ar ? 'عرض بطاقة الشخص' : 'View participant card')
                : summary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: summary.isEmpty
                  ? Colors.white54 : const Color(0xFFD5C3F3),
              fontSize: 12,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded, color: Color(0xFFD3B0FB)),
          onTap: () => widget.onTap(name, photo),
        );
      },
    );
  }
}

/// Also used by the small viewer avatars and on-camera profile controls.
Future<void> showLiveAudiencePersonCard({
  required BuildContext context,
  required String userId,
  required bool ar,
  String fallbackName = '',
  String fallbackPhotoUrl = '',
  Route<dynamic>? liveRoute,
  Future<void> Function(String userId)? onInviteToStage,
  Future<void> Function(bool blocked)? onSetStageMicrophoneBlocked,
  Future<void> Function(bool blocked)? onSetStageCameraBlocked,
  Future<void> Function()? onLowerFromStage,
  bool stageMicrophoneBlocked = false,
  bool stageCameraBlocked = false,
}) {
  final origin = liveRoute ?? ModalRoute.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: const Color(0xFF16121F),
    builder: (_) => _AudiencePersonCard(
      userId: userId,
      ar: ar,
      fallbackName: fallbackName,
      fallbackPhotoUrl: fallbackPhotoUrl,
      onInviteToStage: onInviteToStage,
      onSetStageMicrophoneBlocked: onSetStageMicrophoneBlocked,
      onSetStageCameraBlocked: onSetStageCameraBlocked,
      onLowerFromStage: onLowerFromStage,
      stageMicrophoneBlocked: stageMicrophoneBlocked,
      stageCameraBlocked: stageCameraBlocked,
      onReturnToLive: (cardContext) {
        final navigator = Navigator.of(cardContext);
        if (origin != null && origin.isActive) {
          navigator.popUntil((route) => identical(route, origin));
        } else {
          navigator.pop();
        }
      },
    ),
  );
}

class _AudiencePersonCard extends StatefulWidget {
  const _AudiencePersonCard({
    required this.userId,
    required this.ar,
    required this.fallbackName,
    required this.fallbackPhotoUrl,
    required this.onReturnToLive,
    this.onInviteToStage,
    this.onSetStageMicrophoneBlocked,
    this.onSetStageCameraBlocked,
    this.onLowerFromStage,
    this.stageMicrophoneBlocked = false,
    this.stageCameraBlocked = false,
  });

  final String userId;
  final bool ar;
  final String fallbackName;
  final String fallbackPhotoUrl;
  final Future<void> Function(String userId)? onInviteToStage;
  final Future<void> Function(bool blocked)? onSetStageMicrophoneBlocked;
  final Future<void> Function(bool blocked)? onSetStageCameraBlocked;
  final Future<void> Function()? onLowerFromStage;
  final bool stageMicrophoneBlocked;
  final bool stageCameraBlocked;
  final void Function(BuildContext context) onReturnToLive;

  @override
  State<_AudiencePersonCard> createState() => _AudiencePersonCardState();
}

class _AudiencePersonCardState extends State<_AudiencePersonCard> {
  bool _following = false;
  bool _followBusy = false;
  bool _inviteBusy = false;
  bool _stageActionBusy = false;
  late bool _micBlocked;
  late bool _cameraBlocked;

  bool get _isSelf => FirebaseAuth.instance.currentUser?.uid == widget.userId;

  @override
  void initState() {
    super.initState();
    _micBlocked = widget.stageMicrophoneBlocked;
    _cameraBlocked = widget.stageCameraBlocked;
    _loadFollow();
  }

  Future<void> _loadFollow() async {
    if (_isSelf) return;
    try {
      final following = await ProfileSocialService.isFollowing(widget.userId);
      if (mounted) setState(() => _following = following);
    } catch (_) {
      // Profile metadata must not interfere with Agora playback.
    }
  }

  Future<void> _toggleFollow() async {
    if (_isSelf || _followBusy) return;
    setState(() => _followBusy = true);
    try {
      await ProfileSocialService.toggleFollow(widget.userId);
      await _loadFollow();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  Future<void> _invite() async {
    final invite = widget.onInviteToStage;
    if (invite == null || _isSelf || _inviteBusy) return;
    setState(() => _inviteBusy = true);
    try {
      await invite(widget.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.ar
            ? 'تم إرسال دعوة للكاميرا.' : 'Camera invitation sent.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _inviteBusy = false);
    }
  }

  Future<void> _stageAction(
    Future<void> Function()? action, {
    required String success,
  }) async {
    if (_stageActionBusy || action == null) return;
    setState(() => _stageActionBusy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _stageActionBusy = false);
    }
  }

  Future<void> _changeStageMicrophone() async {
    final callback = widget.onSetStageMicrophoneBlocked;
    if (callback == null) return;
    final next = !_micBlocked;
    await _stageAction(
      () async {
        await callback(next);
        if (mounted) setState(() => _micBlocked = next);
      },
      success: widget.ar
          ? (next ? 'تم كتم صوت الضيف.' : 'يمكن للضيف تشغيل المايك بنفسه.')
          : (next ? 'Guest microphone muted.' : 'Guest may unmute.'),
    );
  }

  Future<void> _changeStageCamera() async {
    final callback = widget.onSetStageCameraBlocked;
    if (callback == null) return;
    final next = !_cameraBlocked;
    await _stageAction(
      () async {
        await callback(next);
        if (mounted) setState(() => _cameraBlocked = next);
      },
      success: widget.ar
          ? (next ? 'تم إيقاف كاميرا الضيف.' : 'الضيف وحده يستطيع تشغيل كاميرته.')
          : (next ? 'Guest camera stopped.' : 'The guest may turn their camera on.'),
    );
  }

  Future<void> _lowerStageGuest() async {
    final callback = widget.onLowerFromStage;
    if (callback == null || _stageActionBusy) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(widget.ar ? 'إنزال من المسرح؟' : 'Remove from stage?'),
        content: Text(widget.ar
            ? 'سيبقى الشخص مشاهدًا بعد إنزاله من المسرح.'
            : 'This guest will remain in the audience.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(widget.ar ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(widget.ar ? 'إنزال' : 'Remove'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    await _stageAction(callback, success: widget.ar
        ? 'تم إنزال الضيف إلى الجمهور.' : 'Guest returned to audience.');
  }

  Future<void> _openFullProfile() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PublicProfileScreen(
          userId: widget.userId,
          languageCode: widget.ar ? 'ar' : 'en',
          onInviteToStage: widget.onInviteToStage == null || _isSelf
              ? null
              : () => widget.onInviteToStage!(widget.userId),
          inviteToStageLabel: widget.ar ? 'دعوة للكاميرا' : 'Invite to stage',
        ),
      ),
    );
    if (mounted) await _loadFollow();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users').doc(widget.userId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        final name = (data['displayName'] ?? data['name'] ??
                widget.fallbackName).toString().trim();
        final photo = (data['photoUrl'] ?? data['avatarUrl'] ??
                widget.fallbackPhotoUrl).toString().trim();
        final username = (data['username'] ?? '').toString().trim();
        final country = (data['country'] ?? '').toString().trim();
        final bio = (data['bio'] ?? '').toString().trim();
        final languages = LiveAudienceLanguages.fromProfile(
          data, widget.ar ? 'ar' : 'en',
        );

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AudienceAvatar(photoUrl: photo, radius: 38),
                const SizedBox(height: 9),
                Text(
                  name.isEmpty ? 'WorldVoice user' : name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (username.isNotEmpty)
                  Text('@$username',
                    style: const TextStyle(color: Color(0xFFEAD08D))),
                if (country.isNotEmpty)
                  Text(country,
                    style: const TextStyle(color: Colors.white70)),
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(bio, maxLines: 3,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70)),
                ],
                const SizedBox(height: 16),
                _languageLine(
                  ProfileLanguageCatalog.localizedFieldTitle(
                    'native', widget.ar ? 'ar' : 'en',
                  ),
                  languages.native.isEmpty ? '—' : languages.native,
                ),
                const SizedBox(height: 8),
                _languageLine(
                  ProfileLanguageCatalog.localizedFieldTitle(
                    'learning', widget.ar ? 'ar' : 'en',
                  ),
                  languages.learning.isEmpty
                      ? '—' : languages.learning.join(' • '),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    if (!_isSelf)
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _followBusy ? null : _toggleFollow,
                          icon: Icon(_following
                              ? Icons.person_remove_alt_1_rounded
                              : Icons.person_add_alt_1_rounded),
                          label: Text(_following
                              ? (widget.ar ? 'إلغاء المتابعة' : 'Unfollow')
                              : (widget.ar ? 'متابعة' : 'Follow')),
                        ),
                      ),
                    if (!_isSelf) const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openFullProfile,
                        icon: const Icon(Icons.account_circle_outlined),
                        label: Text(widget.ar ? 'الملف الشخصي' : 'Profile'),
                      ),
                    ),
                  ],
                ),
                if (!_isSelf &&
                    (widget.onSetStageMicrophoneBlocked != null ||
                     widget.onSetStageCameraBlocked != null ||
                     widget.onLowerFromStage != null)) ...[
                  const SizedBox(height: 10),
                  Container(
                    key: const ValueKey('live-profile-stage-moderation'),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF282140),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            widget.ar ? 'إدارة المشارك في اللايف'
                                : 'Manage Live participant',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (widget.onSetStageMicrophoneBlocked != null)
                          ListTile(
                            key: const ValueKey('live-profile-mute-guest'),
                            dense: true,
                            leading: Icon(
                              _micBlocked ? Icons.mic_rounded
                                  : Icons.mic_off_rounded,
                              color: Colors.white,
                            ),
                            title: Text(_micBlocked
                                ? (widget.ar ? 'السماح بالمايك' : 'Allow microphone')
                                : (widget.ar ? 'كتم صوت الضيف' : 'Mute guest'),
                                style: const TextStyle(color: Colors.white)),
                            onTap: _stageActionBusy ? null : _changeStageMicrophone,
                          ),
                        if (widget.onSetStageCameraBlocked != null)
                          ListTile(
                            key: const ValueKey('live-profile-stop-camera'),
                            dense: true,
                            leading: Icon(
                              _cameraBlocked ? Icons.videocam_rounded
                                  : Icons.videocam_off_rounded,
                              color: Colors.white,
                            ),
                            title: Text(_cameraBlocked
                                ? (widget.ar ? 'السماح بالكاميرا' : 'Allow camera')
                                : (widget.ar ? 'إيقاف كاميرا الضيف' : 'Stop guest camera'),
                                style: const TextStyle(color: Colors.white)),
                            subtitle: Text(widget.ar
                                ? 'لا يمكنك تشغيل كاميرا الضيف بدلًا عنه.'
                                : 'You cannot start the guest camera.',
                                style: const TextStyle(color: Colors.white60)),
                            onTap: _stageActionBusy ? null : _changeStageCamera,
                          ),
                        if (widget.onLowerFromStage != null)
                          ListTile(
                            key: const ValueKey('live-profile-lower-guest'),
                            dense: true,
                            leading: const Icon(Icons.arrow_downward_rounded,
                                color: Color(0xFFFFC99D)),
                            title: Text(widget.ar ? 'إنزال إلى الجمهور'
                                : 'Lower to audience',
                                style: const TextStyle(color: Colors.white)),
                            onTap: _stageActionBusy ? null : _lowerStageGuest,
                          ),
                      ],
                    ),
                  ),
                ],
                if (!_isSelf && widget.onInviteToStage != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _inviteBusy ? null : _invite,
                      icon: const Icon(Icons.videocam_rounded),
                      label: Text(widget.ar
                          ? 'دعوة للصعود بالكاميرا'
                          : 'Invite to camera'),
                    ),
                  ),
                ],
                // Reuse the existing, fully connected room relationship
                // component. Live does not define any duplicate WorldBond
                // cards, gift payments, or relationship endpoints.
                const SizedBox(height: 14),
                RoomWorldBondSection(
                  key: const ValueKey('live-room-worldbond-link'),
                  userId: widget.userId,
                  isSelf: _isSelf,
                  isArabic: widget.ar,
                  onOpen: (kind) => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => WorldBondScreen(
                        peerId: _isSelf ? null : widget.userId,
                        peerName: name,
                        focusType: kind,
                      ),
                    ),
                  ),
                ),
                if (snapshot.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.ar
                          ? 'تعذر تحميل تفاصيل الحساب.'
                          : 'Profile details unavailable.',
                      style: const TextStyle(color: Colors.orangeAccent),
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => widget.onReturnToLive(context),
                    icon: const Icon(Icons.live_tv_rounded),
                    label: Text(widget.ar ? 'العودة للايف' : 'Return to Live'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _languageLine(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF292238),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$title: $value',
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }
}

class _AudienceAvatar extends StatelessWidget {
  const _AudienceAvatar({required this.photoUrl, required this.radius});

  final String photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(photoUrl);
    final isValid = uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
    final fallback = Icon(Icons.person_rounded,
        color: Colors.white, size: radius * .9);
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFEAD08D), Color(0xFF9065EE)],
        ),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF28223B),
        child: isValid
            ? ClipOval(child: Image.network(
                photoUrl,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ))
            : fallback,
      ),
    );
  }
}
