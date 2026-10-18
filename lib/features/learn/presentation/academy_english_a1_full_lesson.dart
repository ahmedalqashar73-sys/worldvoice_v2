import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../data/academy_english_a1_catalog.dart';
import '../data/academy_english_a1_vocabulary.dart';
import '../data/academy_english_a1_long_stories.dart';
import 'academy_english_a1_book_reader.dart';

const _green = Color(0xFF185843);
const _gold = Color(0xFFEDC783);

/// An actual lesson is an entire sequence, not a single card or one question.
/// Each of the 36 sessions includes 20 curated words, contextual speech,
/// grammar, pronunciation, listening, graded reading, and review.
class AcademyEnglishA1FullLesson extends StatefulWidget {
  const AcademyEnglishA1FullLesson({
    required this.unit,
    required this.lesson,
    required this.index,
    super.key,
  });
  final EnglishA1Unit unit;
  final EnglishA1Lesson lesson;
  final int index;

  @override
  State<AcademyEnglishA1FullLesson> createState() =>
      _AcademyEnglishA1FullLessonState();
}

class _AcademyEnglishA1FullLessonState
    extends State<AcademyEnglishA1FullLesson> {
  final FlutterTts _tts = FlutterTts();
  final Set<int> _heard = <int>{};
  int _step = 0;
  int _question = 0;
  int? _selected;
  bool _incorrect = false;
  bool _storyPassed = false;
  bool _showTranscript = false;

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';
  Color get _accent => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF9DECC4) : _green;
  List<EnglishA1Term> get _words =>
      EnglishA1Vocabulary.forLesson(widget.unit.id, widget.index + 1);
  EnglishA1Story get _story =>
      EnglishA1LongStories.forLesson(widget.unit.id, widget.index + 1);
  List<String> get _steps => _ar
      ? ['التمهيد', '20 مفردة', 'محادثة', 'قاعدة', 'نطق',
          'استماع', 'قصة مصورة', 'اختبار']
      : ['Introduction', '20 words', 'Dialogue', 'Grammar',
          'Pronunciation', 'Listening', 'Story', 'Quiz'];

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _speak(String text, {bool slow = false}) async {
    try {
      await _tts.stop();
      if (!mounted) return;
      final ok = await _tts.isLanguageAvailable('en-US');
      if (ok == false) throw StateError('English voice unavailable');
      await _tts.setLanguage('en-US');
      await _tts.setVolume(1);
      await _tts.setSpeechRate(slow ? .30 : .50);
      final result = await _tts.speak(text);
      if (result == 0) throw StateError('TTS playback failed');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_ar
            ? 'تعذّر تشغيل الصوت؛ ثبّت صوت الإنجليزية من إعدادات هاتفك.'
            : 'English speech unavailable. Install the voice in device settings.'),
      ));
    }
  }

  Future<void> _openStory() async {
    final finished = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AcademyEnglishA1BookReader(story: _story),
      ),
    );
    if (finished == true && mounted) {
      setState(() => _storyPassed = true);
    }
  }

  void _next() {
    if (_step == 1 && _heard.length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_ar
            ? 'اضغط على جميع المفردات العشرين لمراجعتها أولًا.'
            : 'Review all twenty vocabulary words first.'),
      ));
      return;
    }
    if (_step == 6 && !_storyPassed) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_ar
            ? 'اقرأ القصة وأجب عن سؤال الفهم قبل المتابعة.'
            : 'Read the story and pass its comprehension question first.'),
      ));
      return;
    }
    if (_step < 7) {
      _tts.stop();
      setState(() {
        _step++;
        _selected = null;
        _incorrect = false;
      });
    }
  }

  String get _grammar => switch (widget.unit.id) {
    1 => 'I am Sara. You are my friend. This is my book. '
         'That is your notebook. Say “I am”, but “You are”.',
    2 => 'I wake up at seven. She wakes up at eight. '
         'We study every day. He studies on Monday. '
         'Use the simple present to talk about habits.',
    _ => 'There is one shop. There are two shops. '
         'Go straight, then turn left. '
         'Use “there is” for one and “there are” for many.',
  };

  String get _grammarArabic => switch (widget.unit.id) {
    1 => 'استخدم am مع I وare مع you. تشير this إلى القريب وthat إلى البعيد.',
    2 => 'المضارع البسيط للعادات اليومية. نضيف غالبًا s للفعل مع he وshe.',
    _ => 'نستخدم there is للمفرد وthere are للجمع. واتبع go straight وturn left للاتجاهات.',
  };

  List<(String, List<String>, int)> get _questions {
    final terms = _words;
    final i = (widget.index * 3 + 2) % 20;
    final j = (widget.index * 7 + 8) % 20;
    return [
      (widget.lesson.question, widget.lesson.options, widget.lesson.answer),
      ('What does "${terms[i].english}" mean?',
        [terms[(i + 1) % 20].arabic,
          terms[i].arabic, terms[(i + 2) % 20].arabic], 1),
      ('Which English word means "${terms[j].arabic}"?',
        [terms[j].english,
          terms[(j + 1) % 20].english, terms[(j + 2) % 20].english], 0),
    ];
  }

  void _submit() {
    if (_selected == null) return;
    if (_selected != _questions[_question].$3) {
      setState(() => _incorrect = true);
      return;
    }
    if (_question == _questions.length - 1) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _question++;
      _selected = null;
      _incorrect = false;
    });
  }

  Widget _panel(Widget child, ColorScheme scheme) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(19),
      color: scheme.surfaceContainerLow,
      border: Border.all(color: scheme.outlineVariant),
    ),
    child: child,
  );

  Widget _header(ColorScheme scheme, String title, String explanation) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: _accent,
            fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(explanation, style: TextStyle(
          color: scheme.onSurfaceVariant, fontSize: 15, height: 1.55)),
        const SizedBox(height: 20),
      ]);

  Widget _introduction(ColorScheme scheme) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _header(scheme, _ar ? 'رحلة اليوم' : 'Today’s journey',
          _ar ? 'تعلّم 20 مفردة، ثم محادثة وقاعدة ونطق واستماع وقصة، واختتم باختبار.'
              : 'Learn twenty words, converse, practice grammar and sound, read a story and pass a quiz.'),
        _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.lesson.title, textDirection: TextDirection.ltr,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
          const SizedBox(height: 12),
          Text(widget.lesson.arabic, textDirection: TextDirection.rtl,
            style: TextStyle(color: scheme.onSurface,
                fontSize: 17, height: 1.5)),
          const SizedBox(height: 16),
          Text(_ar ? 'قصة الدرس: ${_story.titleAr}'
                  : 'Connected story: ${_story.title}',
            style: TextStyle(color: _accent, fontWeight: FontWeight.w800)),
        ]), scheme),
      ]);

  Widget _vocabulary(ColorScheme scheme) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _header(scheme, _ar ? '20 مفردة في هذا الدرس' : 'Your twenty words',
        _ar ? 'اضغط على كل كلمة لسماعها، ثم راجع معناها. الكلمات تعود لاحقًا في اختبار الدرس.'
            : 'Tap every word to hear it. You will recall some of them in the final quiz.'),
      LinearProgressIndicator(
        value: _heard.length / 20, minHeight: 7,
        color: _green, backgroundColor: scheme.surfaceContainerHighest),
      const SizedBox(height: 9),
      Text(_ar ? 'راجعت ${_heard.length} من 20' : '${_heard.length} / 20 reviewed'),
      const SizedBox(height: 15),
      for (var i = 0; i < _words.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Material(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              key: ValueKey('academy-word-$i'),
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() => _heard.add(i));
                _speak(_words[i].english);
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_words[i].english, textDirection: TextDirection.ltr,
                        style: TextStyle(color: scheme.onSurface,
                            fontSize: 20, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(_words[i].arabic, textDirection: TextDirection.rtl,
                        style: TextStyle(color: scheme.onSurfaceVariant,
                            fontSize: 16)),
                    ],
                  )),
                  Icon(_heard.contains(i)
                      ? Icons.check_circle_rounded : Icons.volume_up_rounded,
                    color: _accent),
                ]),
              ),
            ),
          ),
        ),
    ],
  );

  Widget _dialogue(ColorScheme scheme) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _header(scheme, _ar ? 'محادثة هذا الدرس' : 'Conversation',
        _ar ? 'استمع واقرأ الكلمات داخل موقف حقيقي، ثم ردد الجمل.'
            : 'Listen to a real-life example and repeat the words.'),
      _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(backgroundColor: scheme.primaryContainer,
            child: Icon(Icons.record_voice_over_rounded, color: _accent)),
          const SizedBox(width: 9),
          Text(_ar ? 'محادثة قصيرة' : 'Short dialogue',
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 15),
        Text(widget.lesson.teaching, textDirection: TextDirection.ltr,
          style: TextStyle(color: scheme.onSurface,
              height: 1.6, fontSize: 21)),
        const SizedBox(height: 14),
        FilledButton.tonalIcon(
          onPressed: () => _speak(widget.lesson.spoken),
          icon: const Icon(Icons.volume_up_rounded),
          label: Text(_ar ? 'استمع وكرر' : 'Listen and repeat'),
        ),
      ]), scheme),
      const SizedBox(height: 15),
      _panel(Text(_ar
          ? 'المهمة: تخيل أنك تتحدث مع صديق جديد. أعد جملة من المحادثة بصوتك.'
          : 'Task: imagine meeting a friend. Repeat one sentence from the dialogue.',
        style: TextStyle(color: scheme.onSurface, fontSize: 17)), scheme),
    ]);

  Widget _grammarSection(ColorScheme scheme) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _header(scheme, _ar ? 'قاعدة سهلة' : 'Grammar in context',
        _ar ? 'اقرأ القاعدة، استمع إلى الأمثلة، ثم جرّب قول جملة مثلها.'
            : 'Read the rule and examples, then make your own sentence.'),
      _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_grammar, textDirection: TextDirection.ltr,
          style: TextStyle(color: scheme.onSurface,
              fontSize: 20, height: 1.7)),
        const SizedBox(height: 18),
        Text(_grammarArabic, textDirection: TextDirection.rtl,
          style: TextStyle(color: scheme.onSurfaceVariant,
              fontSize: 17, height: 1.6)),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => _speak(_grammar),
          icon: const Icon(Icons.volume_up_rounded),
          label: Text(_ar ? 'استمع للأمثلة' : 'Listen to examples'),
        ),
      ]), scheme),
    ]);

  Widget _pronunciation(ColorScheme scheme) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _header(scheme, _ar ? 'النطق والتكرار' : 'Pronunciation',
        _ar ? 'استمع للكلمات الصعبة ببطء وكررها. هذا تدريب ذاتي وليس تقييمًا آليًا.'
            : 'Play the words slowly and repeat them. This is self-practice, not automated scoring.'),
      for (final term in _words.take(10))
        Padding(padding: const EdgeInsets.only(bottom: 9),
          child: _panel(Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(term.english, style: TextStyle(color: scheme.onSurface,
                  fontWeight: FontWeight.w800, fontSize: 18)),
                Text(term.arabic,
                  style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            )),
            IconButton(
              tooltip: _ar ? 'استمع ببطء' : 'Listen slowly',
              onPressed: () => _speak(term.english, slow: true),
              icon: Icon(Icons.slow_motion_video_rounded, color: _accent),
            ),
          ]), scheme)),
      OutlinedButton.icon(
        onPressed: () => _speak(widget.lesson.spoken, slow: true),
        icon: const Icon(Icons.record_voice_over_rounded),
        label: Text(_ar ? 'ردد المثال كاملًا' : 'Shadow the full sentence'),
      ),
    ]);

  Widget _listening(ColorScheme scheme) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _header(scheme, _ar ? 'استماع وفهم' : 'Listening',
        _ar ? 'اسمع أولًا دون قراءة، ثم اكشف النص لتتحقق من فهمك.'
            : 'Listen without reading first, then reveal the transcript.'),
      _panel(Column(children: [
        Icon(Icons.headphones_rounded, size: 66, color: _accent),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () => _speak(widget.lesson.spoken),
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(_ar ? 'شغّل الاستماع' : 'Play listening'),
          style: FilledButton.styleFrom(
              backgroundColor: _green, foregroundColor: Colors.white),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => setState(() =>
              _showTranscript = !_showTranscript),
          icon: const Icon(Icons.subject_rounded),
          label: Text(_ar ? 'كشف النص' : 'Show transcript'),
        ),
        if (_showTranscript)
          Text(widget.lesson.spoken, textDirection: TextDirection.ltr,
            style: TextStyle(color: scheme.onSurface,
                fontSize: 18, height: 1.55)),
      ]), scheme),
    ]);

  Widget _storySection(ColorScheme scheme) {
    final chapter = _story.pages[widget.index % 4];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _header(scheme, _ar ? 'حكاية الدرس' : 'Storytime',
        _ar ? 'كل أربع دروس مرتبطة بقصة كاملة. اقرأ فصولها الأربعة ثم اجتز سؤال الفهم.'
            : 'Every four lessons share a graded four-paragraph story. Read it and answer the comprehension question.'),
      _panel(Column(crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_ar ? _story.titleAr : _story.title,
            style: const TextStyle(fontSize: 21,
                fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text(chapter.text, textDirection: TextDirection.ltr,
            style: TextStyle(color: scheme.onSurface,
                fontSize: 18, height: 1.55)),
          const SizedBox(height: 15),
          FilledButton.icon(
            key: const ValueKey('academy-open-full-story'),
            onPressed: _openStory,
            icon: const Icon(Icons.auto_stories_rounded),
            label: Text(_storyPassed
                ? (_ar ? 'إعادة قراءة القصة' : 'Read again')
                : (_ar ? 'افتح القصة المصورة كاملة' : 'Open illustrated story')),
            style: FilledButton.styleFrom(
                backgroundColor: _green, foregroundColor: Colors.white),
          ),
          if (_storyPassed)
            Padding(
              padding: const EdgeInsets.only(top: 11),
              child: Text(_ar ? 'أحسنت! اجتزت فهم القصة.'
                  : 'Great! Story comprehension passed.',
                style: TextStyle(color: _accent,
                    fontWeight: FontWeight.w900)),
            ),
        ]), scheme),
    ]);
  }

  Widget _quiz(ColorScheme scheme) {
    final item = _questions[_question];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _header(scheme, _ar ? 'اختبار الدرس' : 'Lesson review',
        _ar ? 'ثلاثة أسئلة تراجع المعنى ومحتوى الدرس. أجب عنها لإنهاء الدرس.'
            : 'Three short questions check understanding and vocabulary.'),
      LinearProgressIndicator(
        value: (_question + 1) / _questions.length,
        backgroundColor: scheme.surfaceContainerHighest,
        color: _green, minHeight: 7),
      const SizedBox(height: 14),
      Text(_ar ? 'السؤال ${_question + 1} من 3'
              : 'Question ${_question + 1} of 3'),
      const SizedBox(height: 17),
      Text(item.$1, textDirection: TextDirection.ltr,
        style: TextStyle(fontWeight: FontWeight.w900,
            fontSize: 20, color: scheme.onSurface)),
      const SizedBox(height: 19),
      for (var i = 0; i < item.$2.length; i++)
        Padding(padding: const EdgeInsets.only(bottom: 12),
          child: OutlinedButton(
            onPressed: () => setState(() {
              _selected = i;
              _incorrect = false;
            }),
            style: OutlinedButton.styleFrom(
              backgroundColor: i == _selected
                  ? scheme.primaryContainer : scheme.surface,
              minimumSize: const Size.fromHeight(62),
              side: BorderSide(
                  color: i == _selected ? _accent : scheme.outlineVariant)),
            child: Align(alignment: AlignmentDirectional.centerStart,
              child: Text(item.$2[i],
                style: TextStyle(color: scheme.onSurface, fontSize: 17))),
          ),
        ),
      if (_incorrect)
        Text(_ar ? 'ليست هذه الإجابة. أعد المحاولة.'
                : 'Not quite. Try another answer.',
          style: TextStyle(color: scheme.error, fontWeight: FontWeight.w800)),
      const SizedBox(height: 13),
      FilledButton(
        key: const ValueKey('academy-lesson-quiz-check'),
        onPressed: _selected == null ? null : _submit,
        style: FilledButton.styleFrom(backgroundColor: _green,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(53)),
        child: Text(_question == _questions.length - 1
            ? (_ar ? 'تحقق وأكمل الدرس' : 'Check and complete')
            : (_ar ? 'تحقق من الإجابة' : 'Check answer')),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = _steps[_step];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _green, foregroundColor: Colors.white,
        title: Text(_ar ? 'الدرس ${widget.index + 1} · $title'
            : 'Lesson ${widget.index + 1} · $title'),
      ),
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(17, 15, 17, 11),
          child: Column(children: [
            LinearProgressIndicator(
              value: (_step + 1) / _steps.length,
              minHeight: 8, borderRadius: BorderRadius.circular(8),
              backgroundColor: scheme.surfaceContainerHighest,
              color: _green),
            const SizedBox(height: 9),
            Row(children: [
              Text(_ar ? 'مرحلة ${_step + 1} من 8'
                  : 'Step ${_step + 1} of 8',
                style: TextStyle(color: scheme.onSurfaceVariant)),
              const Spacer(),
              const Icon(Icons.auto_awesome_rounded,
                  size: 16, color: _gold),
              const SizedBox(width: 5),
              Text(title, style: TextStyle(color: _accent,
                  fontWeight: FontWeight.w800)),
            ]),
          ]),
        ),
        Expanded(child: ListView(
          key: ValueKey('academy-full-lesson-step-$_step'),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
          children: [
            if (_step == 0) _introduction(scheme),
            if (_step == 1) _vocabulary(scheme),
            if (_step == 2) _dialogue(scheme),
            if (_step == 3) _grammarSection(scheme),
            if (_step == 4) _pronunciation(scheme),
            if (_step == 5) _listening(scheme),
            if (_step == 6) _storySection(scheme),
            if (_step == 7) _quiz(scheme),
          ],
        )),
        if (_step < 7)
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 8, 17, 14),
            child: Row(children: [
              if (_step > 0)
                OutlinedButton(
                  onPressed: () => setState(() => _step--),
                  child: Text(_ar ? 'السابق' : 'Back')),
              const Spacer(),
              FilledButton.icon(
                key: const ValueKey('academy-full-lesson-next'),
                onPressed: _next,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(_ar ? 'المرحلة التالية' : 'Continue'),
                style: FilledButton.styleFrom(
                  backgroundColor: _green, foregroundColor: Colors.white,
                  minimumSize: const Size(150, 53)),
              ),
            ]),
          ),
      ])),
    );
  }
}
