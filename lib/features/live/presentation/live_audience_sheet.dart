import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../profile/data/profile_language_catalog.dart';
import '../../profile/presentation/public_profile_screen.dart';
import '../../profile/services/profile_social_service.dart';
import '../services/live_session_service.dart';

/// Display-only projection of the actual WorldVoice user profile. The
/// viewer-presence document is not authoritative for a person's languages.
class LiveAudienceLanguages {
  const LiveAudienceLanguages({required this.native, required this.learning});

  final String native;
  final List<String> learning;

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
    backgroundColor: const Color(0xFF0D3025),
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
                    return ListTile(
                      key: ValueKey('live-viewer-${viewer.id}'),
                      leading: _AudienceAvatar(photoUrl: photo, radius: 22),
                      title: Text(
                        name.isEmpty ? 'WorldVoice user' : name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        ar ? 'اضغط لعرض بطاقة الشخص' : 'View participant card',
                        style: const TextStyle(color: Colors.white60),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFEAD08D),
                      ),
                      onTap: () => showLiveAudiencePersonCard(
                        context: sheetContext,
                        userId: viewer.id,
                        fallbackName: name,
                        fallbackPhotoUrl: photo,
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

/// Also used by the small viewer avatars and on-camera profile controls.
Future<void> showLiveAudiencePersonCard({
  required BuildContext context,
  required String userId,
  required bool ar,
  String fallbackName = '',
  String fallbackPhotoUrl = '',
  Route<dynamic>? liveRoute,
  Future<void> Function(String userId)? onInviteToStage,
}) {
  final origin = liveRoute ?? ModalRoute.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: const Color(0xFF0D3025),
    builder: (_) => _AudiencePersonCard(
      userId: userId,
      ar: ar,
      fallbackName: fallbackName,
      fallbackPhotoUrl: fallbackPhotoUrl,
      onInviteToStage: onInviteToStage,
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
  });

  final String userId;
  final bool ar;
  final String fallbackName;
  final String fallbackPhotoUrl;
  final Future<void> Function(String userId)? onInviteToStage;
  final void Function(BuildContext context) onReturnToLive;

  @override
  State<_AudiencePersonCard> createState() => _AudiencePersonCardState();
}

class _AudiencePersonCardState extends State<_AudiencePersonCard> {
  bool _following = false;
  bool _followBusy = false;
  bool _inviteBusy = false;

  bool get _isSelf => FirebaseAuth.instance.currentUser?.uid == widget.userId;

  @override
  void initState() {
    super.initState();
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
        color: const Color(0xFF14533E),
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
          colors: [Color(0xFFEAD08D), Color(0xFF14BA83)],
        ),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF14533E),
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
