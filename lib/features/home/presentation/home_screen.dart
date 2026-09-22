import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.localeController, super.key});
  final LocaleController localeController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final code = widget.localeController.locale?.languageCode ?? 'en';
    final rtl = const {'ar','ur','fa'}.contains(code);
    final labels = _labels(code);

    final pages = <Widget>[
      _HomeLanding(title: labels.home),
      _Placeholder(icon: Icons.graphic_eq_rounded, title: labels.live),
      _Placeholder(icon: Icons.school_rounded, title: labels.learn),
      _Placeholder(icon: Icons.chat_bubble_outline_rounded, title: labels.chat),
      _Placeholder(icon: Icons.explore_outlined, title: labels.discover),
    ];

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: SafeArea(child: IndexedStack(index: index, children: pages)),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (value) => setState(() => index = value),
          destinations: [
            NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: labels.home),
            NavigationDestination(icon: const Icon(Icons.graphic_eq_outlined), selectedIcon: const Icon(Icons.graphic_eq_rounded), label: labels.live),
            NavigationDestination(icon: const Icon(Icons.school_outlined), selectedIcon: const Icon(Icons.school_rounded), label: labels.learn),
            NavigationDestination(icon: const Icon(Icons.chat_bubble_outline_rounded), selectedIcon: const Icon(Icons.chat_bubble_rounded), label: labels.chat),
            NavigationDestination(icon: const Icon(Icons.explore_outlined), selectedIcon: const Icon(Icons.explore_rounded), label: labels.discover),
          ],
        ),
      ),
    );
  }
}

class _HomeLanding extends StatelessWidget {
  const _HomeLanding({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      children: [
        Row(
          children: [
            Expanded(child: Text('WorldVoice', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900))),
            IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
            const SizedBox(width: 8),
            IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.person_outline_rounded)),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(colors: [cs.primaryContainer, cs.tertiaryContainer]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                'WorldVoice',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

({String home, String live, String learn, String chat, String discover}) _labels(String code) {
  if (code == 'ar') {
    return (home: 'الرئيسية', live: 'اللايف', learn: 'تعلّم', chat: 'الدردشة', discover: 'اكتشف');
  }
  return (home: 'Home', live: 'Live', learn: 'Learn', chat: 'Chat', discover: 'Discover');
}
