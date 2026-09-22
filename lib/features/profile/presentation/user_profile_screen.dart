import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';

import '../../../core/localization/locale_controller.dart';
import '../services/profile_social_service.dart';
import 'profile_connections_screen.dart';
import 'profile_identity_strip.dart';
import 'profile_setup_screen.dart';
import 'profile_visitors_screen.dart';
import 'settings_screen.dart';
import 'voice_bio_card.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({
    required this.localeController,
    super.key,
  });

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final code = localeController.locale?.languageCode ?? 'en';
    final rtl = const {'ar', 'ur', 'fa'}.contains(code);

    if (uid == null) {
      return const Scaffold(body: Center(child: Text('No signed-in user')));
    }

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            code == 'ar'
                ? 'بروفايلي'
                : code == 'es'
                    ? 'Mi perfil'
                    : 'My profile',
          ),
          actions: [
            IconButton(
              tooltip: AppStrings.of(code).profile('settings'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(
                      localeController: localeController,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream:
              FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.data() ?? const <String, dynamic>{};
            final name = (data['displayName'] as String?)?.trim();
            final username = (data['username'] as String?)?.trim();
            final bio = (data['bio'] as String?)?.trim();
            final photo = data['photoUrl'] as String?;
            final cover = data['coverUrl'] as String?;
            final country = data['country'] as String?;
            final gender = data['gender'] as String?;
            final nativeLanguage = data['nativeLanguage'] as String?;
            final birthRaw = data['birthDate'];
            final birthDate = birthRaw is Timestamp ? birthRaw.toDate() : null;
            final isVip = data['isVip'] == true;
            final voiceBioUrl = data['voiceBioUrl'] as String?;
            final learning = (data['learningLanguages'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                const <String>[];
            final hobbies = (data['interests'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                const <String>[];

            return ListView(
              padding: const EdgeInsets.only(bottom: 30),
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
                      Text(
                        '@' +
                            (username?.isNotEmpty == true ? username! : 'user'),
                      ),
                      ProfileIdentityStrip(
                        code: code,
                        country: country,
                        gender: gender,
                        birthDate: birthDate,
                        nativeLanguage: nativeLanguage,
                      ),
                      if (bio?.isNotEmpty == true) ...[
                        const SizedBox(height: 14),
                        Text(bio!),
                      ],
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _LiveCountStat(
                            stream: ProfileSocialService.followers(uid),
                            label: AppStrings.of(code).profile('followers'),
                            onTap: () => _openConnections(
                              context,
                              ProfileConnectionType.followers,
                            ),
                          ),
                          _LiveCountStat(
                            stream: ProfileSocialService.following(uid),
                            label: AppStrings.of(code).profile('following'),
                            onTap: () => _openConnections(
                              context,
                              ProfileConnectionType.following,
                            ),
                          ),
                          _StaticStat(
                            value: isVip ? 'VIP' : 'Free',
                            label: AppStrings.of(code).profile('plan'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProfileSetupScreen(
                                  localeController: localeController,
                                  editMode: true,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(
                            AppStrings.of(code).profile('editProfile'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _ProfileAction(
                              icon: Icons.handshake_outlined,
                              title: 'Partner',
                              onTap: () => _openConnections(
                                context,
                                ProfileConnectionType.partners,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ProfileAction(
                              icon: Icons.visibility_outlined,
                              title: AppStrings.of(code).profile('visitors'),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProfileVisitorsScreen(
                                      localeController: localeController,
                                      isVip: isVip,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      VoiceBioCard(
                        userId: uid,
                        code: code,
                        existingUrl: voiceBioUrl,
                      ),
                      _InfoCard(
                        icon: Icons.translate_rounded,
                        title:
                            AppStrings.of(code).profile('languages'),
                        value: learning.isEmpty
                            ? '—'
                            : AppStrings.of(code).profile('learning') +
                                ': ' +
                                learning.join(', '),
                      ),
                      _InfoCard(
                        icon: Icons.favorite_outline_rounded,
                        title:
                            AppStrings.of(code).profile('interests'),
                        value: hobbies.isEmpty ? '—' : hobbies.join(' • '),
                      ),
                      _InfoCard(
                        icon: Icons.work_outline_rounded,
                        title:
                            AppStrings.of(code).profile('profession'),
                        value: (data['profession'] ?? '—').toString(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _Wallet(
                              icon: Icons.diamond_outlined,
                              value: (data['diamonds'] ?? 0).toString(),
                              label:
                                  AppStrings.of(code).profile('diamonds'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _Wallet(
                              icon: Icons.monetization_on_outlined,
                              value: (data['coins'] ?? 0).toString(),
                              label: AppStrings.of(code).profile('coins'),
                            ),
                          ),
                        ],
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

  void _openConnections(
    BuildContext context,
    ProfileConnectionType type,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileConnectionsScreen(
          type: type,
          localeController: localeController,
        ),
      ),
    );
  }
}

class _LiveCountStat extends StatelessWidget {
  const _LiveCountStat({
    required this.stream,
    required this.label,
    required this.onTap,
  });

  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              children: [
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StaticStat extends StatelessWidget {
  const _StaticStat({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
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
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(value),
        ),
      );
}

class _Wallet extends StatelessWidget {
  const _Wallet({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon),
              const SizedBox(height: 7),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              Text(label),
            ],
          ),
        ),
      );
}

