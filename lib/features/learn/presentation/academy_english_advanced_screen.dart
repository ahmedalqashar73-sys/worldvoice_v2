import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/academy_english_advanced_models.dart';
import '../data/academy_advanced_grammar_workshops.dart';

const _green = Color(0xFF135941);
const _gold = Color(0xFFF2C678);

/// Progress is separate from A1 and from legacy Academy activity IDs.
abstract final class EnglishAdvancedProgress {
  static String _key(String? uid) =>
      'worldvoice.academy.en.advanced.v1.${uid ?? 'guest'}.done';

  static Future<Set<String>> load(String? uid) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key(uid)) ?? <String>[]).toSet();
  }

  static Future<void> complete(String? uid, EnglishAdvancedLesson lesson) async {
    if (!EnglishAdvancedSyllabus.lessons.any((item) => item.id == lesson.id)) {
      throw ArgumentError.value(lesson.id, 'id', 'Unpublished lesson');
    }
    final prefs = await SharedPreferences.getInstance();
    final completed = (prefs.getStringList(_key(uid)) ?? <String>[]).toSet()
      ..add(lesson.id);
    final saved = await prefs.setStringList(_key(uid), completed.toList()..sort());
    if (!saved) throw StateError('Lesson progress could not be saved');
  }
}

/// CEFR level entry: higher levels use the same Level → Unit → Lesson
/// hierarchy as A1. Only authored and tested units are clickable.
class AcademyEnglishAdvancedLevelScreen extends StatefulWidget {
  const AcademyEnglishAdvancedLevelScreen({required this.level, super.key});
  final String level;

  @override
  State<AcademyEnglishAdvancedLevelScreen> createState() =>
      _AcademyEnglishAdvancedLevelScreenState();
}

class _AcademyEnglishAdvancedLevelScreenState
    extends State<AcademyEnglishAdvancedLevelScreen> {
  Set<String> _done = <String>{};

  String? get _uid {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } on Exception {
      return null;
    }
  }

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final done = await EnglishAdvancedProgress.load(_uid);
    if (mounted) setState(() => _done = done);
  }

  Future<void> _open(int number) async {
    await Navigator.of(context).push<void>(MaterialPageRoute(
      builder: (_) => AcademyEnglishAdvancedPath(
          level: widget.level, unitNumber: number),
    ));
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF98E8BC) : _green;
    final units = EnglishAdvancedSyllabus.unitsForLevel(widget.level);
    final available = EnglishAdvancedSyllabus.forLevel(widget.level);
    final completed = available.where((lesson) => _done.contains(lesson.id)).length;
    return Scaffold(
      appBar: AppBar(
        title: Text(_ar
            ? 'الإنجليزية ${widget.level} · ${EnglishAdvancedSyllabus.arabicTitles[widget.level]}'
            : 'English ${widget.level}'),
        backgroundColor: _green, foregroundColor: Colors.white,
      ),
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.fromLTRB(17, 17, 17, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(colors: [
                Color(0xFF155640), Color(0xFF258F73),
              ]),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.auto_stories_rounded,
                  color: Color(0xFFFFDA8B), size: 39),
              const SizedBox(height: 11),
              Text(_ar
                  ? 'رحلتك في الإنجليزية ${widget.level}'
                  : 'Your English ${widget.level} journey',
                style: const TextStyle(color: Colors.white,
                  fontSize: 23, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(_ar
                  ? '3 وحدات · 30 درسًا مخططًا · قصص متدرجة'
                  : '3 units · 30 planned lessons · graded stories',
                style: const TextStyle(color: Color(0xFFE5F5EF), fontSize: 14)),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: completed / 30,
                minHeight: 8, borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFFFD68E),
                backgroundColor: Colors.white24),
              const SizedBox(height: 8),
              Text('$completed / 30',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(height: 11),
          Text(_ar
              ? '${available.length} دروس منشورة حاليًا. بقية الدروس لا تزال قيد التأليف. التقدم محفوظ على هذا الجهاز.'
              : '${available.length} lessons available so far. Others are being authored. Progress is stored on this device.',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 19),
          Text(_ar ? 'اختر الوحدة' : 'Choose a unit',
            style: TextStyle(color: accent, fontSize: 21,
                fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          for (final unit in units)
            Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Material(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(21),
                child: InkWell(
                  key: ValueKey('advanced-unit-${unit.number}'),
                  borderRadius: BorderRadius.circular(21),
                  onTap: () => _open(unit.number),
                  child: Container(
                    padding: const EdgeInsets.all(19),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(21),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Row(children: [
                      CircleAvatar(
                        backgroundColor: scheme.primaryContainer, radius: 27,
                        child: Text('${unit.number}',
                          style: TextStyle(fontWeight: FontWeight.w900,
                            fontSize: 22, color: accent)),
                      ),
                      const SizedBox(width: 13),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_ar ? unit.titleArabic : unit.title,
                            style: const TextStyle(fontSize: 18,
                                fontWeight: FontWeight.w800)),
                          const SizedBox(height: 5),
                          Text(_ar
                              ? '${unit.publishedLessons.where((lesson) => _done.contains(lesson.id)).length} / 10 دروس'
                              : '${unit.publishedLessons.where((lesson) => _done.contains(lesson.id)).length} / 10 lessons',
                            style: TextStyle(color: scheme.onSurfaceVariant)),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: unit.publishedLessons.where(
                                (lesson) => _done.contains(lesson.id)).length / 10,
                            minHeight: 5, color: _green,
                            backgroundColor: scheme.surfaceContainerHighest),
                        ],
                      )),
                      const Icon(Icons.chevron_right_rounded),
                    ]),
                  ),
                ),
              ),
            ),
        ],
      )),
    );
  }
}

class AcademyEnglishAdvancedPath extends StatefulWidget {
  const AcademyEnglishAdvancedPath({
    required this.level, this.unitNumber = 1, super.key,
  });
  final String level;
  final int unitNumber;

  @override
  State<AcademyEnglishAdvancedPath> createState() =>
      _AcademyEnglishAdvancedPathState();
}

class _AcademyEnglishAdvancedPathState
    extends State<AcademyEnglishAdvancedPath> {
  Set<String> _done = <String>{};
  String? get _uid {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } on Exception {
      // In offline previews / tests without Firebase, use isolated guest
      // progress rather than crashing before the lesson menu can open.
      return null;
    }
  }
  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final result = await EnglishAdvancedProgress.load(_uid);
    if (mounted) setState(() => _done = result);
  }

  Future<void> _open(EnglishAdvancedLesson lesson) async {
    final passed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) =>
          AcademyEnglishAdvancedLessonScreen(lesson: lesson)),
    );
    if (passed == true) {
      await EnglishAdvancedProgress.complete(_uid, lesson);
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unit = EnglishAdvancedSyllabus.unitsForLevel(widget.level)[widget.unitNumber - 1];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _green, foregroundColor: Colors.white,
        title: Text(_ar ? 'الوحدة ${widget.unitNumber}' : 'Unit ${widget.unitNumber}'),
      ),
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(_ar ? unit.titleArabic : unit.title,
            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF98E8BC) : _green,
                fontSize: 25, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(_ar
              ? 'English ${widget.level} · الوحدة ${unit.number}'
              : 'English ${widget.level} · Unit ${unit.number}',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14)),
          const SizedBox(height: 18),
          for (var i = 1; i <= 10; i++)
            Builder(builder: (context) {
              final lesson = unit.lessonAt(i);
              final published = lesson != null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Material(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(17),
                  child: InkWell(
                    key: ValueKey('advanced-lesson-${widget.level}-${widget.unitNumber}-$i'),
                    borderRadius: BorderRadius.circular(17),
                    onTap: published ? () => _open(lesson) : null,
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          backgroundColor: published
                              ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                          child: Text('$i', style: TextStyle(
                            color: published ? _green : scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w900, fontSize: 19)),
                        ),
                        const SizedBox(width: 11),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_ar ? 'الدرس $i' : 'Lesson $i',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 18)),
                            Text(published
                                ? (_ar
                                    ? '${lesson.vocabulary.length} كلمة · قواعد · قصة · محادثة · استماع · اختبار'
                                    : '${lesson.vocabulary.length} words · grammar · story · dialogue · listening · quiz')
                                : (_ar
                                    ? 'قيد الإعداد · ${unit.plannedTopics[i - 1]}'
                                    : 'In preparation · ${unit.plannedTopics[i - 1]}'),
                              style: TextStyle(color: scheme.onSurfaceVariant,
                                fontSize: 12)),
                          ],
                        )),
                        Icon(published && _done.contains(lesson.id)
                            ? Icons.check_circle_rounded
                            : published
                                ? Icons.chevron_right_rounded : Icons.lock_outline_rounded,
                          color: published && _done.contains(lesson.id)
                              ? _green : scheme.onSurfaceVariant),
                      ]),
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: 15),
          Text(_ar
            ? 'بقية دروس المستوى لا تظهر كمكتملة قبل تأليف قصصها واختباراتها.'
            : 'Unwritten lessons are not displayed as finished or available.',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
          Text(_ar
            ? 'التقدم محفوظ محليًا لكل حساب على الجهاز.'
            : 'Progress is saved locally per account on this device.',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        ],
      )),
    );
  }
}

/// One graded long-form lesson. Comprehension, listening and typed recall
/// must pass before the lesson is marked complete.
class AcademyEnglishAdvancedLessonScreen extends StatefulWidget {
  const AcademyEnglishAdvancedLessonScreen({required this.lesson, super.key});
  final EnglishAdvancedLesson lesson;
  @override
  State<AcademyEnglishAdvancedLessonScreen> createState() =>
      _AcademyEnglishAdvancedLessonScreenState();
}

class _AcademyEnglishAdvancedLessonScreenState
    extends State<AcademyEnglishAdvancedLessonScreen> {
  late final FlutterTts _tts = FlutterTts();
  final _typedWord = TextEditingController();
  final _writtenSentence = TextEditingController();
  int? _readChoice;
  int? _listenChoice;
  bool _readPassed = false;
  bool _grammarPassed = false;
  int? _grammarChoice;
  bool _grammarChecked = false;
  bool _listenPassed = false;
  bool _wordPassed = false;
  int _spellingStep = 0;
  bool _sentencePassed = false;
  bool _showTranscript = false;
  String? _message;
  int? _activeSection;
  int _highestUnlocked = 0;

  static const _sectionAr = <String>[
    'شرح القواعد',
    'المفردات',
    'القصة المصورة',
    'اختبار الكلمات',
    'المحادثة',
    'النطق',
    'الاستماع',
    'اكتمال الدرس',
  ];
  static const _sectionEn = <String>[
    'Grammar',
    'Vocabulary',
    'Illustrated story',
    'Word quiz',
    'Conversation',
    'Pronunciation',
    'Listening',
    'Complete',
  ];
  static const _sectionIcons = <IconData>[
    Icons.school_outlined, Icons.translate_rounded,
    Icons.auto_stories_rounded, Icons.fact_check_rounded,
    Icons.forum_rounded, Icons.record_voice_over_rounded,
    Icons.headphones_rounded, Icons.emoji_events_rounded,
  ];

  void _enterSection(int section) {
    if (section < 0 || section > _highestUnlocked) return;
    setState(() {
      _activeSection = section;
      _message = null;
    });
  }

  bool get _readyToAdvance => switch (_activeSection) {
    0 => _grammarPassed,
    3 => _readPassed && _wordPassed && _sentencePassed,
    6 => _listenPassed,
    _ => true,
  };

  void _nextSection() {
    if (_activeSection == null || !_readyToAdvance) return;
    _tts.stop();
    setState(() {
      _highestUnlocked = _highestUnlocked < _activeSection! + 1
          ? _activeSection! + 1 : _highestUnlocked;
      _activeSection = null;
      _message = null;
    });
  }

  Widget _sectionMenu() {
    final scheme = Theme.of(context).colorScheme;
    final lesson = widget.lesson;
    final accent = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF98E8BC) : _green;
    return ListView(
      key: const ValueKey('advanced-section-menu'),
      padding: const EdgeInsets.fromLTRB(17, 16, 17, 25),
      children: [
        Text(_ar
            ? 'الدرس ${lesson.number} · الوحدة ${lesson.unitNumber}'
            : 'Lesson ${lesson.number} · Unit ${lesson.unitNumber}',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900,
              color: accent)),
        const SizedBox(height: 5),
        Text(_ar
            ? 'هذه أقسام الدرس. ابدأ بالقواعد ثم أكمل الأقسام بالترتيب.'
            : 'These sections belong to one lesson. Start with grammar and complete them in order.',
          style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5)),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: _highestUnlocked / 7,
          minHeight: 7, borderRadius: BorderRadius.circular(9),
          color: accent, backgroundColor: scheme.surfaceContainerHighest,
        ),
        const SizedBox(height: 17),
        for (var index = 0; index < _sectionAr.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Material(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(17),
              child: InkWell(
                key: ValueKey('advanced-section-$index'),
                onTap: index <= _highestUnlocked
                    ? () => _enterSection(index) : null,
                borderRadius: BorderRadius.circular(17),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: index == _highestUnlocked
                        ? accent.withValues(alpha: .55)
                        : scheme.outlineVariant),
                  ),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 23, backgroundColor: scheme.primaryContainer,
                      child: Icon(_sectionIcons[index], color: accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_ar ? _sectionAr[index] : _sectionEn[index],
                          style: const TextStyle(fontSize: 17,
                              fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(index == 1
                            ? (_ar ? '${lesson.vocabulary.length} كلمة بالصوت والمعنى والنطق'
                                : '${lesson.vocabulary.length} words with audio, meaning and pronunciation')
                            : index == 2
                                ? (_ar ? 'قصة قصيرة في صفحة واحدة · ${lesson.paragraphs.length} فقرات'
                                    : 'One-page story · ${lesson.paragraphs.length} paragraphs')
                                : _ar ? 'القسم ${index + 1} من 8'
                                    : 'Section ${index + 1} of 8',
                          style: TextStyle(fontSize: 12,
                              color: scheme.onSurfaceVariant)),
                      ],
                    )),
                    Icon(index < _highestUnlocked
                        ? Icons.check_circle_rounded
                        : index == _highestUnlocked
                            ? Icons.chevron_right_rounded
                            : Icons.lock_outline_rounded,
                      color: index < _highestUnlocked
                          ? accent : scheme.onSurfaceVariant),
                  ]),
                ),
              ),
            ),
          ),
      ],
    );
  }

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void dispose() {
    _tts.stop();
    _typedWord.dispose();
    _writtenSentence.dispose();
    super.dispose();
  }

  Future<void> _play(String passage, {bool slow = false}) async {
    try {
      await _tts.stop();
      if (await _tts.isLanguageAvailable('en-US') == false) {
        throw StateError('English voice not installed');
      }
      await _tts.setLanguage('en-US');
      final rate = EnglishAdvancedSyllabus.listeningRates[widget.lesson.level]!;
      await _tts.setSpeechRate(slow ? rate * .72 : rate);
      await _tts.setVolume(1);
      final result = await _tts.speak(passage);
      if (result == 0) throw StateError('Audio unavailable');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_ar
            ? 'ثبّت صوت English (US) من إعدادات الهاتف وشغّل صوت الوسائط.'
            : 'Install an English US voice and check media volume.'),
        ));
      }
    }
  }

  Widget _section(String name, String en, Widget child, {IconData icon = Icons.book}) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(19),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(icon, color: _green),
            const SizedBox(width: 8),
            Expanded(child: Text(_ar ? name : en,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
          ]),
          const SizedBox(height: 13),
          child,
        ]),
      ),
    );
  }

  Widget _quiz({
    required String keyName,
    required String question,
    required List<String> answers,
    required int correct,
    required int? selected,
    required bool passed,
    required ValueChanged<int> onChoose,
    required VoidCallback onCheck,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(question, textDirection: TextDirection.ltr,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      for (var i = 0; i < answers.length; i++)
        Padding(padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton(
            key: ValueKey('$keyName-option-$i'),
            onPressed: passed ? null : () => onChoose(i),
            style: OutlinedButton.styleFrom(
              backgroundColor: i == selected
                  ? Theme.of(context).colorScheme.primaryContainer : null,
              minimumSize: const Size.fromHeight(52),
            ),
            child: Align(alignment: AlignmentDirectional.centerStart,
              child: Text(answers[i], textDirection: TextDirection.ltr)),
          ),
        ),
      if (passed)
        Text(_ar ? 'أحسنت، الإجابة صحيحة!' : 'Correct — well done!',
          style: const TextStyle(color: _green, fontWeight: FontWeight.bold)),
      FilledButton(
        key: ValueKey('$keyName-check'),
        onPressed: selected == null || passed ? null : onCheck,
        child: Text(_ar ? 'تحقق من الإجابة' : 'Check answer'),
      ),
    ]);
  }

  void _checkTypedWord() {
    final words = widget.lesson.spellingChallenge;
    if (_wordPassed || _spellingStep >= words.length) return;
    String normalize(String value) =>
        value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final expected = words[_spellingStep].term;
    if (normalize(_typedWord.text) != normalize(expected)) {
      setState(() => _message = _ar
          ? 'هذه ليست الكلمة الصحيحة. راجع كلمات القصة وحاول مجددًا.'
          : 'Not quite. Review the story-word list and try again.');
      return;
    }
    setState(() {
      _spellingStep++;
      _wordPassed = _spellingStep == words.length;
      _typedWord.clear();
      _message = _wordPassed
          ? (_ar ? 'أحسنت! كتبت الكلمات الثلاث من القصة بشكل صحيح.'
              : 'Excellent! You spelled all three story words correctly.')
          : (_ar ? 'ممتاز! ننتقل إلى الكلمة التالية.'
              : 'Great! Now try the next story word.');
    });
  }

  void _checkSentence() {
    final text = _writtenSentence.text.trim().toLowerCase();
    final count = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    final minWords = switch (widget.lesson.level) {
      'A2' => 6, 'B1' => 10, 'B2' => 14, 'C1' => 18, _ => 24,
    };
    final usesTerm = widget.lesson.storyWords.any((word) =>
        text.contains(word.term.toLowerCase()));
    setState(() {
      _sentencePassed = count >= minWords && usesTerm;
      _message = _sentencePassed
        ? (_ar
          ? 'سُجّل تدريبك الكتابي. هذا فحص للطول والمفردات فقط وليس تصحيحًا نحويًا تلقائيًا.'
          : 'Writing recorded. Only length and vocabulary were checked, not grammar.')
        : (_ar
          ? 'اكتب $minWords كلمات على الأقل بالإنجليزية واستخدم كلمة من القصة.'
          : 'Write at least $minWords English words and use a story word.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final dialogue = EnglishAdvancedDialogues.forLesson(lesson);
    final workshop = AdvancedGrammarWorkshops.forLesson(lesson.level, lesson.number);
    final scheme = Theme.of(context).colorScheme;
    final canFinish = _readPassed && _listenPassed && _wordPassed && _sentencePassed;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _green, foregroundColor: Colors.white,
        title: Text('English ${lesson.level} · ${_ar ? 'الدرس' : 'Lesson'} ${lesson.number}'),
        actions: [
          IconButton(
            key: const ValueKey('advanced-back-to-sections'),
            tooltip: _ar ? 'أقسام الدرس' : 'Lesson sections',
            onPressed: _activeSection == null ? null : () {
              _tts.stop();
              setState(() => _activeSection = null);
            },
            icon: const Icon(Icons.view_list_rounded),
          ),
        ],
      ),
      body: SafeArea(child: _activeSection == null
          ? _sectionMenu()
          : ListView(
        key: const ValueKey('advanced-lesson-body'),
        padding: const EdgeInsets.fromLTRB(15, 18, 15, 30),
        children: [
          Text(_ar ? lesson.titleArabic : lesson.title,
            style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(_ar
            ? '${lesson.paragraphs.length} فقرات · ${lesson.vocabulary.length} كلمة جديدة · استماع متدرج'
            : '${lesson.paragraphs.length} paragraphs · ${lesson.vocabulary.length} new words · graded listening',
            style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 17),
          if (_activeSection == 0) _section('شرح القاعدة', 'Grammar with examples',
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(lesson.grammarTitle, textDirection: TextDirection.ltr,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 9),
              Text(_ar ? lesson.grammarArabic : (workshop?.explanationEnglish ?? lesson.grammarTitle),
                textDirection: _ar ? TextDirection.rtl : TextDirection.ltr,
                style: const TextStyle(height: 1.65)),
              const SizedBox(height: 12),
              Row(children: [
                const CircleAvatar(backgroundColor: Color(0xFFD6EBDF),
                  child: Icon(Icons.face_3_rounded, color: _green)),
                const SizedBox(width: 9),
                Expanded(child: Text(_ar ? 'الأستاذة إيما · شرح وتطبيق'
                    : 'Tutor Emma · Guided explanation',
                  style: const TextStyle(fontWeight: FontWeight.w900))),
              ]),
              const SizedBox(height: 14),
              for (final example in lesson.grammarExamples)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(example, textDirection: TextDirection.ltr),
                  trailing: IconButton(
                    icon: const Icon(Icons.volume_up_rounded),
                    onPressed: () => _play(example)),
                ),
              if (workshop != null) ...[
                const SizedBox(height: 9),
                for (var i = 0; i < workshop.examples.length; i++)
                  Padding(padding: const EdgeInsets.only(bottom: 11),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          Expanded(child: SelectableText(workshop.examples[i].english,
                            key: ValueKey('advanced-grammar-example-$i'),
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(fontSize: 17,
                                fontWeight: FontWeight.w700))),
                          IconButton(
                            icon: const Icon(Icons.volume_up_rounded),
                            onPressed: () => _play(workshop.examples[i].english)),
                        ]),
                        if (_ar) Text(workshop.examples[i].arabic,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                      ])),
                const SizedBox(height: 14),
                Text(_ar ? 'خطأ شائع وتصحيحه' : 'Common mistake and correction',
                  style: const TextStyle(fontSize: 17,
                      fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(workshop.wrong, textDirection: TextDirection.ltr,
                  style: TextStyle(color: scheme.error, fontSize: 16)),
                const SizedBox(height: 7),
                Text(workshop.correct, textDirection: TextDirection.ltr,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 18),
                Text(_ar ? 'اختبر فهمك' : 'Check your understanding',
                  style: const TextStyle(fontSize: 18,
                      fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(workshop.question, textDirection: TextDirection.ltr),
                const SizedBox(height: 10),
                for (var i = 0; i < workshop.options.length; i++)
                  Padding(padding: const EdgeInsets.only(bottom: 7),
                    child: OutlinedButton(
                      key: ValueKey('advanced-grammar-option-$i'),
                      onPressed: _grammarPassed ? null : () => setState(() {
                        _grammarChoice = i; _grammarChecked = false;
                      }),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _grammarChoice == i
                            ? scheme.primaryContainer : null,
                        minimumSize: const Size.fromHeight(50)),
                      child: Align(alignment: AlignmentDirectional.centerStart,
                        child: Text(workshop.options[i],
                          textDirection: TextDirection.ltr)),
                    )),
                if (_grammarChecked)
                  Text(_grammarPassed
                      ? (_ar ? 'صحيح، يمكنك المتابعة.' : 'Correct. You may continue.')
                      : (_ar ? 'راجع القاعدة وحاول مجددًا.'
                          : 'Review the rule and try again.'),
                    style: TextStyle(color: _grammarPassed
                        ? _green : scheme.error)),
                const SizedBox(height: 9),
                FilledButton(
                  key: const ValueKey('advanced-grammar-check'),
                  onPressed: _grammarChoice == null || _grammarPassed
                      ? null : () => setState(() {
                          _grammarChecked = true;
                          if (_grammarChoice == workshop.answer) _grammarPassed = true;
                        }),
                  child: Text(_ar ? 'تحقق من الإجابة' : 'Check grammar answer'),
                ),
              ],
            ]), icon: Icons.school_outlined),
          if (_activeSection == 2) _section('قصة المستوى · ${lesson.paragraphs.length} فقرات',
              'Graded story · ${lesson.paragraphs.length} paragraphs',
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                key: const ValueKey('advanced-story-cover'),
                padding: const EdgeInsets.symmetric(vertical: 21, horizontal: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF155740), Color(0xFF2F9874)])),
                child: Column(children: [
                  const Icon(Icons.auto_stories_rounded, color: _gold, size: 52),
                  const SizedBox(height: 8),
                  Text(_ar ? lesson.storyTitleArabic : lesson.storyTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white,
                      fontSize: 21, fontWeight: FontWeight.w900)),
                ]),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < lesson.paragraphs.length; i++) ...[
                SelectableText(lesson.paragraphs[i],
                  key: ValueKey('advanced-paragraph-$i'),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(height: 1.75, fontSize: 18)),
                const SizedBox(height: 15),
              ],
              Wrap(spacing: 8, runSpacing: 8, children: [
                FilledButton.tonalIcon(
                  onPressed: () => _play(lesson.paragraphs.join(' ')),
                  icon: const Icon(Icons.volume_up_rounded),
                  label: Text(_ar ? 'استمع للقصة' : 'Hear story'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _play(lesson.paragraphs.join(' '), slow: true),
                  icon: const Icon(Icons.slow_motion_video_rounded),
                  label: Text(_ar ? 'ببطء' : 'Slow'),
                ),
              ]),
            ]), icon: Icons.auto_stories_rounded),
          if (_activeSection == 2) _section('الكلمات الجديدة داخل القصة', 'New words from this story',
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final word in lesson.storyWords)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(word.term, textDirection: TextDirection.ltr,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(word.arabic, textDirection: TextDirection.rtl),
                  trailing: IconButton(
                    icon: const Icon(Icons.volume_up_rounded),
                    onPressed: () => _play(word.term)),
                ),
            ]), icon: Icons.bookmark_add_outlined),
          if (_activeSection == 1) _section('مفردات إضافية للدرس', 'Additional lesson vocabulary',
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final word in lesson.vocabulary)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(word.term, textDirection: TextDirection.ltr),
                  subtitle: Text(word.arabic, textDirection: TextDirection.rtl),
                  trailing: IconButton(
                    icon: const Icon(Icons.volume_up_rounded),
                    onPressed: () => _play(word.term)),
                ),
            ]), icon: Icons.translate_rounded),
          if (_activeSection == 4) _section(
            'محادثة تفاعلية', 'Guided conversation',
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(_ar
                  ? 'استمع للحوار بين شخصين، ثم حاول أداء أحد الدورين بنفسك.'
                  : 'Listen to the two speakers and try taking one role yourself.',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 10),
              for (var line = 0; line < dialogue.lines.length; line++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Card(
                    color: line.isEven
                        ? scheme.primaryContainer : scheme.surfaceContainerHigh,
                    child: ListTile(
                      title: Text(dialogue.lines[line],
                        textDirection: TextDirection.ltr),
                      trailing: IconButton(
                        tooltip: _ar ? 'اسمع الجملة' : 'Hear sentence',
                        onPressed: () => _play(dialogue.lines[line]),
                        icon: const Icon(Icons.volume_up_rounded)),
                    ),
                  ),
                ),
              FilledButton.tonalIcon(
                onPressed: () => _play(dialogue.lines.join(' ')),
                icon: const Icon(Icons.record_voice_over_rounded),
                label: Text(_ar ? 'استمع للحوار كاملًا' : 'Hear full dialogue'),
              ),
            ]), icon: Icons.forum_rounded),
          if (_activeSection == 5) _section(
            'تدريب النطق الإنجليزي', 'English pronunciation practice',
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(_ar ? dialogue.tipArabic : dialogue.tip,
                style: const TextStyle(height: 1.55)),
              const SizedBox(height: 12),
              Text(_ar
                ? 'استمع للنطق الإنجليزي ورموز IPA، ثم انطق بنفسك وقلّد الصوت.'
                : 'Listen to English audio and IPA cues. Speak aloud and imitate the sounds.',
                style: TextStyle(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 9),
              for (final cue in dialogue.pronunciation)
                ListTile(
                  title: Text(cue, textDirection: TextDirection.ltr,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                  trailing: IconButton(
                    icon: const Icon(Icons.volume_up_rounded),
                    onPressed: () => _play(cue.split(' /').first),
                  ),
                ),
              const SizedBox(height: 8),
              Text(_ar
                  ? 'هذا تدريب استماع وتكرار؛ تقييم النطق بالميكروفون لم يُفعّل بعد.'
                  : 'This is listen-and-repeat practice. Automatic microphone scoring is not enabled.',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ]), icon: Icons.record_voice_over_rounded),
          if (_activeSection == 3) _section('اختبار فهم القصة', 'Story comprehension',
            _quiz(
              keyName: 'advanced-reading',
              question: lesson.readingQuestion, answers: lesson.readingOptions,
              correct: lesson.readingAnswer, selected: _readChoice,
              passed: _readPassed,
              onChoose: (v) => setState(() => _readChoice = v),
              onCheck: () => setState(() {
                _readPassed = _readChoice == lesson.readingAnswer;
                if (!_readPassed) _message = _ar ? 'راجع القصة وجرب مرة ثانية.' : 'Read again and retry.';
              }),
            ), icon: Icons.fact_check_rounded),
          if (_activeSection == 6) _section('استماع أصعب بحسب المستوى', 'Graded listening challenge',
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(_ar
                ? 'استمع أولًا دون نص، ثم أجب. سرعة القراءة والمحتوى يتدرجان حسب المستوى.'
                : 'Listen without a transcript first, then answer. Pace and content are graded.',
                style: TextStyle(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 7, children: [
                FilledButton.tonalIcon(
                  key: const ValueKey('advanced-listening-play'),
                  onPressed: () => _play(lesson.listening),
                  icon: const Icon(Icons.headphones_rounded),
                  label: Text(_ar ? 'استمع' : 'Listen'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _play(lesson.listening, slow: true),
                  icon: const Icon(Icons.slow_motion_video_rounded),
                  label: Text(_ar ? 'ببطء' : 'Slow'),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _showTranscript = !_showTranscript),
                  icon: const Icon(Icons.subject_rounded),
                  label: Text(_ar ? 'النص' : 'Transcript'),
                ),
              ]),
              if (_showTranscript)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: SelectableText(lesson.listening,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(height: 1.6))),
              const SizedBox(height: 14),
              _quiz(
                keyName: 'advanced-listening', question: lesson.listeningQuestion,
                answers: lesson.listeningOptions,
                correct: lesson.listeningAnswer,
                selected: _listenChoice, passed: _listenPassed,
                onChoose: (v) => setState(() => _listenChoice = v),
                onCheck: () => setState(() {
                  _listenPassed = _listenChoice == lesson.listeningAnswer;
                  if (!_listenPassed) _message = _ar ? 'اسمع المقطع مرة أخرى.' : 'Listen again.';
                }),
              ),
            ]), icon: Icons.headphones_rounded),
          if (_activeSection == 3) _section('اختبار كتابة كلمات القصة', 'Story spelling challenge',
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(_ar
                  ? 'اكتب 3 كلمات مختلفة من القصة، واحدة في كل مرة. راجع القائمة الكاملة أعلاه إذا احتجت.'
                  : 'Type three different story words, one at a time. Review the full word list above when needed.',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 9),
              Text(_wordPassed
                  ? (_ar ? '3 / 3 كلمات صحيحة ✓' : '3 / 3 words correct ✓')
                  : '${_spellingStep + 1} / ${lesson.spellingChallenge.length}',
                  key: const ValueKey('advanced-spelling-progress'),
                  style: const TextStyle(
                    color: _green, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              if (_wordPassed)
                Text(_ar ? 'أتممت اختبار كلمات القصة.'
                    : 'You completed the story-word challenge.')
              else ...[
                Text(_spellingStep == 0
                    ? lesson.writingCue
                    : (_ar
                        ? 'اكتب الكلمة الإنجليزية التي تعني: ${lesson.spellingChallenge[_spellingStep].arabic}'
                        : 'Type the English word for: ${lesson.spellingChallenge[_spellingStep].arabic}'),
                    textDirection: _spellingStep == 0
                        ? TextDirection.ltr : null),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey('advanced-write-word'),
                  controller: _typedWord,
                  textDirection: TextDirection.ltr,
                  autocorrect: false,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: _ar ? 'اكتب الكلمة بالإنجليزية' : 'Type the English word'),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  key: const ValueKey('advanced-check-word'),
                  onPressed: _checkTypedWord,
                  child: Text(_ar ? 'تحقق من الكلمة' : 'Check spelling')),
              ],
              const SizedBox(height: 16),
              Text(_ar
                ? 'اكتب جملة أو فقرة قصيرة مستخدمًا كلمة جديدة على الأقل من القصة.'
                : 'Write your own sentence or paragraph using at least one story word.'),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('advanced-write-sentence'),
                controller: _writtenSentence,
                textDirection: TextDirection.ltr,
                minLines: 3, maxLines: 6,
                onChanged: (_) => setState(() => _sentencePassed = false),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: _ar ? 'اكتب إجابتك بالإنجليزية...' : 'Write in English...'),
              ),
              const SizedBox(height: 9),
              OutlinedButton(
                key: const ValueKey('advanced-check-sentence'),
                onPressed: _checkSentence,
                child: Text(_ar ? 'مراجعة تدريب الكتابة' : 'Check writing exercise')),
            ]), icon: Icons.edit_note_rounded),
          if (_activeSection == 3 && _message != null)
            Padding(padding: const EdgeInsets.only(bottom: 16),
              child: Text(_message!, style: TextStyle(
                color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700))),
          if (_activeSection != null && _activeSection! < 7)
            FilledButton.icon(
              key: const ValueKey('advanced-section-next'),
              onPressed: _readyToAdvance ? _nextSection : null,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(_ar ? 'إكمال القسم والعودة للأقسام'
                  : 'Complete section and return to menu'),
              style: FilledButton.styleFrom(
                backgroundColor: _green, foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54)),
            ),
          if (_activeSection == 7) FilledButton.icon(
            key: const ValueKey('advanced-finish'),
            onPressed: canFinish ? () => Navigator.of(context).pop(true) : null,
            icon: const Icon(Icons.check_circle_rounded),
            label: Text(_ar ? 'إنهاء الدرس وحفظ التقدم' : 'Finish and save lesson'),
            style: FilledButton.styleFrom(
              backgroundColor: _green, foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(58)),
          ),
        ],
      )),
    );
  }
}
