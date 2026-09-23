import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';
import '../../learn/presentation/learn_screen.dart';
import '../../live/presentation/live_screen.dart';
import '../services/agora_voice_room_controller.dart';
import 'agora_voice_room_screen.dart';

class RoomsHubScreen extends StatefulWidget {
  const RoomsHubScreen({required this.localeController, super.key});

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

    final pages = <Widget>[
      _AiTeacherPage(labels: labels),
      LiveScreen(localeController: widget.localeController),
      LearnScreen(localeController: widget.localeController),
      _VoiceRoomsPage(labels: labels),
    ];

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      labels.hubTitle,
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
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                scrollDirection: Axis.horizontal,
                itemCount: labels.sections.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final selected = _section == index;
                  return ChoiceChip(
                    selected: selected,
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
              child: IndexedStack(
                index: _section,
                children: pages,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _sectionIcon(int index) {
    switch (index) {
      case 0:
        return Icons.auto_awesome_rounded;
      case 1:
        return Icons.live_tv_rounded;
      case 2:
        return Icons.school_rounded;
      default:
        return Icons.mic_rounded;
    }
  }
}

class _AiTeacherPage extends StatelessWidget {
  const _AiTeacherPage({required this.labels});

  final _RoomsHubLabels labels;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF5B43C7), Color(0xFF1C9A72)],
            ),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white24,
                child: Icon(
                  Icons.smart_toy_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labels.aiTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels.aiSubtitle,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _FeatureTile(
          icon: Icons.record_voice_over_rounded,
          title: labels.aiConversation,
          subtitle: labels.aiConversationBody,
        ),
        _FeatureTile(
          icon: Icons.translate_rounded,
          title: labels.aiTranslate,
          subtitle: labels.aiTranslateBody,
        ),
        _FeatureTile(
          icon: Icons.quiz_rounded,
          title: labels.aiQuiz,
          subtitle: labels.aiQuizBody,
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(labels.startAi),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            backgroundColor: colors.primary,
          ),
        ),
      ],
    );
  }
}

class _VoiceRoomsPage extends StatelessWidget {
  const _VoiceRoomsPage({required this.labels});

  final _RoomsHubLabels labels;

  void _openRoom(
    BuildContext context, {
    required String channelId,
    required String roomName,
    required AgoraRoomRole role,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AgoraVoiceRoomScreen(
          channelId: channelId,
          roomName: roomName,
          initialRole: role,
        ),
      ),
    );
  }

  Future<void> _createRoom(BuildContext context) async {
    final controller = TextEditingController();
    final roomName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(labels.createRoom),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          decoration: InputDecoration(
            hintText: labels.roomNameHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(labels.cancel),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: Text(labels.createRoom),
          ),
        ],
      ),
    );
    controller.dispose();

    if (roomName == null || !context.mounted) return;

    final slug = roomName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+
class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () {},
      ),
    );
  }
}

class _VoiceRoomCard extends StatelessWidget {
  const _VoiceRoomCard({
    required this.name,
    required this.flag,
    required this.subtitle,
    required this.listeners,
    required this.onTap,
  });

  final String name;
  final String flag;
  final String subtitle;
  final int listeners;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          child: Text(flag, style: const TextStyle(fontSize: 24)),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.headphones_rounded, size: 17),
            const SizedBox(width: 4),
            Text('$listeners'),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _RoomsHubLabels {
  _RoomsHubLabels(String code)
      : hubTitle = code == 'ar'
            ? 'Rooms'
            : code == 'es'
                ? 'Rooms'
                : 'Rooms',
        search = code == 'ar'
            ? 'بحث'
            : code == 'es'
                ? 'Buscar'
                : 'Search',
        sections = code == 'ar'
            ? const ['ChatGPT AI', 'Live', 'تعلّم', 'الغرف الصوتية']
            : code == 'es'
                ? const ['ChatGPT AI', 'Live', 'Aprender', 'Salas']
                : const ['ChatGPT AI', 'Live', 'Learn', 'Voice Rooms'],
        aiTitle = code == 'ar'
            ? 'ChatGPT AI'
            : code == 'es'
                ? 'ChatGPT AI'
                : 'ChatGPT AI',
        aiSubtitle = code == 'ar'
            ? 'معلمك الذكي للمحادثة والتعلّم.'
            : code == 'es'
                ? 'Tu profesor inteligente para hablar y aprender.'
                : 'Your AI teacher for speaking and learning.',
        aiConversation = code == 'ar'
            ? 'محادثة مع AI'
            : code == 'es'
                ? 'Conversación con AI'
                : 'AI conversation',
        aiConversationBody = code == 'ar'
            ? 'تدرّب على الكلام والنطق بشكل مباشر.'
            : code == 'es'
                ? 'Practica conversación y pronunciación.'
                : 'Practice speaking and pronunciation.',
        aiTranslate = code == 'ar'
            ? 'ترجمة وشرح'
            : code == 'es'
                ? 'Traducción y explicación'
                : 'Translate & explain',
        aiTranslateBody = code == 'ar'
            ? 'ترجمة الكلمات والجمل مع شرح مبسط.'
            : code == 'es'
                ? 'Traduce palabras y frases con explicaciones.'
                : 'Translate words and sentences with explanations.',
        aiQuiz = code == 'ar'
            ? 'اختبارات قصيرة'
            : code == 'es'
                ? 'Pruebas rápidas'
                : 'Quick quizzes',
        aiQuizBody = code == 'ar'
            ? 'اختبر مستواك وتابع تقدمك.'
            : code == 'es'
                ? 'Comprueba tu nivel y progreso.'
                : 'Check your level and progress.',
        startAi = code == 'ar'
            ? 'ابدأ مع ChatGPT AI'
            : code == 'es'
                ? 'Empezar con ChatGPT AI'
                : 'Start with ChatGPT AI',
        voiceRoomsTitle = code == 'ar'
            ? 'الغرف الصوتية'
            : code == 'es'
                ? 'Salas de voz'
                : 'Voice Rooms',
        createRoom = code == 'ar'
            ? 'إنشاء'
            : code == 'es'
                ? 'Crear'
                : 'Create',
        roomNameHint = code == 'ar'
            ? 'اسم الغرفة'
            : code == 'es'
                ? 'Nombre de la sala'
                : 'Room name',
        cancel = code == 'ar'
            ? 'إلغاء'
            : code == 'es'
                ? 'Cancelar'
                : 'Cancel',
        englishRoom = code == 'ar'
            ? 'English Lounge'
            : 'English Lounge',
        arabicRoom = code == 'ar'
            ? 'أصدقاء العربية'
            : code == 'es'
                ? 'Amigos de árabe'
                : 'Arabic Friends',
        worldRoom = code == 'ar'
            ? 'حديث العالم'
            : code == 'es'
                ? 'Charla mundial'
                : 'World Talk',
        publicRoom = code == 'ar'
            ? 'غرفة عامة • تحدث مباشرة'
            : code == 'es'
                ? 'Sala pública • Habla en directo'
                : 'Public room • Speak live',
        languageExchange = code == 'ar'
            ? 'تبادل لغات من جميع أنحاء العالم'
            : code == 'es'
                ? 'Intercambio de idiomas global'
                : 'Global language exchange';

  final String hubTitle;
  final String search;
  final List<String> sections;
  final String aiTitle;
  final String aiSubtitle;
  final String aiConversation;
  final String aiConversationBody;
  final String aiTranslate;
  final String aiTranslateBody;
  final String aiQuiz;
  final String aiQuizBody;
  final String startAi;
  final String voiceRoomsTitle;
  final String createRoom;
  final String roomNameHint;
  final String cancel;
  final String englishRoom;
  final String arabicRoom;
  final String worldRoom;
  final String publicRoom;
  final String languageExchange;
}
), '');
    final channelId = slug.isEmpty
        ? 'worldvoice_${DateTime.now().millisecondsSinceEpoch}'
        : 'wv_${slug}_${DateTime.now().millisecondsSinceEpoch}';

    _openRoom(
      context,
      channelId: channelId,
      roomName: roomName,
      role: AgoraRoomRole.speaker,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                labels.voiceRoomsTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            FilledButton.icon(
              onPressed: () => _createRoom(context),
              icon: const Icon(Icons.add_rounded),
              label: Text(labels.createRoom),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _VoiceRoomCard(
          name: labels.englishRoom,
          flag: '🇺🇸',
          subtitle: labels.publicRoom,
          listeners: 69,
          onTap: () => _openRoom(
            context,
            channelId: 'worldvoice_english_lounge',
            roomName: labels.englishRoom,
            role: AgoraRoomRole.listener,
          ),
        ),
        _VoiceRoomCard(
          name: labels.arabicRoom,
          flag: '🇸🇦',
          subtitle: labels.publicRoom,
          listeners: 262,
          onTap: () => _openRoom(
            context,
            channelId: 'worldvoice_arabic_friends',
            roomName: labels.arabicRoom,
            role: AgoraRoomRole.listener,
          ),
        ),
        _VoiceRoomCard(
          name: labels.worldRoom,
          flag: '🌍',
          subtitle: labels.languageExchange,
          listeners: 154,
          onTap: () => _openRoom(
            context,
            channelId: 'worldvoice_world_talk',
            roomName: labels.worldRoom,
            role: AgoraRoomRole.listener,
          ),
        ),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () {},
      ),
    );
  }
}

class _VoiceRoomCard extends StatelessWidget {
  const _VoiceRoomCard({
    required this.name,
    required this.flag,
    required this.subtitle,
    required this.listeners,
  });

  final String name;
  final String flag;
  final String subtitle;
  final int listeners;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          child: Text(flag, style: const TextStyle(fontSize: 24)),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.headphones_rounded, size: 17),
            const SizedBox(width: 4),
            Text('$listeners'),
          ],
        ),
        onTap: () {},
      ),
    );
  }
}

class _RoomsHubLabels {
  _RoomsHubLabels(String code)
      : hubTitle = code == 'ar'
            ? 'Rooms'
            : code == 'es'
                ? 'Rooms'
                : 'Rooms',
        search = code == 'ar'
            ? 'بحث'
            : code == 'es'
                ? 'Buscar'
                : 'Search',
        sections = code == 'ar'
            ? const ['ChatGPT AI', 'Live', 'تعلّم', 'الغرف الصوتية']
            : code == 'es'
                ? const ['ChatGPT AI', 'Live', 'Aprender', 'Salas']
                : const ['ChatGPT AI', 'Live', 'Learn', 'Voice Rooms'],
        aiTitle = code == 'ar'
            ? 'ChatGPT AI'
            : code == 'es'
                ? 'ChatGPT AI'
                : 'ChatGPT AI',
        aiSubtitle = code == 'ar'
            ? 'معلمك الذكي للمحادثة والتعلّم.'
            : code == 'es'
                ? 'Tu profesor inteligente para hablar y aprender.'
                : 'Your AI teacher for speaking and learning.',
        aiConversation = code == 'ar'
            ? 'محادثة مع AI'
            : code == 'es'
                ? 'Conversación con AI'
                : 'AI conversation',
        aiConversationBody = code == 'ar'
            ? 'تدرّب على الكلام والنطق بشكل مباشر.'
            : code == 'es'
                ? 'Practica conversación y pronunciación.'
                : 'Practice speaking and pronunciation.',
        aiTranslate = code == 'ar'
            ? 'ترجمة وشرح'
            : code == 'es'
                ? 'Traducción y explicación'
                : 'Translate & explain',
        aiTranslateBody = code == 'ar'
            ? 'ترجمة الكلمات والجمل مع شرح مبسط.'
            : code == 'es'
                ? 'Traduce palabras y frases con explicaciones.'
                : 'Translate words and sentences with explanations.',
        aiQuiz = code == 'ar'
            ? 'اختبارات قصيرة'
            : code == 'es'
                ? 'Pruebas rápidas'
                : 'Quick quizzes',
        aiQuizBody = code == 'ar'
            ? 'اختبر مستواك وتابع تقدمك.'
            : code == 'es'
                ? 'Comprueba tu nivel y progreso.'
                : 'Check your level and progress.',
        startAi = code == 'ar'
            ? 'ابدأ مع ChatGPT AI'
            : code == 'es'
                ? 'Empezar con ChatGPT AI'
                : 'Start with ChatGPT AI',
        voiceRoomsTitle = code == 'ar'
            ? 'الغرف الصوتية'
            : code == 'es'
                ? 'Salas de voz'
                : 'Voice Rooms',
        createRoom = code == 'ar'
            ? 'إنشاء'
            : code == 'es'
                ? 'Crear'
                : 'Create',
        englishRoom = code == 'ar'
            ? 'English Lounge'
            : 'English Lounge',
        arabicRoom = code == 'ar'
            ? 'أصدقاء العربية'
            : code == 'es'
                ? 'Amigos de árabe'
                : 'Arabic Friends',
        worldRoom = code == 'ar'
            ? 'حديث العالم'
            : code == 'es'
                ? 'Charla mundial'
                : 'World Talk',
        publicRoom = code == 'ar'
            ? 'غرفة عامة • تحدث مباشرة'
            : code == 'es'
                ? 'Sala pública • Habla en directo'
                : 'Public room • Speak live',
        languageExchange = code == 'ar'
            ? 'تبادل لغات من جميع أنحاء العالم'
            : code == 'es'
                ? 'Intercambio de idiomas global'
                : 'Global language exchange';

  final String hubTitle;
  final String search;
  final List<String> sections;
  final String aiTitle;
  final String aiSubtitle;
  final String aiConversation;
  final String aiConversationBody;
  final String aiTranslate;
  final String aiTranslateBody;
  final String aiQuiz;
  final String aiQuizBody;
  final String startAi;
  final String voiceRoomsTitle;
  final String createRoom;
  final String englishRoom;
  final String arabicRoom;
  final String worldRoom;
  final String publicRoom;
  final String languageExchange;
}
