import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';

class LiveScreen extends StatelessWidget {
  const LiveScreen({required this.localeController, super.key});

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final code = localeController.locale?.languageCode ?? 'en';
    final rtl = const {'ar', 'ur', 'fa'}.contains(code);
    final labels = _LiveLabels(code);

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  labels.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.videocam_rounded),
                label: Text(labels.goLive),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                colors: [Color(0xFF7B3FF2), Color(0xFFE54A8D)],
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.live_tv_rounded,
                  size: 54,
                  color: Colors.white,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    labels.banner,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            labels.nowLive,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          const _LiveCard(
            name: 'Priscilia',
            flag: '🇮🇩',
            topic: 'Language exchange • English',
            viewers: 2621,
          ),
          const _LiveCard(
            name: 'Alice',
            flag: '🇯🇵',
            topic: 'English beginner practice',
            viewers: 1543,
          ),
          const _LiveCard(
            name: 'Global Live',
            flag: '🌍',
            topic: 'Meet people worldwide',
            viewers: 859,
          ),
        ],
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({
    required this.name,
    required this.flag,
    required this.topic,
    required this.viewers,
  });

  final String name;
  final String flag;
  final String topic;
  final int viewers;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: colors.secondaryContainer,
          child: Text(flag, style: const TextStyle(fontSize: 24)),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(topic),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.visibility_outlined, size: 17),
            const SizedBox(width: 4),
            Text('$viewers'),
          ],
        ),
        onTap: () {},
      ),
    );
  }
}

class _LiveLabels {
  _LiveLabels(String code)
      : title = code == 'ar'
            ? 'البث المباشر'
            : code == 'es'
                ? 'En vivo'
                : 'Live',
        goLive = code == 'ar'
            ? 'ابدأ بث'
            : code == 'es'
                ? 'Transmitir'
                : 'Go Live',
        banner = code == 'ar'
            ? 'شاهد وتفاعل مع البثوث المباشرة حول العالم.'
            : code == 'es'
                ? 'Mira y participa en directos de todo el mundo.'
                : 'Watch and join live broadcasts from around the world.',
        nowLive = code == 'ar'
            ? 'مباشر الآن'
            : code == 'es'
                ? 'En vivo ahora'
                : 'Live now';

  final String title;
  final String goLive;
  final String banner;
  final String nowLive;
}
