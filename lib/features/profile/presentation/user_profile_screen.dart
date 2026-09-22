import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({required this.localeController, super.key});
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final code = localeController.locale?.languageCode ?? 'en';
    final rtl = const {'ar','ur','fa'}.contains(code);

    if (uid == null) {
      return const Scaffold(body: Center(child: Text('No signed-in user')));
    }

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(code == 'ar' ? 'بروفايلي' : code == 'es' ? 'Mi perfil' : 'My profile'),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined)),
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
            final learning = (data['learningLanguages'] as List?)
                    ?.map((e) => '$e')
                    .toList() ??
                const <String>[];
            final hobbies = (data['interests'] as List?)
                    ?.map((e) => '$e')
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
                      Text('@${username?.isNotEmpty == true ? username : 'user'}'),
                      if (bio?.isNotEmpty == true) ...[
                        const SizedBox(height: 14),
                        Text(bio!),
                      ],
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _Stat(
                            value: '${data['followersCount'] ?? 0}',
                            label: code == 'ar' ? 'متابعون' : 'Followers',
                          ),
                          const SizedBox(width: 24),
                          _Stat(
                            value: '${data['followingCount'] ?? 0}',
                            label: code == 'ar' ? 'يتابع' : 'Following',
                          ),
                          const SizedBox(width: 24),
                          _Stat(
                            value: data['isVip'] == true ? 'VIP' : 'Free',
                            label: code == 'ar' ? 'الحساب' : 'Plan',
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _InfoCard(
                        icon: Icons.translate_rounded,
                        title: code == 'ar' ? 'اللغات' : 'Languages',
                        value: [
                          if (native?.isNotEmpty == true)
                            '${code == 'ar' ? 'الأم' : 'Native'}: $native',
                          if (learning.isNotEmpty)
                            '${code == 'ar' ? 'أتعلم' : 'Learning'}: ${learning.join(', ')}',
                        ].join('  •  '),
                      ),
                      _InfoCard(
                        icon: Icons.favorite_outline_rounded,
                        title: code == 'ar' ? 'الهوايات' : 'Interests',
                        value: hobbies.isEmpty ? '—' : hobbies.join(' • '),
                      ),
                      _InfoCard(
                        icon: Icons.work_outline_rounded,
                        title: code == 'ar' ? 'المهنة' : 'Profession',
                        value: '${data['profession'] ?? '—'}',
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _Wallet(
                              icon: Icons.diamond_outlined,
                              value: '${data['diamonds'] ?? 0}',
                              label: code == 'ar' ? 'ألماس' : 'Diamonds',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _Wallet(
                              icon: Icons.monetization_on_outlined,
                              value: '${data['coins'] ?? 0}',
                              label: code == 'ar' ? 'عملات' : 'Coins',
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

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
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
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              Text(label),
            ],
          ),
        ),
      );
}
