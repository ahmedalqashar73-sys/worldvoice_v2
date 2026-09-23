import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';
import 'voice_rooms_list.dart';

class RoomsHubScreen extends StatefulWidget {
  const RoomsHubScreen({
    required this.localeController,
    super.key,
  });

  final LocaleController localeController;

  @override
  State<RoomsHubScreen> createState() => _RoomsHubScreenState();
}

class _RoomsHubScreenState extends State<RoomsHubScreen> {
  int _section = 0;

  @override
  Widget build(BuildContext context) {
    final code = widget.localeController.locale?.languageCode ?? 'en';
    final rtl = const {'ar', 'ur', 'fa'}.contains(code);
    final labels = _RoomsHubLabels(code);

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      labels.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () {},
                    tooltip: labels.search,
                    icon: const Icon(Icons.search_rounded),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 50,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                scrollDirection: Axis.horizontal,
                itemCount: labels.sections.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final selected = _section == index;
                  return ChoiceChip(
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _section = index),
                    avatar: Icon(
                      _sectionIcon(index),
                      size: 18,
                    ),
                    label: Text(labels.sections[index]),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _section == 0
                  ? VoiceRoomsList(
                      languageCode: code,
                      localeController: widget.localeController,
                    )
                  : const SizedBox.expand(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _sectionIcon(int index) {
    switch (index) {
      case 0:
        return Icons.mic_rounded;
      case 1:
        return Icons.live_tv_rounded;
      case 2:
        return Icons.auto_awesome_rounded;
      default:
        return Icons.school_rounded;
    }
  }
}

class _RoomsHubLabels {
  _RoomsHubLabels(String code)
      : title = 'Rooms',
        search = code == 'ar'
            ? 'بحث'
            : code == 'es'
                ? 'Buscar'
                : 'Search',
        sections = code == 'ar'
            ? const [
                'الغرف الصوتية',
                'البث المباشر',
                'أستاذ AI',
                'أتعلم',
              ]
            : code == 'es'
                ? const [
                    'Salas de voz',
                    'Live',
                    'Teacher AI',
                    'Aprender',
                  ]
                : const [
                    'Voice Rooms',
                    'Live',
                    'Teacher AI',
                    'Learn',
                  ];

  final String title;
  final String search;
  final List<String> sections;
}

