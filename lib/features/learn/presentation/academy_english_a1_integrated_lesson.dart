import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../data/academy_english_a1_catalog.dart';
import '../data/academy_english_a1_lesson_checks.dart';
import '../data/academy_english_a1_dialogues.dart';
import '../data/academy_english_a1_long_stories.dart';
import '../data/academy_english_a1_vocabulary.dart';
import 'academy_illustrated_story_art.dart';

const _lessonGreen = Color(0xFF125842);
const _lessonGold = Color(0xFFEFC57E);

/// One *complete* lesson, not one vocabulary/grammar/story tile. All eight
/// teaching stages belong to the same persistent English A1 lesson ID.
class AcademyEnglishA1IntegratedLesson extends StatefulWidget {
  const AcademyEnglishA1IntegratedLesson({
    required this.unit, required this.lesson, required this.lessonNumber,
    super.key,
  });

  final EnglishA1Unit unit;
  final EnglishA1Lesson lesson;
  final int lessonNumber;

  @override
  State<AcademyEnglishA1IntegratedLesson> createState() =>
      _AcademyEnglishA1IntegratedLessonState();
}

class _AcademyEnglishA1IntegratedLessonState
    extends State<AcademyEnglishA1IntegratedLesson> {
  late final List<EnglishA1Word> _words =
      EnglishA1Vocabulary.forLesson(widget.unit.id, widget.lessonNumber);
  late final EnglishA1LongStory _story =
      EnglishA1StorySyllabus.storyFor(widget.unit.id, widget.lessonNumber);
  late final EnglishA1StoryChapter _chapter =
      EnglishA1StorySyllabus.chapterFor(widget.unit.id, widget.lessonNumber);
  late final EnglishA1Grammar _grammar =
      EnglishA1LessonChecks.grammarFor(widget.unit.id, widget.lessonNumber);
  late final EnglishA1Dialogue _dialogue =
      EnglishA1DialogueCatalog.forLesson(widget.unit.id, widget.lessonNumber);
  late final FlutterTts _tts = FlutterTts();

  int _stage = 0;
  int? _chosen;
  bool _checked = false;
  bool _conversationPassed = false;
  bool _listeningPassed = false;
  bool _readingPassed = false;
  int _practiceNumber = 0;
  bool _speaking = false;
  bool _showListeningTranscript = false;

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';
  Color get _accent => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF98E8BC) : _lessonGreen;

  static const _stageAr = [
    'شرح القواعد', '20 مفردة', 'القصة المصورة', 'اختبار الكلمات',
    'المحادثة', 'النطق', 'الاستماع', 'اكتمال الدرس',
  ];
  static const _stageEn = [
    'Grammar', '20 words', 'Illustrated story', 'Word quiz',
    'Conversation', 'Pronunciation', 'Listening', 'Complete',
  ];

  @override
  void initState() {
    super.initState();
    _tts.setCompletionHandler(_finishedSpeech);
    _tts.setCancelHandler(_finishedSpeech);
    _tts.setErrorHandler((_) => _finishedSpeech());
  }

  void _finishedSpeech() {
    if (mounted) setState(() => _speaking = false);
  }

  Future<void> _hear(String text, {bool slow = false}) async {
    try {
      await _tts.stop();
      if (!mounted) return;
      if (await _tts.isLanguageAvailable('en-US') == false) {
        throw StateError('English voice unavailable');
      }
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(slow ? .30 : .50);
      await _tts.setVolume(1);
      if (!mounted) return;
      setState(() => _speaking = true);
      final started = await _tts.speak(text);
      if (started == 0) throw StateError('Speech failed');
    } catch (_) {
      _finishedSpeech();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_ar
            ? 'تعذر النطق. تأكد من تثبيت صوت الإنجليزية ورفع صوت الوسائط.'
            : 'Install the English voice and check media volume.'),
      ));
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  void _next() {
    _tts.stop();
    setState(() {
      _stage++;
      _chosen = null;
      _checked = false;
    });
  }

  Future<void> _openChapter() async {
    final passed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _EnglishA1BookChapter(
          story: _story, chapter: _chapter,
          chapterNumber: (widget.lessonNumber - 1) % 4 + 1,
          question: EnglishA1LessonChecks.storyCheck(
              widget.unit.id, widget.lessonNumber),
        ),
      ),
    );
    if (passed == true && mounted) {
      setState(() => _readingPassed = true);
    }
  }

  Widget _audioControls(String text) {
    return Wrap(spacing: 9, runSpacing: 7, children: [
      FilledButton.tonalIcon(
        onPressed: () => _hear(text),
        icon: Icon(_speaking ? Icons.volume_up_rounded
            : Icons.play_arrow_rounded),
        label: Text(_ar ? 'استمع' : 'Listen'),
      ),
      OutlinedButton.icon(
        onPressed: () => _hear(text, slow: true),
        icon: const Icon(Icons.slow_motion_video_rounded),
        label: Text(_ar ? 'ببطء' : 'Slow'),
      ),
    ]);
  }

  Widget _panel({required Widget child}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }

  Widget _promptOptions({
    required String question,
    required List<String> options,
    required int correct,
    required VoidCallback onPassed,
    bool rtlOptions = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final right = _checked && _chosen == correct;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(question,
        textDirection: TextDirection.ltr,
        style: TextStyle(fontSize: 19, height: 1.4,
            color: scheme.onSurface, fontWeight: FontWeight.w800)),
      const SizedBox(height: 15),
      for (var i = 0; i < options.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: OutlinedButton(
            onPressed: right ? null : () => setState(() {
              _chosen = i; _checked = false;
            }),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(14),
              alignment: AlignmentDirectional.centerStart,
              minimumSize: const Size.fromHeight(58),
              backgroundColor: _chosen == i
                  ? scheme.primaryContainer : scheme.surface,
              side: BorderSide(color: _chosen == i
                  ? _accent : scheme.outlineVariant),
            ),
            child: Text(options[i],
              textDirection: rtlOptions ? TextDirection.rtl : TextDirection.ltr,
              style: TextStyle(fontSize: 16, color: scheme.onSurface)),
          ),
        ),
      if (_checked)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(right
              ? (_ar ? 'صحيح، أحسنت!' : 'Correct, well done!')
              : (_ar ? 'حاول مرة أخرى.' : 'Try again.'),
            style: TextStyle(color: right ? _accent : scheme.error,
                fontWeight: FontWeight.w800)),
        ),
      FilledButton(
        key: const ValueKey('academy-integrated-answer'),
        onPressed: _chosen == null ? null
            : right ? onPassed : () => setState(() => _checked = true),
        style: FilledButton.styleFrom(
          backgroundColor: _lessonGreen, foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(53)),
        child: Text(right
            ? (_ar ? 'التالي' : 'Continue')
            : (_ar ? 'تحقق من الإجابة' : 'Check answer')),
      ),
    ]);
  }

  Widget _conversation() {
    final scheme = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(_ar ? 'تحدث مع الأستاذة' : 'Talk with your tutor',
          style: TextStyle(fontSize: 22, color: _accent,
              fontWeight: FontWeight.w900)),
      const SizedBox(height: 13),
      _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFD6EBDF),
            child: Icon(Icons.face_3_rounded, color: _lessonGreen)),
          const SizedBox(width: 10),
          Text(_ar ? 'الأستاذة إيما' : 'Tutor Emma',
            style: TextStyle(color: _accent, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 13),
        Text(_dialogue.dialogue,
            textDirection: TextDirection.ltr,
            style: TextStyle(color: scheme.onSurface,
                fontSize: 19, height: 1.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 11),
        Text(widget.lesson.arabic,
            textDirection: TextDirection.rtl,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 15)),
        const SizedBox(height: 14),
        _audioControls(_dialogue.dialogue),
      ])),
      const SizedBox(height: 21),
      _promptOptions(
        question: widget.lesson.question,
        options: widget.lesson.options,
        correct: widget.lesson.answer,
        onPassed: () {
          _conversationPassed = true;
          _next();
        },
      ),
    ]);
  }

  Widget _vocabulary() {
    final scheme = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(_ar ? '20 كلمة للتعلم والمراجعة' : '20 words to learn and review',
          style: TextStyle(color: _accent,
              fontSize: 21, fontWeight: FontWeight.w900)),
      const SizedBox(height: 7),
      Text(_ar
          ? 'تحتوي القائمة على كلمات جديدة وأخرى تتكرر لترسيخ الحفظ.'
          : 'New words and intentional revision words build lasting recall.',
        style: TextStyle(color: scheme.onSurfaceVariant)),
      const SizedBox(height: 15),
      for (var i = 0; i < _words.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: _panel(child: Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_words[i].term, textDirection: TextDirection.ltr,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                        color: scheme.onSurface)),
                const SizedBox(height: 4),
                Text(_words[i].pronunciation,
                    style: TextStyle(fontSize: 15,
                        color: _accent, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(_words[i].arabic,
                    style: TextStyle(color: scheme.onSurface, fontSize: 15)),
              ],
            )),
            IconButton.filledTonal(
              tooltip: _ar ? 'استمع للكلمة' : 'Hear word',
              icon: const Icon(Icons.volume_up_rounded),
              onPressed: () => _hear(_words[i].term),
            ),
          ])),
        ),
    ]);
  }

  Widget _pronunciation() {
    final scheme = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(_ar ? 'استمع، ثم ردد بصوتك' : 'Listen and repeat',
        style: TextStyle(color: _accent, fontSize: 23,
            fontWeight: FontWeight.w900)),
      const SizedBox(height: 13),
      _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.lesson.spoken,
              textDirection: TextDirection.ltr,
              style: TextStyle(color: scheme.onSurface, fontSize: 21,
                  height: 1.55, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _audioControls(widget.lesson.spoken),
        ])),
      const SizedBox(height: 16),
      Text(_ar
          ? 'اسمع الجملة مرتين، مرة عادية ومرة بطيئة. كررها ثلاث مرات.'
          : 'Listen at normal and slow speed, then repeat three times.',
        style: TextStyle(color: scheme.onSurface, height: 1.5)),
      const SizedBox(height: 10),
      Text(_ar
          ? 'التدريب ذاتي حاليًا؛ لا يتم تقييم صحة النطق بالميكروفون.'
          : 'This is guided self-practice, not automatic microphone scoring.',
        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
    ]);
  }

  Widget _grammarPage() {
    final scheme = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(_grammar.title,
          style: TextStyle(color: _accent, fontSize: 24,
              fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_grammar.example,
              textDirection: TextDirection.ltr,
              style: TextStyle(color: scheme.onSurface, fontSize: 21,
                  fontWeight: FontWeight.w800, height: 1.5)),
          const SizedBox(height: 10),
          Text(_grammar.helpArabic,
              textDirection: TextDirection.rtl,
              style: TextStyle(color: scheme.onSurface, fontSize: 16,
                  height: 1.6)),
          const SizedBox(height: 13),
          _audioControls(_grammar.example),
        ])),
      const SizedBox(height: 18),
      Text(_ar ? 'تطبيق سريع' : 'Quick application',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      const SizedBox(height: 7),
      Text(_dialogue.dialogue, textDirection: TextDirection.ltr,
        style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5)),
    ]);
  }

  Widget _listening() {
    final scheme = Theme.of(context).colorScheme;
    final word = _words[12];
    final other1 = _words[13];
    final other2 = _words[14];
    final correct = widget.lessonNumber % 3;
    final choices = <String>[other1.arabic, other2.arabic];
    choices.insert(correct, word.arabic);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(_ar ? 'استماع وحوار من الحياة اليومية' : 'Listen to a real-life passage',
        style: TextStyle(color: _accent, fontSize: 23,
            fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      Text(_ar
          ? 'استمع إلى الفقرة كاملة، ثم اكشف النص إذا احتجت.'
          : 'Listen to the passage first, and reveal the transcript if needed.',
        style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5)),
      const SizedBox(height: 13),
      _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
        const Icon(Icons.headphones_rounded,
            color: _lessonGreen, size: 52),
        const SizedBox(height: 11),
        _audioControls(_dialogue.listening),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () => setState(() =>
              _showListeningTranscript = !_showListeningTranscript),
          icon: const Icon(Icons.subject_rounded),
          label: Text(_ar ? 'إظهار نص الاستماع' : 'Show listening transcript'),
        ),
        if (_showListeningTranscript)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: SelectableText(_dialogue.listening,
              textDirection: TextDirection.ltr,
              style: TextStyle(color: scheme.onSurface,
                  fontSize: 17, height: 1.6)),
          ),
      ])),
      const SizedBox(height: 23),
      Text(_ar ? 'استمع لكلمة من مفردات الدرس واختر معناها.'
          : 'Now listen to a lesson word and choose its meaning.',
        style: TextStyle(color: scheme.onSurfaceVariant)),
      const SizedBox(height: 12),
      _panel(child: Column(children: [
        const Icon(Icons.record_voice_over_rounded,
            color: _lessonGreen, size: 38),
        const SizedBox(height: 10),
        _audioControls(word.term),
      ])),
      const SizedBox(height: 23),
      _promptOptions(
        question: _ar ? 'ما معنى الكلمة التي سمعتها؟'
            : 'What does the spoken word mean?',
        options: choices, correct: correct, rtlOptions: true,
        onPassed: () {
          _listeningPassed = true;
          _next();
        },
      ),
    ]);
  }

  Widget _storyStage() {
    final scheme = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AcademyIllustratedStoryArt(
          scene: _story.scene, page: (widget.lessonNumber - 1) % 4),
      const SizedBox(height: 18),
      Text(_ar ? _story.titleArabic : _story.title,
          style: TextStyle(color: _accent,
              fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 7),
      Text(_ar ? 'قصة قصيرة · 3 فقرات' :
          'Short story · 3 paragraphs',
        style: TextStyle(color: scheme.onSurfaceVariant)),
      const SizedBox(height: 10),
      Text(_ar ? _chapter.titleArabic : _chapter.title,
          style: TextStyle(fontSize: 18, color: scheme.onSurface)),
      const SizedBox(height: 12),
      Text(_ar
          ? 'صفحة قراءة واحدة، تحتوي على رسمة وثلاث فقرات وصوت وترجمة وسؤال.'
          : 'One readable page with an illustration, three paragraphs, audio, translation and a question.',
        style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5)),
      const SizedBox(height: 15),
      FilledButton.icon(
        key: const ValueKey('academy-integrated-read-story'),
        onPressed: _openChapter,
        style: FilledButton.styleFrom(
          backgroundColor: _lessonGreen, foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56)),
        icon: Icon(_readingPassed
            ? Icons.check_circle_rounded : Icons.menu_book_rounded),
        label: Text(_readingPassed
            ? (_ar ? 'قراءة الفصل مرة أخرى' : 'Read this chapter again')
            : (_ar ? 'افتح الكتاب واقرأ الفصل' : 'Open the storybook')),
      ),
      if (_readingPassed)
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Text(_ar ? 'أحسنت، نجحت في فهم الفصل!'
              : 'Great! You passed the chapter comprehension check.',
            style: TextStyle(color: _accent, fontWeight: FontWeight.w800)),
        ),
    ]);
  }

  Widget _practice() {
    final scheme = Theme.of(context).colorScheme;
    final index = _practiceNumber * 4;
    final word = _words[index];
    final correctIndex = (_practiceNumber + 1) % 3;
    final choices = <String>[
      _words[index + 1].arabic, _words[index + 2].arabic,
    ]..insert(correctIndex, word.arabic);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(_ar ? 'راجع الكلمات بنفسك' : 'Check your understanding',
        style: TextStyle(color: _accent, fontSize: 23,
            fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      Text(_ar
          ? 'سؤال ${_practiceNumber + 1} من 4'
          : 'Question ${_practiceNumber + 1} of 4',
        style: TextStyle(color: scheme.onSurfaceVariant)),
      const SizedBox(height: 13),
      _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(word.term, textDirection: TextDirection.ltr,
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900,
                color: scheme.onSurface)),
        const SizedBox(height: 8),
        IconButton.filledTonal(
          onPressed: () => _hear(word.term),
          icon: const Icon(Icons.volume_up_rounded),
        ),
      ])),
      const SizedBox(height: 20),
      _promptOptions(
        question: _ar ? 'ما المعنى الصحيح؟' : 'Choose the correct meaning.',
        options: choices, correct: correctIndex, rtlOptions: true,
        onPassed: () {
          if (_practiceNumber == 3) {
            _next();
          } else {
            setState(() {
              _practiceNumber++;
              _chosen = null;
              _checked = false;
            });
          }
        },
      ),
    ]);
  }

  Widget _finish() {
    final scheme = Theme.of(context).colorScheme;
    return Column(children: [
      const SizedBox(height: 30),
      const Icon(Icons.emoji_events_rounded,
          color: _lessonGold, size: 76),
      const SizedBox(height: 17),
      Text(_ar ? 'ممتاز! أكملت درسًا متكاملًا' : 'Excellent! Lesson complete',
        textAlign: TextAlign.center,
        style: TextStyle(color: _accent,
            fontSize: 26, fontWeight: FontWeight.w900)),
      const SizedBox(height: 13),
      Text(_ar
          ? 'أنهيت المحادثة، وراجعت 20 كلمة، وتدربت على النطق والقواعد والاستماع، وقرأت فصل القصة، وأجبت عن الاختبار.'
          : 'You completed conversation, 20 vocabulary items, pronunciation, grammar, listening, an illustrated story chapter, and practice.',
        textAlign: TextAlign.center,
        style: TextStyle(color: scheme.onSurface, fontSize: 16, height: 1.7)),
      const SizedBox(height: 25),
      Text(_ar
          ? 'سيُحفظ تقدم هذا الدرس على الجهاز لحسابك.'
          : 'This lesson is saved locally for your account.',
        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
    ]);
  }

  Widget _currentStage() => switch (_stage) {
    0 => _grammarPage(),
    1 => _vocabulary(),
    2 => _storyStage(),
    3 => _practice(),
    4 => _conversation(),
    5 => _pronunciation(),
    6 => _listening(),
    _ => _finish(),
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canContinue = switch (_stage) {
      2 => _readingPassed,
      3 => false,
      4 => _conversationPassed,
      6 => _listeningPassed,
      _ => true,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(_ar
            ? 'الوحدة ${widget.unit.id} · الدرس ${widget.lessonNumber}'
            : 'Unit ${widget.unit.id} · Lesson ${widget.lessonNumber}'),
        backgroundColor: _lessonGreen, foregroundColor: Colors.white,
      ),
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(17, 14, 17, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: (_stage + 1) / 8,
                minHeight: 8,
                borderRadius: BorderRadius.circular(9),
                color: _lessonGreen,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: Text(
                  _ar ? _stageAr[_stage] : _stageEn[_stage],
                  style: TextStyle(color: _accent,
                      fontWeight: FontWeight.w900, fontSize: 17))),
                Text('${_stage + 1}/8',
                    style: TextStyle(color: scheme.onSurfaceVariant)),
              ]),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            key: ValueKey('academy-integrated-stage-$_stage'),
            padding: const EdgeInsets.fromLTRB(17, 10, 17, 22),
            children: [_currentStage()],
          ),
        ),
        if (canContinue)
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 5, 17, 14),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('academy-integrated-next'),
                onPressed: () {
                  if (_stage == 7) {
                    Navigator.of(context).pop(true);
                  } else {
                    _next();
                  }
                },
                style: FilledButton.styleFrom(
                    backgroundColor: _lessonGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54)),
                icon: Icon(_stage == 7
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_rounded),
                label: Text(_stage == 7
                    ? (_ar ? 'احفظ الدرس وارجع للوحدة' : 'Save lesson')
                    : (_ar ? 'المتابعة' : 'Continue')),
              ),
            ),
          ),
      ])),
    );
  }
}

class _EnglishA1BookChapter extends StatefulWidget {
  const _EnglishA1BookChapter({
    required this.story,
    required this.chapter,
    required this.chapterNumber,
    required this.question,
  });
  final EnglishA1LongStory story;
  final EnglishA1StoryChapter chapter;
  final int chapterNumber;
  final EnglishA1Check question;

  @override
  State<_EnglishA1BookChapter> createState() => _EnglishA1BookChapterState();
}

class _EnglishA1BookChapterState extends State<_EnglishA1BookChapter> {
  int _page = 0;
  int? _choice;
  bool _checked = false;
  bool _translate = false;
  double _fontSize = 21;
  late final FlutterTts _tts = FlutterTts();

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';
  bool get _quiz => _page == widget.chapter.paragraphs.length + 1;

  Future<void> _speak(String text, {bool slow = false}) async {
    try {
      await _tts.stop();
      if (await _tts.isLanguageAvailable('en-US') == false) {
        throw StateError('English voice missing');
      }
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(slow ? .30 : .50);
      await _tts.setVolume(1);
      final started = await _tts.speak(text);
      if (started == 0) throw StateError('Could not speak');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_ar ? 'صوت الإنجليزية غير متوفر على الجهاز.'
            : 'English speech voice is unavailable on the device.'),
      ));
    }
  }

  void _turn(int next) {
    if (next < 0 || next > widget.chapter.paragraphs.length + 1) return;
    _tts.stop();
    setState(() {
      _page = next; _translate = false; _choice = null; _checked = false;
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final night = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final paper = night ? scheme.surfaceContainerHigh
        : const Color(0xFFFFFCF2);
    final ink = scheme.onSurface;
    final correct = _checked && _choice == widget.question.answer;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _lessonGreen, foregroundColor: Colors.white,
        title: Text(_ar ? 'مكتبة WorldVoice' : 'WorldVoice Library'),
        actions: [
          IconButton(
            tooltip: _ar ? 'تصغير النص' : 'Smaller text',
            onPressed: () => setState(() {
              _fontSize = (_fontSize - 2).clamp(17, 30).toDouble();
            }),
            icon: const Icon(Icons.text_decrease_rounded)),
          IconButton(
            tooltip: _ar ? 'تكبير النص' : 'Larger text',
            onPressed: () => setState(() {
              _fontSize = (_fontSize + 2).clamp(17, 30).toDouble();
            }),
            icon: const Icon(Icons.text_increase_rounded)),
        ],
      ),
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(17, 11, 17, 10),
          child: Row(children: [
            Expanded(child: LinearProgressIndicator(
              value: (_page + 1) / (widget.chapter.paragraphs.length + 2),
              minHeight: 6, borderRadius: BorderRadius.circular(8),
              color: _lessonGreen,
              backgroundColor: scheme.surfaceContainerHighest,
            )),
            const SizedBox(width: 12),
            Text('${_page + 1}/${widget.chapter.paragraphs.length + 2}',
                style: TextStyle(color: scheme.onSurfaceVariant)),
          ]),
        ),
        Expanded(child: ListView(
          key: ValueKey('academy-story-page-$_page'),
          padding: const EdgeInsets.fromLTRB(15, 9, 15, 18),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: paper,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: scheme.outlineVariant),
                boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: night ? .07 : .09),
                  blurRadius: 18, offset: const Offset(0, 7),
                )],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.auto_stories_rounded,
                        color: _lessonGreen, size: 22),
                    const SizedBox(width: 7),
                    Flexible(child: Text(
                      _ar ? widget.story.titleArabic : widget.story.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900,
                          color: ink))),
                  ]),
                  const SizedBox(height: 7),
                  Text(_ar ? 'الفصل ${widget.chapterNumber} من 4'
                      : 'Chapter ${widget.chapterNumber} of 4',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700)),
                  const SizedBox(height: 11),
                  AcademyIllustratedStoryArt(
                    scene: widget.story.scene,
                    page: widget.chapterNumber * 5 + _page,
                  ),
                  const SizedBox(height: 15),
                  if (_page == 0) ...[
                    Text(_ar ? widget.chapter.titleArabic
                        : widget.chapter.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ink, fontSize: 24,
                          fontWeight: FontWeight.w900)),
                    const SizedBox(height: 14),
                    Text(_ar
                        ? 'افتح الصفحات واقرأ الفقرات الثلاث. يمكنك تكبير الخط والاستماع والترجمة، ثم أجب عن سؤال الفهم.'
                        : 'Read three story paragraphs, resize the type, listen and translate; finish with a comprehension question.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ink, fontSize: 17, height: 1.7)),
                  ] else if (!_quiz) ...[
                    Text(_ar ? 'فقرة $_page من 3' : 'Paragraph $_page of 3',
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 13),
                    SelectableText(widget.chapter.paragraphs[_page - 1].english,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: _fontSize, height: 1.85,
                        fontWeight: FontWeight.w600, color: ink)),
                    const SizedBox(height: 13),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      FilledButton.tonalIcon(
                        onPressed: () => _speak(
                            widget.chapter.paragraphs[_page - 1].english),
                        icon: const Icon(Icons.volume_up_rounded),
                        label: Text(_ar ? 'اقرأ لي' : 'Read aloud')),
                      OutlinedButton.icon(
                        onPressed: () => _speak(
                          widget.chapter.paragraphs[_page - 1].english, slow: true),
                        icon: const Icon(Icons.slow_motion_video_rounded),
                        label: Text(_ar ? 'ببطء' : 'Slow')),
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => _translate = !_translate),
                        icon: const Icon(Icons.translate_rounded),
                        label: Text(_ar ? 'الترجمة' : 'Translation')),
                    ]),
                    if (_translate) ...[
                      const SizedBox(height: 12),
                      Text(widget.chapter.paragraphs[_page - 1].arabic,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(fontSize: _fontSize - 3, height: 1.7,
                            color: ink)),
                    ],
                  ] else ...[
                    Text(_ar ? 'هل فهمت الفصل؟' : 'Check your reading',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22,
                          fontWeight: FontWeight.w900, color: ink)),
                    const SizedBox(height: 14),
                    Text(widget.question.question,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(fontSize: 19,
                          fontWeight: FontWeight.w700, color: ink)),
                    const SizedBox(height: 15),
                    for (var i = 0; i < widget.question.options.length; i++)
                      Padding(padding: const EdgeInsets.only(bottom: 10),
                        child: OutlinedButton(
                          onPressed: correct ? null : () => setState(() {
                            _choice = i; _checked = false;
                          }),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _choice == i
                                ? scheme.primaryContainer : paper,
                            minimumSize: const Size.fromHeight(54),
                          ),
                          child: Text(widget.question.options[i],
                            style: TextStyle(color: ink)))),
                    if (_checked)
                      Text(correct
                          ? (_ar ? 'رائع! فهمت أحداث الفصل.'
                              : 'Great! You understood this chapter.')
                          : (_ar ? 'حاول مرة أخرى.' : 'Try again.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w800,
                            color: correct ? _lessonGreen : scheme.error)),
                  ],
                  const SizedBox(height: 10),
                  Divider(color: scheme.outlineVariant),
                  const Text('WORLDVOICE · STORYBOOK',
                    textAlign: TextAlign.center,
                    style: TextStyle(letterSpacing: 1.2,
                        fontSize: 10, color: Color(0xFF6C8B80))),
                ],
              ),
            ),
          ],
        )),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 4, 15, 14),
          child: Row(children: [
            if (_page > 0)
              OutlinedButton(
                onPressed: () => _turn(_page - 1),
                child: Text(_ar ? 'السابق' : 'Back')),
            const Spacer(),
            FilledButton.icon(
              key: const ValueKey('academy-story-chapter-next'),
              onPressed: _quiz
                  ? (_choice == null ? null
                      : correct ? () => Navigator.of(context).pop(true)
                      : () => setState(() => _checked = true))
                  : () => _turn(_page + 1),
              style: FilledButton.styleFrom(backgroundColor: _lessonGreen,
                  foregroundColor: Colors.white),
              icon: Icon(correct
                  ? Icons.check_circle_rounded : Icons.arrow_forward_rounded),
              label: Text(_quiz
                  ? (correct ? (_ar ? 'إكمال الفصل' : 'Finish chapter')
                      : (_ar ? 'تحقق' : 'Check answer'))
                  : (_ar ? 'الصفحة التالية' : 'Next page')),
            ),
          ]),
        ),
      ])),
    );
  }
}
