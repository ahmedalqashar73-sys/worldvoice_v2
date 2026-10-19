import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../data/academy_english_a1_catalog.dart';
import '../data/academy_a1_tutor_lessons.dart';
import '../data/academy_english_pronunciation.dart';
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
  int _highestUnlocked = 0;
  bool _showSectionMenu = true;
  int? _chosen;
  bool _checked = false;
  bool _conversationPassed = false;
  bool _listeningPassed = false;
  bool _readingPassed = false;
  int _practiceNumber = 0;
  int _tutorQuestionIndex = 0;
  int? _tutorChoice;
  bool _tutorChecked = false;
  bool _tutorGrammarPassed = false;

  AcademyTutorLesson? get _tutor =>
      AcademyA1TutorCatalog.forUnitLesson(widget.unit.id, widget.lessonNumber);
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
      if (_stage < 7) {
        _highestUnlocked = math.max(_highestUnlocked, _stage + 1);
        _stage = _highestUnlocked;
      }
      _chosen = null;
      _checked = false;
      _showSectionMenu = true;
    });
  }

  void _openSection(int index) {
    if (index > _highestUnlocked || index < 0) return;
    _tts.stop();
    setState(() {
      _stage = index;
      _showSectionMenu = false;
      _chosen = null;
      _checked = false;
      if (index == 3) _practiceNumber = 0;
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
                Text(AcademyEnglishPronunciation.displayHint(_words[i].term),
                    key: ValueKey('academy-english-pronunciation-$i'),
                    textDirection: TextDirection.ltr,
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
    final tutor = _tutor;
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
      if (tutor != null) ...[
        Text(_ar ? 'النطق الإنجليزي · IPA' : 'English pronunciation · IPA',
          style: TextStyle(color: _accent,
              fontWeight: FontWeight.w900, fontSize: 19)),
        const SizedBox(height: 11),
        _panel(child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final reading in tutor.pronunciationGuide)
              Padding(padding: const EdgeInsets.only(bottom: 9),
                child: Text(reading,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(color: scheme.onSurface,
                      fontSize: 20, fontWeight: FontWeight.w700))),
            Text(tutor.pronunciationTipArabic,
              textDirection: TextDirection.rtl,
              style: TextStyle(color: scheme.onSurface,
                  fontSize: 15, height: 1.65)),
          ])),
        const SizedBox(height: 15),
      ],
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

  Widget _tutorGrammarPage(AcademyTutorLesson tutor) {
    final scheme = Theme.of(context).colorScheme;
    final check = tutor.checks[_tutorQuestionIndex];
    final isCorrect = _tutorChecked && _tutorChoice == check.correctIndex;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        const CircleAvatar(radius: 26,
          backgroundColor: Color(0xFFD6EBDF),
          child: Icon(Icons.face_3_rounded, color: _lessonGreen, size: 27)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_ar ? 'الأستاذة إيما · شرح مباشر' : 'Tutor Emma · Guided lesson',
              style: TextStyle(color: _accent,
                fontWeight: FontWeight.w900, fontSize: 18)),
            Text(_ar ? 'جزء القواعد · نحو 5 دقائق'
                      : 'Grammar section · about 5 minutes',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
          ])),
      ]),
      const SizedBox(height: 15),
      _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tutor.welcomeArabic,
              textDirection: TextDirection.rtl,
              style: TextStyle(color: scheme.onSurface,
                fontSize: 17, height: 1.8)),
          const SizedBox(height: 15),
          Text(_ar ? 'هدفنا اليوم' : 'Today’s goal',
            style: TextStyle(color: _accent,
                fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 5),
          Text(tutor.goalArabic, textDirection: TextDirection.rtl,
            style: TextStyle(color: scheme.onSurface, height: 1.7)),
        ],
      )),
      const SizedBox(height: 20),
      Text(tutor.title, textDirection: TextDirection.ltr,
        style: TextStyle(color: _accent, fontSize: 25,
            fontWeight: FontWeight.w900)),
      const SizedBox(height: 11),
      Text(tutor.ruleArabic, textDirection: TextDirection.rtl,
        style: TextStyle(color: scheme.onSurface, fontSize: 17,
            height: 1.8)),
      const SizedBox(height: 16),
      _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_ar ? 'قاعدة سهلة تتذكرها' : 'Remember the pattern',
            style: TextStyle(color: _accent,
                fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 11),
          for (final pattern in tutor.patterns)
            Padding(padding: const EdgeInsets.only(bottom: 9),
              child: SelectableText(pattern,
                textDirection: TextDirection.ltr,
                style: TextStyle(color: scheme.onSurface,
                    fontSize: 16, height: 1.6,
                    fontWeight: FontWeight.w600))),
        ],
      )),
      const SizedBox(height: 22),
      Text(_ar ? 'نطبق معًا: خمس جمل' : 'Let’s practise: five examples',
        style: TextStyle(color: _accent,
            fontWeight: FontWeight.w900, fontSize: 20)),
      const SizedBox(height: 10),
      for (var i = 0; i < tutor.examples.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _panel(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: SelectableText(tutor.examples[i].english,
                textDirection: TextDirection.ltr,
                style: TextStyle(color: scheme.onSurface,
                    fontWeight: FontWeight.w900, fontSize: 19,
                    height: 1.5))),
              IconButton.filledTonal(
                tooltip: _ar ? 'استمع للمثال' : 'Hear example',
                icon: const Icon(Icons.volume_up_rounded),
                onPressed: () => _hear(tutor.examples[i].english),
              ),
            ]),
            const SizedBox(height: 7),
            Text(tutor.examples[i].arabic,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: scheme.onSurface, fontSize: 15)),
            const SizedBox(height: 8),
            Text(tutor.examples[i].note,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: scheme.onSurfaceVariant,
                    fontSize: 14, height: 1.6)),
          ])),
        ),
      const SizedBox(height: 14),
      _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.lightbulb_outline_rounded, color: _lessonGold),
            const SizedBox(width: 7),
            Text(_ar ? 'خطأ شائع — انتبه' : 'Common mistake',
              style: TextStyle(color: _accent,
                  fontWeight: FontWeight.w900, fontSize: 17)),
          ]),
          const SizedBox(height: 12),
          Text(tutor.commonMistake,
              textDirection: TextDirection.ltr,
              style: TextStyle(color: scheme.error,
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(tutor.correctForm,
              textDirection: TextDirection.ltr,
              style: TextStyle(color: scheme.onSurface,
                  fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(tutor.mistakeExplanationArabic,
              textDirection: TextDirection.rtl,
              style: TextStyle(color: scheme.onSurface,
                  height: 1.7)),
          const SizedBox(height: 13),
          Text(tutor.teacherTipArabic,
              textDirection: TextDirection.rtl,
              style: TextStyle(color: scheme.onSurface,
                  height: 1.7)),
        ],
      )),
      const SizedBox(height: 22),
      Text(_ar ? 'اسأل نفسك: هل فهمت القاعدة؟'
                  : 'Quick understanding check',
        style: TextStyle(color: _accent,
            fontWeight: FontWeight.w900, fontSize: 21)),
      const SizedBox(height: 7),
      Text(_ar
          ? 'حل 3 أسئلة مع شرح التصحيح، ثم أكمل إلى المفردات.'
          : 'Answer 3 questions with feedback, then move to vocabulary.',
        style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5)),
      const SizedBox(height: 15),
      if (_tutorGrammarPassed)
        _panel(child: Row(children: [
          const Icon(Icons.check_circle_rounded, color: _lessonGreen),
          const SizedBox(width: 10),
          Expanded(child: Text(_ar
              ? 'أحسنت! أتقنت مراجعة القاعدة. تابع إلى المفردات.'
              : 'Great work! Now continue to vocabulary.',
              style: TextStyle(color: scheme.onSurface,
                  fontWeight: FontWeight.w700))),
        ]))
      else
        _panel(child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(_ar ? 'السؤال ${_tutorQuestionIndex + 1} من 3'
                      : 'Question ${_tutorQuestionIndex + 1} of 3',
            style: TextStyle(color: _accent,
                fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Text(check.prompt, textDirection: TextDirection.ltr,
            style: TextStyle(color: scheme.onSurface, fontSize: 19,
                fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          for (var i = 0; i < check.options.length; i++)
            Padding(padding: const EdgeInsets.only(bottom: 9),
              child: OutlinedButton(
                onPressed: isCorrect ? null : () => setState(() {
                  _tutorChoice = i;
                  _tutorChecked = false;
                }),
                style: OutlinedButton.styleFrom(
                  backgroundColor: _tutorChoice == i
                      ? scheme.primaryContainer : scheme.surface,
                  minimumSize: const Size.fromHeight(56),
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(check.options[i],
                    textDirection: TextDirection.ltr,
                    style: TextStyle(color: scheme.onSurface,
                        fontSize: 16)),
                ),
              ),
            ),
          if (_tutorChecked) ...[
            const SizedBox(height: 8),
            Text(isCorrect
                ? (_ar ? 'إجابة صحيحة! ممتاز.' : 'Correct. Well done!')
                : (_ar ? 'هذه ليست الإجابة الصحيحة. جرّب مرة أخرى.'
                        : 'Not quite. Try again.'),
              style: TextStyle(color: isCorrect
                  ? _accent : scheme.error, fontWeight: FontWeight.w800)),
            const SizedBox(height: 7),
            Text(check.explanation,
              textDirection: TextDirection.ltr,
              style: TextStyle(color: scheme.onSurface,
                  fontSize: 14, height: 1.5)),
          ],
          const SizedBox(height: 15),
          FilledButton(
            key: const ValueKey('academy-tutor-check-answer'),
            onPressed: _tutorChoice == null ? null : () => setState(() {
              if (isCorrect) {
                if (_tutorQuestionIndex == tutor.checks.length - 1) {
                  _tutorGrammarPassed = true;
                } else {
                  _tutorQuestionIndex++;
                }
                _tutorChoice = null;
                _tutorChecked = false;
              } else {
                _tutorChecked = true;
              }
            }),
            style: FilledButton.styleFrom(
              backgroundColor: _lessonGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52)),
            child: Text(isCorrect
                ? (_ar ? 'السؤال التالي' : 'Next question')
                : (_ar ? 'تحقق من الإجابة' : 'Check answer')),
          ),
        ])),
    ]);
  }

  Widget _grammarPage() {
    final tutor = _tutor;
    if (tutor != null) return _tutorGrammarPage(tutor);
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
          scene: _story.scene, page: (widget.lessonNumber - 1) % 4,
          animate: false),
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

  static const _sectionIcons = <IconData>[
    Icons.menu_book_rounded,
    Icons.translate_rounded,
    Icons.auto_stories_rounded,
    Icons.fact_check_rounded,
    Icons.forum_rounded,
    Icons.record_voice_over_rounded,
    Icons.headphones_rounded,
    Icons.emoji_events_rounded,
  ];

  Widget _sectionMenu() {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      key: const ValueKey('academy-lesson-sections'),
      padding: const EdgeInsets.fromLTRB(17, 16, 17, 25),
      children: [
        Text(_ar
            ? 'الدرس ${widget.lessonNumber} · الوحدة ${widget.unit.id}'
            : 'Lesson ${widget.lessonNumber} · Unit ${widget.unit.id}',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900,
              color: _accent)),
        const SizedBox(height: 5),
        Text(_tutor != null
            ? (_ar
                ? 'مع الأستاذة إيما · المدة المقترحة 15 دقيقة. ابدأ بالقواعد، ثم تعلّم الكلمات وطبّقها في القصة والمحادثة.'
                : 'Study with tutor Emma · Suggested pace: 15 minutes. Start with grammar, then practise in stories and conversation.')
            : (_ar
                ? 'هذه أقسام الدرس. ابدأ بالقواعد ثم أكمل الأقسام بالترتيب.'
                : 'These sections belong to one lesson. Start with grammar and complete them in order.'),
          style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5)),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: _highestUnlocked / 7,
          minHeight: 7,
          borderRadius: BorderRadius.circular(9),
          color: _accent,
          backgroundColor: scheme.surfaceContainerHighest,
        ),
        const SizedBox(height: 17),
        for (var i = 0; i < _stageAr.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Material(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(17),
              child: InkWell(
                key: ValueKey('academy-section-$i'),
                onTap: i <= _highestUnlocked
                    ? () => _openSection(i) : null,
                borderRadius: BorderRadius.circular(17),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: i == _highestUnlocked
                        ? _accent.withValues(alpha: .55)
                        : scheme.outlineVariant),
                  ),
                  child: Row(children: [
                    CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      radius: 23,
                      child: Icon(_sectionIcons[i], color: _accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_ar ? _stageAr[i] : _stageEn[i],
                            style: const TextStyle(fontSize: 17,
                                fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(i == 1
                              ? (_ar ? '20 كلمة بالصوت والمعنى والنطق' :
                                  '20 words with audio, meaning and pronunciation')
                              : i == 2
                                  ? (_ar ? 'قصة قصيرة في صفحة واحدة' :
                                      'One-page illustrated reading')
                                  : _ar
                                      ? 'القسم ${i + 1} من 8'
                                      : 'Section ${i + 1} of 8',
                            style: TextStyle(fontSize: 12,
                                color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Icon(i < _highestUnlocked
                        ? Icons.check_circle_rounded
                        : i == _highestUnlocked
                            ? Icons.chevron_right_rounded
                            : Icons.lock_outline_rounded,
                        color: i < _highestUnlocked
                            ? _accent : scheme.onSurfaceVariant),
                  ]),
                ),
              ),
            ),
          ),
      ],
    );
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
      0 => _tutor == null || _tutorGrammarPassed,
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
        actions: [
          if (!_showSectionMenu)
            IconButton(
              tooltip: _ar ? 'أقسام الدرس' : 'Lesson sections',
              onPressed: () {
                _tts.stop();
                setState(() => _showSectionMenu = true);
              },
              icon: const Icon(Icons.view_list_rounded),
            ),
        ],
      ),
      body: SafeArea(child: _showSectionMenu
          ? _sectionMenu()
          : Column(children: [
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
  int? _choice;
  bool _checked = false;
  bool _translate = false;
  double _fontSize = 20;
  late final FlutterTts _tts = FlutterTts();

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

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
      if (started == 0) throw StateError('TTS did not start');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_ar
            ? 'تأكد من تثبيت صوت الإنجليزية ورفع صوت الوسائط.'
            : 'Install an English speech voice and check media volume.'),
      ));
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final night = Theme.of(context).brightness == Brightness.dark;
    final paper = night ? scheme.surfaceContainerHigh
        : const Color(0xFFFFFCF5);
    final correct = _checked && _choice == widget.question.answer;
    final paragraphs = widget.chapter.paragraphs;
    final fullText = paragraphs.map((p) => p.english).join(' ');
    return Scaffold(
      appBar: AppBar(
        title: Text(_ar ? 'قصة مصورة' : 'Illustrated story'),
        backgroundColor: _lessonGreen, foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: _ar ? 'تصغير الخط' : 'Smaller font',
            onPressed: () => setState(() =>
                _fontSize = (_fontSize - 2).clamp(16, 28).toDouble()),
            icon: const Icon(Icons.text_decrease_rounded)),
          IconButton(
            tooltip: _ar ? 'تكبير الخط' : 'Larger font',
            onPressed: () => setState(() =>
                _fontSize = (_fontSize + 2).clamp(16, 28).toDouble()),
            icon: const Icon(Icons.text_increase_rounded)),
        ],
      ),
      body: SafeArea(child: ListView(
        key: const ValueKey('academy-story-single-page'),
        padding: const EdgeInsets.fromLTRB(15, 13, 15, 26),
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: paper,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(_ar ? widget.story.titleArabic : widget.story.title,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurface,
                    fontWeight: FontWeight.w900, fontSize: 24)),
              const SizedBox(height: 6),
              Text(_ar ? widget.chapter.titleArabic : widget.chapter.title,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 15)),
              const SizedBox(height: 15),
              // Bundled vector art (one scene). No video or remote fetch.
              AcademyIllustratedStoryArt(
                scene: widget.story.scene,
                page: widget.chapterNumber,
                animate: false,
              ),
              const SizedBox(height: 18),
              for (var i = 0; i < paragraphs.length; i++) ...[
                SelectableText(
                  paragraphs[i].english,
                  key: ValueKey('academy-story-paragraph-$i'),
                  textDirection: TextDirection.ltr,
                  style: TextStyle(color: scheme.onSurface, height: 1.68,
                    fontSize: _fontSize, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 15),
              ],
              Wrap(spacing: 8, runSpacing: 7, children: [
                FilledButton.tonalIcon(
                  onPressed: () => _speak(fullText),
                  icon: const Icon(Icons.volume_up_rounded),
                  label: Text(_ar ? 'اقرأ القصة' : 'Read aloud'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _speak(fullText, slow: true),
                  icon: const Icon(Icons.slow_motion_video_rounded),
                  label: Text(_ar ? 'ببطء' : 'Slow audio'),
                ),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _translate = !_translate),
                  icon: const Icon(Icons.translate_rounded),
                  label: Text(_ar ? 'الترجمة' : 'Translation'),
                ),
              ]),
              if (_translate) ...[
                const SizedBox(height: 14),
                for (final paragraph in paragraphs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 13),
                    child: Text(paragraph.arabic,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(fontSize: _fontSize - 2, height: 1.6,
                          color: scheme.onSurface)),
                  ),
              ],
            ]),
          ),
          const SizedBox(height: 24),
          Text(_ar ? 'اختبار فهم القصة' : 'Story comprehension',
            style: const TextStyle(
              fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 10),
          Text(widget.question.question,
            textDirection: TextDirection.ltr,
            style: TextStyle(fontSize: 18, height: 1.5,
                fontWeight: FontWeight.w700, color: scheme.onSurface)),
          const SizedBox(height: 14),
          for (var i = 0; i < widget.question.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                onPressed: correct ? null : () => setState(() {
                  _choice = i; _checked = false;
                }),
                style: OutlinedButton.styleFrom(
                  alignment: AlignmentDirectional.centerStart,
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: _choice == i
                      ? scheme.primaryContainer : scheme.surface,
                ),
                child: Text(widget.question.options[i],
                  textDirection: TextDirection.ltr,
                  style: TextStyle(color: scheme.onSurface)),
              ),
            ),
          if (_checked)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(correct
                  ? (_ar ? 'ممتاز! فهمت القصة.'
                      : 'Excellent! You understood the story.')
                  : (_ar ? 'أعد القراءة وحاول مجددًا.'
                      : 'Read again and try once more.'),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: correct ? _lessonGreen : scheme.error)),
            ),
          FilledButton.icon(
            key: const ValueKey('academy-story-complete'),
            onPressed: _choice == null ? null :
                correct ? () => Navigator.of(context).pop(true)
                : () => setState(() => _checked = true),
            icon: Icon(correct
                ? Icons.check_circle_rounded : Icons.task_alt_rounded),
            label: Text(correct
                ? (_ar ? 'إكمال القصة' : 'Finish story')
                : (_ar ? 'تحقق من الإجابة' : 'Check answer')),
            style: FilledButton.styleFrom(
              backgroundColor: _lessonGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(54),
            ),
          ),
          const SizedBox(height: 14),
          Text('WORLDVOICE · STORYBOOK',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant,
                letterSpacing: 1.1, fontSize: 11)),
        ],
      )),
    );
  }
}
