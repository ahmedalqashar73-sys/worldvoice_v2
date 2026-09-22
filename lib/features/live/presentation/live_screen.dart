import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({
    required this.localeController,
    required this.onOpenLearn,
    super.key,
  });

  final LocaleController localeController;
  final VoidCallback onOpenLearn;

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  int section = 0;
  int language = 0;

  @override
  Widget build(BuildContext context) {
    final code = widget.localeController.locale?.languageCode ?? 'en';
    final rtl = const {'ar','ur','fa'}.contains(code);
    final t = _LiveLabels(code);

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB000), Color(0xFFFFD45B)],
                    ),
                  ),
                  child: const Text(
                    'VIP',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                ),
                const Spacer(),
                Text(
                  t.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const Spacer(),
                IconButton.filledTonal(
                  onPressed: () {},
                  icon: const Icon(Icons.videocam_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Segmented(
              labels: t.sections,
              selected: section,
              onChanged: (i) {
                if (i == 3) {
                  widget.onOpenLearn();
                } else {
                  setState(() => section = i);
                }
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: t.languages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ChoiceChip(
                  selected: language == i,
                  label: Text(t.languages[i]),
                  onSelected: (_) => setState(() => language = i),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 142,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: LinearGradient(
                  colors: section == 1
                      ? const [Color(0xFF3F2C79), Color(0xFF6F4DE8)]
                      : const [Color(0xFF1C7C69), Color(0xFF22B07D)],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      section == 1 ? t.voiceBanner : section == 2 ? t.aiBanner : t.liveBanner,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Icon(
                    section == 1
                        ? Icons.mic_rounded
                        : section == 2
                            ? Icons.smart_toy_rounded
                            : Icons.live_tv_rounded,
                    size: 62,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (section == 2)
              _AiPanel(labels: t)
            else
              GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .78,
                children: section == 1
                    ? const [
                        _RoomCard(name: 'English Lounge', flag: '🇺🇸', title: 'Speak freely • Beginner', viewers: '69', voice: true),
                        _RoomCard(name: 'Arabic Friends', flag: '🇸🇦', title: 'تعال نتكلم عربي', viewers: '262', voice: true),
                        _RoomCard(name: 'World Talk', flag: '🌍', title: 'Meet people worldwide', viewers: '154', voice: true),
                        _RoomCard(name: 'Night Chat', flag: '🇯🇵', title: 'English & Japanese', viewers: '98', voice: true),
                      ]
                    : const [
                        _RoomCard(name: 'Priscilia', flag: '🇮🇩', title: 'no more stage — just talk', viewers: '2621'),
                        _RoomCard(name: 'Alice', flag: '🇯🇵', title: 'English beginner', viewers: '1543'),
                        _RoomCard(name: 'Wake Up', flag: '🇨🇳', title: 'play • sing • dance', viewers: '859'),
                        _RoomCard(name: 'Global Live', flag: '🌍', title: 'Language exchange live', viewers: '421'),
                      ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        labels.length,
        (i) => Expanded(
          child: Padding(
            padding: EdgeInsetsDirectional.only(end: i == labels.length - 1 ? 0 : 6),
            child: FilledButton.tonal(
              onPressed: () => onChanged(i),
              style: FilledButton.styleFrom(
                backgroundColor: selected == i
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 13),
              ),
              child: Text(
                labels[i],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: selected == i ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.name,
    required this.flag,
    required this.title,
    required this.viewers,
    this.voice = false,
  });

  final String name;
  final String flag;
  final String title;
  final String viewers;
  final bool voice;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: voice
              ? [const Color(0xFF2E1D68), const Color(0xFF4936A0)]
              : [const Color(0xFF620049), const Color(0xFF8F0062)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(voice ? Icons.graphic_eq_rounded : Icons.live_tv_rounded, color: Colors.white),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('EN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: CircleAvatar(
              radius: 34,
              backgroundColor: cs.surface.withValues(alpha: .92),
              child: Text(flag, style: const TextStyle(fontSize: 30)),
            ),
          ),
          const Spacer(),
          Text(
            name,
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.visibility_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 5),
              Text(viewers, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiPanel extends StatelessWidget {
  const _AiPanel({required this.labels});
  final _LiveLabels labels;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AiAction(icon: Icons.record_voice_over_rounded, title: labels.aiConversation, subtitle: labels.aiConversationBody),
        _AiAction(icon: Icons.translate_rounded, title: labels.aiTranslate, subtitle: labels.aiTranslateBody),
        _AiAction(icon: Icons.quiz_rounded, title: labels.aiQuiz, subtitle: labels.aiQuizBody),
      ],
    );
  }
}

class _AiAction extends StatelessWidget {
  const _AiAction({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          radius: 26,
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

class _LiveLabels {
  _LiveLabels(String code)
      : title = code == 'ar' ? 'اللايف' : code == 'es' ? 'En vivo' : 'Live',
        sections = code == 'ar'
            ? const ['بث مباشر','غرف صوتية','AI','تعلّم']
            : code == 'es'
                ? const ['Directo','Salas','AI','Aprender']
                : const ['Live','Voice','AI','Learn'],
        languages = code == 'ar'
            ? const ['الكل','الإنجليزية','العربية','التركية']
            : code == 'es'
                ? const ['Todo','Inglés','Árabe','Turco']
                : const ['All','English','Arabic','Turkish'],
        liveBanner = code == 'ar' ? 'بث مباشر عالمي\nوتبادل لغات' : code == 'es' ? 'Directos globales\ne intercambio de idiomas' : 'Global live\nlanguage exchange',
        voiceBanner = code == 'ar' ? 'غرف صوتية\nوتحدث مع العالم' : code == 'es' ? 'Salas de voz\nhabla con el mundo' : 'Voice rooms\ntalk with the world',
        aiBanner = code == 'ar' ? 'معلّم WorldVoice AI\nتعلّم وتدرّب' : code == 'es' ? 'Profesor WorldVoice AI\naprende y practica' : 'WorldVoice AI teacher\nlearn and practice',
        aiConversation = code == 'ar' ? 'محادثة AI' : code == 'es' ? 'Conversación AI' : 'AI conversation',
        aiConversationBody = code == 'ar' ? 'تدرّب على الكلام والنطق.' : code == 'es' ? 'Practica conversación y pronunciación.' : 'Practice speaking and pronunciation.',
        aiTranslate = code == 'ar' ? 'مساعد الترجمة' : code == 'es' ? 'Asistente de traducción' : 'Translation assistant',
        aiTranslateBody = code == 'ar' ? 'ترجمة وشرح الجمل.' : code == 'es' ? 'Traduce y explica frases.' : 'Translate and explain sentences.',
        aiQuiz = code == 'ar' ? 'كويز سريع' : code == 'es' ? 'Quiz rápido' : 'Quick quiz',
        aiQuizBody = code == 'ar' ? 'اختبر مستواك وتعلّم من أخطائك.' : code == 'es' ? 'Pon a prueba tu nivel.' : 'Test your level and learn from mistakes.';

  final String title;
  final List<String> sections;
  final List<String> languages;
  final String liveBanner;
  final String voiceBanner;
  final String aiBanner;
  final String aiConversation;
  final String aiConversationBody;
  final String aiTranslate;
  final String aiTranslateBody;
  final String aiQuiz;
  final String aiQuizBody;
}
