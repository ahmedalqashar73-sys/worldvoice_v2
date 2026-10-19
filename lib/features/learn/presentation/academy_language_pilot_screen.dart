import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/academy_language_pilots.dart';
import 'academy_illustrated_story_art.dart';

const _academyGreen = Color(0xFF125842);

/// One fully authored starter lesson for the four non-English courses.
/// This does NOT unlock or claim that the remaining A1 curriculum exists.
class AcademyLanguagePilotScreen extends StatefulWidget {
  const AcademyLanguagePilotScreen({required this.lesson, super.key});
  final AcademyLanguagePilot lesson;

  @override
  State<AcademyLanguagePilotScreen> createState() =>
      _AcademyLanguagePilotScreenState();
}

class _AcademyLanguagePilotScreenState
    extends State<AcademyLanguagePilotScreen> {
  late final FlutterTts _tts = FlutterTts();
  int? _section;
  int _highest = 0;
  int? _choice;
  bool _translation = false;
  bool _answerChecked = false;
  bool _done = false;
  bool _saving = false;

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';
  String get _user => FirebaseAuth.instance.currentUser?.uid ?? 'guest';
  String get _key =>
      'worldvoice.academy.pilot.v1.$_user.${widget.lesson.code}.lesson1';
  static const _sectionIcons = <IconData>[
    Icons.menu_book_rounded, Icons.translate_rounded,
    Icons.auto_stories_rounded, Icons.forum_rounded,
    Icons.record_voice_over_rounded, Icons.headphones_rounded,
    Icons.fact_check_rounded,
  ];
  static const _namesAr = [
    'شرح القواعد', '20 مفردة', 'القصة المصورة',
    'المحادثة', 'النطق', 'الاستماع', 'الاختبار',
  ];
  static const _namesEn = [
    'Grammar lesson', '20 new words', 'Illustrated story',
    'Conversation', 'Pronunciation', 'Listening', 'Comprehension quiz',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pref = await SharedPreferences.getInstance();
    if (mounted) setState(() => _done = pref.getBool(_key) ?? false);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  void _open(int index) {
    if (index > _highest) return;
    _tts.stop();
    setState(() {
      _section = index;
      _choice = null;
      _answerChecked = false;
    });
  }

  void _continue() {
    _tts.stop();
    setState(() {
      if (_section != null && _highest < _section! + 1) {
        _highest = _section! + 1;
      }
      _section = null;
    });
  }

  Future<void> _speak(String term, {bool slow = false}) async {
    try {
      await _tts.stop();
      final locale = widget.lesson.voiceLocale;
      final ok = await _tts.isLanguageAvailable(locale);
      if (ok == false) throw StateError('Language voice unavailable');
      await _tts.setLanguage(locale);
      await _tts.setSpeechRate(slow ? 0.30 : 0.50);
      await _tts.setVolume(1.0);
      final result = await _tts.speak(term);
      if (result == 0) throw StateError('Speech failed');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        _ar ? 'ثبّت صوت لغة الكورس من إعدادات تحويل النص إلى كلام.'
            : 'Install the target-language voice in phone text-to-speech settings.',
      )));
    }
  }

  Future<void> _save() async {
    if (_saving || _choice != widget.lesson.correctIndex) return;
    setState(() => _saving = true);
    try {
      final p = await SharedPreferences.getInstance();
      if (!await p.setBool(_key, true)) throw StateError('Local storage failed');
      if (!mounted) return;
      setState(() {
        _done = true;
        _highest = 7;
        _section = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        _ar ? 'أنجزت الدرس! الحفظ على هذا الجهاز، وليس في Firebase.'
            : 'Lesson complete. Saved on this device, not Firebase.',
      )));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        _ar ? 'تعذر الحفظ على الجهاز.' : 'Could not save on this device.',
      )));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _surface(Widget child) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: child,
    );
  }

  Widget _audio(String text) => Wrap(spacing: 10, runSpacing: 8, children: [
    FilledButton.tonalIcon(
      onPressed: () => _speak(text),
      icon: const Icon(Icons.volume_up_rounded),
      label: Text(_ar ? 'استمع' : 'Listen'),
    ),
    OutlinedButton.icon(
      onPressed: () => _speak(text, slow: true),
      icon: const Icon(Icons.slow_motion_video_rounded),
      label: Text(_ar ? 'ببطء' : 'Slow'),
    ),
  ]);

  Widget _sectionList() {
    final l = widget.lesson;
    final scheme = Theme.of(context).colorScheme;
    final accent = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFA2E9BF) : _academyGreen;
    return ListView(
      key: const ValueKey('academy-pilot-sections'),
      padding: const EdgeInsets.all(18),
      children: [
        Text(_ar ? l.titleArabic : l.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900, color: accent)),
        const SizedBox(height: 8),
        Text(_ar
            ? 'الدرس الأول كامل: تعلّم الكلمات والقاعدة والقصة والمحادثة والاستماع.'
            : 'Your complete first lesson: learn grammar, words, story, dialogue and listening.',
          style: TextStyle(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 9),
        Text(_ar
            ? 'بقية دروس A1 في هذه اللغة قيد الإعداد.'
            : 'The rest of this language’s A1 lessons are being prepared.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        if (_done) ...[
          const SizedBox(height: 9),
          Text(_ar ? 'مكتمل ومحفوظ محليًا' : 'Completed · saved on device',
            style: TextStyle(color: accent, fontWeight: FontWeight.w900)),
        ],
        const SizedBox(height: 19),
        for (var i = 0; i < _sectionIcons.length; i++)
          Padding(padding: const EdgeInsets.only(bottom: 10),
            child: Material(color: scheme.surface,
              borderRadius: BorderRadius.circular(17),
              child: InkWell(
                key: ValueKey('academy-pilot-section-$i'),
                borderRadius: BorderRadius.circular(17),
                onTap: i <= _highest ? () => _open(i) : null,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Row(children: [
                    Icon(_sectionIcons[i], color: accent, size: 27),
                    const SizedBox(width: 13),
                    Expanded(child: Text(
                        _ar ? _namesAr[i] : _namesEn[i],
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 17))),
                    Icon(i < _highest
                        ? Icons.check_circle_rounded
                        : i == _highest
                            ? Icons.chevron_right_rounded
                            : Icons.lock_outline_rounded,
                      color: i < _highest ? accent : scheme.onSurfaceVariant),
                  ]),
                ),
              )),
          ),
      ],
    );
  }

  Widget _content() {
    final l = widget.lesson;
    final scheme = Theme.of(context).colorScheme;
    final textStyle = TextStyle(
        color: scheme.onSurface, fontSize: 18, height: 1.6);
    final stage = _section!;
    switch (stage) {
      case 0:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(_ar ? 'افهم القاعدة مع الأستاذة' : 'Learn with your tutor',
            style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          _surface(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_ar ? l.grammarArabic : l.grammar, style: textStyle),
            const SizedBox(height: 12),
            Text(l.title, style: TextStyle(
                color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
          ])),
          const SizedBox(height: 16),
          // Always play the target language, not an English explanation.
          _audio(l.dialogue),
        ]);
      case 1:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(_ar ? '20 كلمة جديدة' : '20 new words',
            style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          for (var i = 0; i < l.words.length; i++)
            Padding(padding: const EdgeInsets.only(bottom: 9),
              child: _surface(Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SelectableText(l.words[i].term,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(color: scheme.onSurface, fontSize: 21,
                          fontWeight: FontWeight.w900)),
                    Text(l.words[i].pronunciation,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(color: scheme.onSurfaceVariant,
                          fontSize: 15)),
                    Text(l.words[i].arabic,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(color: scheme.onSurface,
                          fontSize: 15)),
                  ],
                )),
                IconButton(
                  tooltip: _ar ? 'نطق الكلمة' : 'Speak word',
                  onPressed: () => _speak(l.words[i].term),
                  icon: const Icon(Icons.volume_up_rounded),
                ),
              ]))),
        ]);
      case 2:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(_ar ? 'القصة المصورة' : 'Illustrated story',
            style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          AcademyIllustratedStoryArt(scene: 1, page: 1, animate: false),
          const SizedBox(height: 15),
          for (final paragraph in l.story) ...[
            SelectableText(paragraph,
              textDirection: TextDirection.ltr, style: textStyle),
            const SizedBox(height: 15),
          ],
          _audio(l.story.join(' ')),
          TextButton.icon(
            onPressed: () => setState(() => _translation = !_translation),
            icon: const Icon(Icons.translate_rounded),
            label: Text(_ar ? 'الترجمة' : 'Translation'),
          ),
          if (_translation)
            for (final meaning in l.storyArabic)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(meaning,
                    textDirection: TextDirection.rtl, style: textStyle),
              ),
        ]);
      case 3:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(_ar ? 'المحادثة' : 'Conversation',
            style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _surface(SelectableText(l.dialogue,
            textDirection: TextDirection.ltr,
            style: textStyle)),
          const SizedBox(height: 12),
          _audio(l.dialogue),
        ]);
      case 4:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(_ar ? 'التدرب على النطق' : 'Pronunciation practice',
            style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(_ar
              ? 'استمع إلى الجملة وكرر بصوتك. النطق الذاتي لا يتضمن تصحيحًا آليًا بالميكروفون حاليًا.'
              : 'Listen and repeat aloud. Automatic microphone pronunciation scoring is not available yet.',
            style: textStyle),
          const SizedBox(height: 16),
          _surface(Text(l.listening,
            textDirection: TextDirection.ltr, style: textStyle)),
          const SizedBox(height: 12),
          _audio(l.listening),
        ]);
      case 5:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(_ar ? 'الاستماع' : 'Listening',
            style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(_ar ? 'استمع مرة بالسرعة العادية ومرة بالسرعة البطيئة.'
              : 'Listen first at normal speed, then slowly.',
            style: textStyle),
          const SizedBox(height: 12),
          _audio(l.listening),
          const SizedBox(height: 14),
          Text(_ar ? 'نص الاستماع' : 'Transcript',
            style: TextStyle(color: scheme.onSurfaceVariant)),
          SelectableText(l.listening,
            textDirection: TextDirection.ltr, style: textStyle),
        ]);
      default:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(_ar ? 'اختبار فهم القصة' : 'Story comprehension quiz',
            style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text(l.comprehension,
            textDirection: TextDirection.ltr, style: textStyle),
          const SizedBox(height: 12),
          for (var i = 0; i < l.options.length; i++)
            Padding(padding: const EdgeInsets.only(bottom: 9),
              child: OutlinedButton(
                onPressed: _choice == l.correctIndex && _answerChecked
                    ? null : () => setState(() {
                        _choice = i; _answerChecked = false;
                      }),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: _choice == i
                      ? scheme.primaryContainer : scheme.surface,
                ),
                child: Text(l.options[i], textDirection: TextDirection.ltr,
                  style: TextStyle(color: scheme.onSurface)),
              ),
            ),
          if (_answerChecked)
            Text(_choice == l.correctIndex
                ? (_ar ? 'أحسنت! إجابة صحيحة.' : 'Correct! Well done.')
                : (_ar ? 'حاول مجددًا بعد مراجعة القصة.' : 'Review the story and try again.'),
              style: TextStyle(color: _choice == l.correctIndex
                  ? _academyGreen : scheme.error)),
        ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _section == 6;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _academyGreen, foregroundColor: Colors.white,
        title: Text(widget.lesson.name,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (_section != null)
            IconButton(
              onPressed: () {
                _tts.stop();
                setState(() => _section = null);
              },
              icon: const Icon(Icons.view_list_rounded),
              tooltip: _ar ? 'أقسام الدرس' : 'Lesson sections',
            ),
        ],
      ),
      body: SafeArea(child: _section == null
          ? _sectionList()
          : Column(children: [
              Expanded(child: ListView(
                padding: const EdgeInsets.all(19),
                children: [_content()],
              )),
              Padding(
                padding: const EdgeInsets.all(13),
                child: FilledButton(
                  key: const ValueKey('academy-pilot-next'),
                  onPressed: last ? (_choice == null || _saving
                      ? null : _answerChecked && _choice == widget.lesson.correctIndex
                          ? _save : () => setState(() => _answerChecked = true))
                      : _continue,
                  style: FilledButton.styleFrom(
                    backgroundColor: _academyGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: Text(last
                      ? (_answerChecked && _choice == widget.lesson.correctIndex
                        ? (_ar ? 'حفظ إكمال الدرس' : 'Complete lesson')
                        : (_ar ? 'تحقق من الإجابة' : 'Check answer'))
                      : (_ar ? 'التالي' : 'Continue')),
                ),
              ),
            ])),
    );
  }
}
