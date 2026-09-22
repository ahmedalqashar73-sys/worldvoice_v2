import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({required this.localeController, super.key});
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final code = localeController.locale?.languageCode ?? 'en';
    final rtl = const {'ar','ur','fa'}.contains(code);
    final title = code == 'ar' ? 'اكتشف' : code == 'es' ? 'Descubrir' : 'Discover';

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 18),
            const _DiscoverCard(icon: Icons.travel_explore_rounded, title: 'Language partners', subtitle: 'Meet people by language and country'),
            const _DiscoverCard(icon: Icons.auto_stories_rounded, title: 'Stories', subtitle: 'See moments from the WorldVoice community'),
            const _DiscoverCard(icon: Icons.celebration_rounded, title: 'Events', subtitle: 'Join language events and public rooms'),
          ],
        ),
      ),
    );
  }
}

class _DiscoverCard extends StatelessWidget {
  const _DiscoverCard({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 27,
          backgroundColor: cs.primaryContainer,
          child: Icon(icon, color: cs.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      ),
    );
  }
}
