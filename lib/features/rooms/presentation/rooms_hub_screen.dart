import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';
import '../services/agora_voice_room_controller.dart';
import 'agora_voice_room_screen.dart';

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
                  ? _VoiceRoomTestPanel(
                      channelId: 'worldvoice_english_lounge',
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


class _VoiceRoomTestPanel extends StatelessWidget {
  const _VoiceRoomTestPanel({required this.channelId});

  final String channelId;

  void _open(
    BuildContext context, {
    required AgoraRoomRole role,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AgoraVoiceRoomScreen(
          channelId: channelId,
          roomName: 'WorldVoice Test Room',
          initialRole: role,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'WorldVoice Test Room',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  channelId,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => _open(
                    context,
                    role: AgoraRoomRole.speaker,
                  ),
                  icon: const Icon(Icons.admin_panel_settings_rounded),
                  label: const Text('Enter as Host'),
                ),
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  onPressed: () => _open(
                    context,
                    role: AgoraRoomRole.listener,
                  ),
                  icon: const Icon(Icons.headphones_rounded),
                  label: const Text('Enter as Listener'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
