import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';
import '../services/profile_social_service.dart';
import 'profile_identity_badges.dart';
import 'profile_identity_strip.dart';

class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({
    required this.userId,
    required this.localeController,
    super.key,
  });

  final String userId;
  final LocaleController localeController;

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  bool _following = false;
  bool _followBusy = false;

  @override
  void initState() {
    super.initState();
    _loadRelationship();
    ProfileSocialService.recordVisit(widget.userId);
  }

  Future<void> _loadRelationship() async {
    final value = await ProfileSocialService.isFollowing(widget.userId);
    if (mounted) setState(() => _following = value);
  }

  Future<void> _toggleFollow() async {
    if (_followBusy) return;
    setState(() => _followBusy = true);
    try {
      await ProfileSocialService.toggleFollow(widget.userId);
      if (mounted) setState(() => _following = !_following);
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.localeController.locale?.languageCode ?? 'en';
    final rtl = const {'ar', 'ur', 'fa'}.contains(code);

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.data() ?? const <String, dynamic>{};
            final photo = data['photoUrl'] as String?;
            final cover = data['coverUrl'] as String?;
            final name = (data['displayName'] as String?)?.trim();
            final username = (data['username'] as String?)?.trim();
            final bio = (data['bio'] as String?)?.trim();
            final country = data['country'] as String?;
            final gender = data['gender'] as String?;
            final nativeLanguage = data['nativeLanguage'] as String?;
            final birthRaw = data['birthDate'];
            final birthDate = birthRaw is Timestamp ? birthRaw.toDate() : null;
            final learning = (data['learningLanguages'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                const <String>[];
            final interests = (data['interests'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                const <String>[];

            return ListView(
              padding: const EdgeInsets.only(bottom: 28),
              children: [
                SizedBox(
                  height: 235,
                  child: Stack(
                    children: [
                      Container(
                        height: 170,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D6B4F), Color(0xFF5F47C8)],
                          ),
                          image: cover == null || cover.isEmpty
                              ? null
                              : DecorationImage(
                                  image: NetworkImage(cover),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      PositionedDirectional(
                        start: 22,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 64,
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          child: CircleAvatar(
                            radius: 59,
                            backgroundImage: photo == null || photo.isEmpty
                                ? null
                                : NetworkImage(photo),
                            child: photo == null || photo.isEmpty
                                ? const Icon(Icons.person_rounded, size: 58)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name?.isNotEmpty == true ? name! : 'WorldVoice',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text('@' + (username?.isNotEmpty == true ? username! : 'user')),
                      ProfileIdentityStrip(
                        code: code,
                        country: country,
                        gender: gender,
                        birthDate: birthDate,
                        nativeLanguage: nativeLanguage,
                      ),
                      if (bio?.isNotEmpty == true) ...[
                        const SizedBox(height: 12),
                        Text(bio!),
                      ],
                      const SizedBox(height: 16),
                      if (FirebaseAuth.instance.currentUser?.uid != widget.userId)
                        FilledButton.icon(
                          onPressed: _followBusy ? null : _toggleFollow,
                          icon: Icon(
                            _following
                                ? Icons.person_remove_alt_1_rounded
                                : Icons.person_add_alt_1_rounded,
                          ),
                          label: Text(
                            _following
                                ? _t(code, 'Following', 'متابَع', 'Siguiendo')
                                : _t(code, 'Follow', 'متابعة', 'Seguir'),
                          ),
                        ),
                      const SizedBox(height: 18),
                      _Info(
                        icon: Icons.translate_rounded,
                        title: _t(code, 'Languages', 'اللغات', 'Idiomas'),
                        value: learning.isEmpty
                            ? '—'
                            : _t(code, 'Learning', 'أتعلم', 'Aprende') +
                                ': ' +
                                learning.join(', '),
                      ),
                      _Info(
                        icon: Icons.favorite_outline_rounded,
                        title: _t(code, 'Interests', 'الهوايات', 'Intereses'),
                        value: interests.isEmpty ? '—' : interests.join(' • '),
                      ),
                      _Info(
                        icon: Icons.work_outline_rounded,
                        title: _t(code, 'Profession', 'المهنة', 'Profesión'),
                        value: (data['profession'] ?? '—').toString(),
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
  }
}

class _Info extends StatelessWidget {
  const _Info({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          contentPadding: const EdgeInsets.all(14),
          leading: Icon(icon),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(value),
        ),
      );
}

String _t(String code, String en, String ar, String es) {
  if (code == 'ar') return ar;
  if (code == 'es') return es;
  return en;
}
