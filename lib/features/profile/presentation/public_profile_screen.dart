import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_controller.dart';
import '../services/profile_social_service.dart';
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
  @override
  void initState() {
    super.initState();
    ProfileSocialService.recordVisit(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.localeController.locale?.languageCode ?? 'en';
    final rtl = const {'ar', 'ur', 'fa'}.contains(code);
    final strings = AppStrings.of(code);

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
            final name = (data['displayName'] as String?)?.trim();
            final country = data['country'] as String?;
            final gender = data['gender'] as String?;
            final nativeLanguage = (data['nativeLanguage'] as String?)?.trim();
            final birthRaw = data['birthDate'];
            final birthDate = birthRaw is Timestamp ? birthRaw.toDate() : null;
            final learning = (data['learningLanguages'] as List?)
                    ?.map((item) => item.toString())
                    .where((item) => item.trim().isNotEmpty)
                    .toList() ??
                const <String>[];
            final interests = (data['interests'] as List?)
                    ?.map((item) => item.toString())
                    .where((item) => item.trim().isNotEmpty)
                    .toList() ??
                const <String>[];
            final profession = (data['profession'] ?? '').toString().trim();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 54,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    backgroundImage: photo == null || photo.isEmpty
                        ? null
                        : NetworkImage(photo),
                    child: photo == null || photo.isEmpty
                        ? const Icon(Icons.person_rounded, size: 52)
                        : null,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  name?.isNotEmpty == true ? name! : 'WorldVoice',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Center(
                  child: ProfileIdentityStrip(
                    code: code,
                    country: country,
                    gender: gender,
                    birthDate: birthDate,
                  ),
                ),
                const SizedBox(height: 24),
                _SectionCard(
                  icon: Icons.translate_rounded,
                  title: strings.profile('languages'),
                  children: [
                    _LanguageRow(
                      label: strings.profile('native'),
                      value: nativeLanguage?.isNotEmpty == true
                          ? nativeLanguage!
                          : '—',
                    ),
                    const SizedBox(height: 10),
                    _LanguageRow(
                      label: strings.profile('learning'),
                      value: learning.isEmpty ? '—' : learning.join(', '),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  icon: Icons.favorite_outline_rounded,
                  title: strings.profile('interests'),
                  children: [
                    if (interests.isEmpty)
                      const Text('—')
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final interest in interests)
                            Chip(
                              label: Text(interest),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  icon: Icons.work_outline_rounded,
                  title: strings.profile('profession'),
                  children: [
                    Text(
                      profession.isEmpty ? '—' : profession,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: .35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: colors.primaryContainer,
                child: Icon(
                  icon,
                  size: 20,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label:',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(value)),
      ],
    );
  }
}
