import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';
import '../services/profile_social_service.dart';
import 'profile_connections_screen.dart';
import 'profile_settings_screen.dart';
import 'profile_visitors_screen.dart';
import 'voice_bio_screen.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({required this.localeController, super.key});

  final LocaleController localeController;

  String _t(String code, String en, String ar, String es) {
    if (code == 'ar') return ar;
    if (code == 'es') return es;
    return en;
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
          title: Text(_t(code, 'My profile', 'بروفايلي', 'Mi perfil')),
          actions: [
            IconButton(
              tooltip: _t(code, 'Settings', 'الإعدادات', 'Ajustes'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileSettingsScreen(
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
          stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
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
            final native = data['nativeLanguage'] as String?;
            final isVip = data['isVip'] == true;
            final voiceBio = data['voiceBioUrl'] as String?;
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
                          backgroundColor: Theme.of(context).colorScheme.surface,
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
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text('@' + (username?.isNotEmpty == true ? username! : 'user')),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _LiveCountStat(
                              stream: ProfileSocialService.followers(uid),
                              label: _t(code, 'Followers', 'المتابعون', 'Seguidores'),
                              onTap: () => _openConnections(
                                context,
                                ProfileConnectionType.followers,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _LiveCountStat(
                              stream: ProfileSocialService.following(uid),
                              label: _t(code, 'Following', 'أتابع', 'Siguiendo'),
                              onTap: () => _openConnections(
                                context,
                                ProfileConnectionType.following,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _StaticStat(
                              value: isVip ? 'VIP' : 'Free',
                              label: _t(code, 'Plan', 'الخطة', 'Plan'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _ProfileAction(
                              icon: Icons.handshake_outlined,
                              label: 'Partner',
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
                              label: _t(code, 'Visitors', 'Visitors', 'Visitors'),
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
                      const SizedBox(height: 14),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _t(code, 'About Me', 'About Me', 'About Me'),
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  IconButton.filledTonal(
                                    tooltip: _t(
                                      code,
                                      'Record voice About Me',
                                      'سجل About Me صوتي',
                                      'Grabar About Me de voz',
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => VoiceBioScreen(
                                            localeController: localeController,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: Icon(
                                      voiceBio == null || voiceBio.isEmpty
                                          ? Icons.mic_none_rounded
                                          : Icons.mic_rounded,
                                    ),
                                  ),
                                ],
                              ),
                              if (bio?.isNotEmpty == true) ...[
                                const SizedBox(height: 10),
                                Text(bio!),
                              ] else ...[
                                const SizedBox(height: 10),
                                Text(
                                  _t(
                                    code,
                                    'Add a short introduction about yourself.',
                                    'أضف نبذة قصيرة عن نفسك.',
                                    'Añade una breve presentación sobre ti.',
                                  ),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: .65),
                                      ),
                                ),
                              ],
                              if (voiceBio != null && voiceBio.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      _t(
                                        code,
                                        'Voice introduction active',
                                        'المقدمة الصوتية مفعّلة',
                                        'Presentación de voz activa',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _InfoCard(
                        icon: Icons.translate_rounded,
                        title: _t(code, 'Languages', 'اللغات', 'Idiomas'),
                        value: [
                          if (native?.isNotEmpty == true)
                            _t(code, 'Native', 'الأم', 'Nativo') + ': ' + native!,
                          if (learning.isNotEmpty)
                            _t(code, 'Learning', 'أتعلم', 'Aprendiendo') +
                                ': ' +
                                learning.join(', '),
                        ].join('  •  '),
                      ),
                      _InfoCard(
                        icon: Icons.favorite_outline_rounded,
                        title: _t(code, 'Interests', 'الهوايات', 'Intereses'),
                        value: hobbies.isEmpty ? '—' : hobbies.join(' • '),
                      ),
                      _InfoCard(
                        icon: Icons.work_outline_rounded,
                        title: _t(code, 'Profession', 'المهنة', 'Profesión'),
                        value: (data['profession'] ?? '—').toString(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _Wallet(
                              icon: Icons.diamond_outlined,
                              value: (data['diamonds'] ?? 0).toString(),
                              label: _t(code, 'Diamonds', 'ألماس', 'Diamantes'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _Wallet(
                              icon: Icons.monetization_on_outlined,
                              value: (data['coins'] ?? 0).toString(),
                              label: _t(code, 'Coins', 'عملات', 'Monedas'),
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
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StaticStat extends StatelessWidget {
  const _StaticStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
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
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(value.isEmpty ? '—' : value),
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
