import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../data/academy_catalog.dart';
import '../data/academy_journey_catalog.dart';
import '../data/academy_story_catalog.dart';
import 'academy_first_conversation.dart';
import 'academy_story_reader.dart';
import '../services/academy_progress_service.dart';

const _green = Color(0xFF12523B);
const _gold = Color(0xFFF0C875);

String academyKindTitle(AcademyLessonKind kind, bool ar) => switch (kind) {
  AcademyLessonKind.vocabulary => ar ? 'المفردات' : 'Vocabulary',
  AcademyLessonKind.grammar => ar ? 'القواعد' : 'Grammar',
  AcademyLessonKind.story => ar ? 'قصص' : 'Stories',
  AcademyLessonKind.listening => ar ? 'الاستماع' : 'Listening',
  AcademyLessonKind.speaking => ar ? 'المحادثة' : 'Speaking',
  AcademyLessonKind.quiz => ar ? 'اختبار الوحدة' : 'Unit quiz',
};
IconData academyKindIcon(AcademyLessonKind kind) => switch (kind) {
  AcademyLessonKind.vocabulary => Icons.book_outlined,
  AcademyLessonKind.grammar => Icons.auto_stories_outlined,
  AcademyLessonKind.story => Icons.menu_book_rounded,
  AcademyLessonKind.listening => Icons.headphones_rounded,
  AcademyLessonKind.speaking => Icons.record_voice_over_rounded,
  AcademyLessonKind.quiz => Icons.fact_check_outlined,
};

class AcademyCourseScreen extends StatelessWidget {
  const AcademyCourseScreen({required this.course, this.progress, super.key});
  final AcademyCourse course;
  final AcademyProgressService? progress;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    final accent = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF9DECC4) : _green;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final repository = progress ?? AcademyProgressService();
    return Scaffold(
      appBar: AppBar(title: Text('${course.flag} ${course.nativeName}'),
        backgroundColor: _green, foregroundColor: Colors.white),
      body: SafeArea(child: StreamBuilder<Set<String>>(
        stream: uid == null ? Stream.value(<String>{})
            : repository.completedLessons(uid),
        builder: (context, snapshot) {
          final done = snapshot.data ?? <String>{};
          final lessonsDone = course.units.fold<int>(0, (n, unit) =>
              n + AcademyLessonKind.values.where(
                (kind) => done.contains(unit.lessonId(kind))).length);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    Color(0xFF12523B), Color(0xFF27835A)]),
                  borderRadius: BorderRadius.circular(21)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ar ? 'رحلتك في ${course.arabicName}' :
                      'Your ${course.nativeName} journey',
                    style: const TextStyle(color: Colors.white,
                      fontSize: 21, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text(ar ? 'Beginner · وحدتان · 12 درسًا' :
                      'Beginner · 2 units · 12 lessons',
                    style: const TextStyle(color: _gold)),
                  const SizedBox(height: 15),
                  LinearProgressIndicator(
                    value: lessonsDone / course.lessonCount,
                    color: _gold, minHeight: 7,
                    backgroundColor: const Color(0xFF36795A),
                    borderRadius: BorderRadius.circular(6)),
                  Align(alignment: AlignmentDirectional.centerEnd,
                    child: Text('$lessonsDone / ${course.lessonCount}',
                      style: const TextStyle(color: Colors.white))),
                ]),
              ),
              if (uid == null)
                Padding(padding: const EdgeInsets.only(top: 12),
                  child: Text(ar ? 'سجل الدخول لحفظ التقدم.'
                      : 'Sign in to save progress.',
                    style: const TextStyle(color: Color(0xFF9A692C)))),
              if (snapshot.hasError)
                Padding(padding: const EdgeInsets.only(top: 12),
                  child: Text(ar ? 'تعذّر قراءة التقدم من Firebase.'
                      : 'Unable to load progress from Firebase.',
                    style: const TextStyle(color: Colors.redAccent))),
              const SizedBox(height: 17),
              Material(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  key: const ValueKey('academy-start-dialogue'),
                  borderRadius: BorderRadius.circular(22),
                  onTap: () async {
                    final finished = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => AcademyFirstConversation(course: course),
                      ),
                    );
                    if (finished == true && context.mounted && course.units.isNotEmpty) {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => AcademyLessonScreen(
                            unit: course.units.first,
                            kind: AcademyLessonKind.vocabulary,
                            progress: repository,
                            completed: done.contains(course.units.first.lessonId(
                                AcademyLessonKind.vocabulary)),
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(19),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Row(children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.forum_rounded, color: accent, size: 28),
                      ),
                      const SizedBox(width: 13),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ar ? 'ابدأ بأول محادثة' : 'Your first conversation',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 17)),
                          const SizedBox(height: 4),
                          Text(ar
                              ? 'استمع، اختر الرد الصحيح، ثم تعلّم الكلمات.'
                              : 'Listen, choose a reply, and learn the words.',
                            style: TextStyle(color: scheme.onSurfaceVariant,
                                fontSize: 13)),
                        ],
                      )),
                      Icon(Icons.play_circle_fill_rounded,
                        color: accent, size: 31),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 21),
              for (final unit in course.units) ...[
                Text(ar ? 'الوحدة ${unit.number} · ${unit.title}' :
                    'Unit ${unit.number} · ${unit.nativeTitle}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: accent, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text(unit.nativeTitle,
                  style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 9),
                for (final kind in AcademyLessonKind.values)
                  Card(
                    color: scheme.surface, elevation: 0,
                    margin: const EdgeInsets.only(bottom: 7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: scheme.outlineVariant)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: scheme.primaryContainer,
                        child: Icon(academyKindIcon(kind), color: accent)),
                      title: Text(academyKindTitle(kind, ar),
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(ar ? 'الدرس ${kind.index + 1} من 6'
                          : 'Lesson ${kind.index + 1} of 6'),
                      trailing: Icon(done.contains(unit.lessonId(kind))
                          ? Icons.check_circle_rounded
                          : Icons.chevron_right_rounded,
                        color: done.contains(unit.lessonId(kind))
                            ? accent : scheme.onSurfaceVariant),
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(builder: (_) => AcademyLessonScreen(
                          unit: unit, kind: kind, progress: repository,
                          completed: done.contains(unit.lessonId(kind))),
                        )),
                    ),
                  ),
                const SizedBox(height: 13),
              ],
              Row(children: [
                Icon(Icons.route_rounded, color: accent),
                const SizedBox(width: 9),
                Text(ar ? 'خريطة رحلة التعلم' : 'Your learning journey',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900, color: accent)),
              ]),
              const SizedBox(height: 10),
              ...AcademyJourneyCatalog.levels.map((level) {
                final current = level.id == 'A1';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: scheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: scheme.outlineVariant),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: current
                          ? scheme.primaryContainer
                          : scheme.surfaceContainerHighest,
                      child: Text(level.id, style: TextStyle(
                        color: current ? accent : scheme.onSurfaceVariant,
                        fontSize: 13, fontWeight: FontWeight.w900)),
                    ),
                    title: Text(ar ? level.titleArabic : level.titleEnglish,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(current
                        ? (ar
                            ? '${course.units.length} وحدات متاحة حاليًا من ${level.plannedUnits} مخططة'
                            : '${course.units.length} available of ${level.plannedUnits} planned units')
                        : (ar
                            ? '${level.plannedUnits} وحدة مخططة · قيد الإعداد'
                            : '${level.plannedUnits} planned units · Coming later')),
                    trailing: Icon(current
                        ? Icons.play_circle_outline_rounded
                        : Icons.lock_outline_rounded,
                      color: current ? accent : scheme.onSurfaceVariant),
                  ),
                );
              }),
              const SizedBox(height: 20),

            ],
          );
        },
      )),
    );
  }
}

/// Lesson completion means self-study only, never XP or a verified proficiency
/// certificate. The quiz must be answered correctly before saving it.
class AcademyLessonScreen extends StatefulWidget {
  const AcademyLessonScreen({required this.unit, required this.kind,
    required this.completed, this.progress, super.key});
  final AcademyUnit unit;
  final AcademyLessonKind kind;
  final bool completed;
  final AcademyProgressService? progress;

  @override
  State<AcademyLessonScreen> createState() => _AcademyLessonScreenState();
}
class _AcademyLessonScreenState extends State<AcademyLessonScreen> {
  late final FlutterTts _tts;
  int? _chosen;
  int? _speakingWord;
  bool _checked = false, _correct = false, _saving = false;
  bool _speaking = false, _slowSpeech = false, _transcript = false;
  bool _storyPassed = false;
  late bool _complete;

  @override
  void initState() {
    super.initState();
    _complete = widget.completed;
    _tts = FlutterTts();
    _tts.setCompletionHandler(_finishSpeech);
    _tts.setCancelHandler(_finishSpeech);
    _tts.setErrorHandler((_) => _finishSpeech());
  }

  void _finishSpeech() {
    if (mounted) {
      setState(() {
        _speaking = false;
        _speakingWord = null;
      });
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  String get _speechLocale => switch (widget.unit.language) {
    'en' => 'en-US',
    'es' => 'es-ES',
    'zh' => 'zh-CN',
    'fr' => 'fr-FR',
    'ko' => 'ko-KR',
    _ => widget.unit.language,
  };
  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

  void _notice(String text) => ScaffoldMessenger.of(context)
    .showSnackBar(SnackBar(content: Text(text)));

  Future<void> _hear(String text, {int? wordIndex, bool slow = false}) async {
    // Tapping the active speed again stops playback. Tapping the other
    // speed, or another word, starts that pronunciation immediately.
    if (_speaking && _speakingWord == wordIndex && _slowSpeech == slow) {
      await _tts.stop();
      _finishSpeech();
      return;
    }
    try {
      await _tts.stop();
      if (!mounted) return;
      setState(() {
        _speaking = true;
        _speakingWord = wordIndex;
        _slowSpeech = slow;
      });
      // Never read aloud the Arabic translation: only the original term.
      await _tts.setLanguage(_speechLocale);
      await _tts.setSpeechRate(slow ? 0.30 : 0.50);
      await _tts.setPitch(1.0);
      final started = await _tts.speak(text);
      if (started == 0) {
        throw StateError('The speech engine refused the selected voice');
      }
    } catch (_) {
      if (mounted) {
        _finishSpeech();
        _notice(_ar
            ? 'تعذّر تشغيل النطق. ثبّت صوت هذه اللغة من إعدادات هاتفك.'
            : 'Could not speak. Install this language voice in your device settings.');
      }
    }
  }

  Future<void> _save() async {
    if (_saving || _complete) return;
    if (widget.kind == AcademyLessonKind.quiz && !_correct) return;
    if (widget.kind == AcademyLessonKind.story && !_storyPassed) return;
    setState(() => _saving = true);
    try {
      await (widget.progress ?? AcademyProgressService())
          .complete(widget.unit, widget.kind);
      if (!mounted) return;
      setState(() => _complete = true);
      _notice(_ar ? 'تم حفظ تقدمك!' : 'Progress saved!');
    } catch (_) {
      if (mounted) {
        _notice(_ar
            ? 'تعذّر حفظ التقدم. تأكد من تسجيل الدخول واتصال Firebase.'
            : 'Could not save progress. Check Firebase and your login.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _info(String title, String text, {bool target = false}) {
    final scheme = Theme.of(context).colorScheme;
    final accent = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF9DECC4) : _green;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w900, color: accent,
        )),
        const SizedBox(height: 9),
        Text(text,
          textDirection: target ? TextDirection.ltr : null,
          style: TextStyle(
            fontSize: 17, height: 1.55, color: scheme.onSurface,
          ),
        ),
      ]),
    );
  }

  Widget _listen(String text) => FilledButton.icon(
    onPressed: _speaking ? null : () => _hear(text),
    icon: Icon(_speaking ? Icons.hourglass_top_rounded
        : Icons.volume_up_rounded),
    label: Text(_ar ? 'استمع للنطق' : 'Listen'),
    style: FilledButton.styleFrom(
      backgroundColor: _green, foregroundColor: Colors.white),
  );

  Widget _wordCard(AcademyWord word, int index) {
    final scheme = Theme.of(context).colorScheme;
    final night = Theme.of(context).brightness == Brightness.dark;
    final emphasis = night ? const Color(0xFF9DECC4) : _green;
    final rtlTarget = const {'ar', 'fa', 'ur'}.contains(widget.unit.language);
    final playingHere = _speaking && _speakingWord == index;
    final guide = switch (widget.unit.language) {
      'zh' => _ar ? 'النطق (Pinyin)' : 'Pinyin pronunciation',
      'ko' => _ar ? 'النطق بالحروف اللاتينية' : 'Romanized pronunciation',
      _ => _ar ? 'النطق التقريبي' : 'Pronunciation guide',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: .60)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: night ? .05 : .035),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Text(
                  word.term,
                  textDirection: rtlTarget ? TextDirection.rtl : TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 27,
                    height: 1.28,
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                tooltip: _ar ? 'استمع للنطق' : 'Play pronunciation',
                onPressed: () => _hear(word.term, wordIndex: index),
                style: IconButton.styleFrom(
                  backgroundColor: emphasis.withValues(alpha: .12),
                  foregroundColor: emphasis,
                  minimumSize: const Size(49, 49),
                ),
                icon: Icon(
                  playingHere && !_slowSpeech
                      ? Icons.stop_rounded : Icons.volume_up_rounded,
                  size: 27,
                ),
              ),
            ]),
            const SizedBox(height: 11),
            Text(guide,
                style: TextStyle(color: scheme.onSurfaceVariant,
                    fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            SelectableText(
              word.pronunciation,
              textDirection: widget.unit.language == 'zh' ||
                      widget.unit.language == 'ko'
                  ? TextDirection.ltr : null,
              style: TextStyle(color: emphasis, fontSize: 19, height: 1.35,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              word.arabic,
              textDirection: TextDirection.rtl,
              style: TextStyle(color: scheme.onSurface, fontSize: 17,
                  height: 1.4, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: scheme.outlineVariant),
            const SizedBox(height: 5),
            TextButton.icon(
              onPressed: () => _hear(word.term, wordIndex: index, slow: true),
              icon: Icon(playingHere && _slowSpeech
                  ? Icons.stop_rounded : Icons.slow_motion_video_rounded),
              label: Text(_ar ? 'استمع ببطء' : 'Listen slowly'),
              style: TextButton.styleFrom(foregroundColor: emphasis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    final u = widget.unit;
    switch (widget.kind) {
      case AcademyLessonKind.vocabulary:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _ar
                  ? 'استمع للكلمة، واقرأ نطقها، ثم تعرّف على معناها.'
                  : 'Listen, read its pronunciation and learn its meaning.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < u.words.length; i++)
              _wordCard(u.words[i], i),
            const SizedBox(height: 5),
            Text(
              _ar ? 'جرّب استخدام كل كلمة في جملة.'
                  : 'Try using every word in a sentence.',
              textAlign: TextAlign.center,
            ),
          ],
        );
      case AcademyLessonKind.grammar:
        return Column(children: [
          _info(_ar ? 'شرح القاعدة' : 'Grammar note', u.grammar),
          const SizedBox(height: 12),
          _info(_ar ? 'مثال' : 'Example', u.grammarExample, target: true),
          const SizedBox(height: 10),
          _listen(u.grammarExample),
          const SizedBox(height: 10),
          _info(_ar ? 'الترجمة' : 'Arabic meaning', u.grammarTranslation),
        ]);
      case AcademyLessonKind.story:
        final story = AcademyStoryCatalog.forUnit(u);
        final scheme = Theme.of(context).colorScheme;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(23),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF124B3A), Color(0xFF23815B)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(children: [
                const Icon(Icons.auto_stories_rounded,
                  color: _gold, size: 41),
                const SizedBox(height: 18),
                Text(story.coverSymbol,
                  style: const TextStyle(fontSize: 61)),
                const SizedBox(height: 14),
                Text(story.title, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white,
                    fontSize: 23, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(story.titleArabic, textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFE4F2E6), fontSize: 16)),
                const SizedBox(height: 8),
                Text(_ar
                      ? '${story.pages.length} صفحات · قراءة واستماع'
                      : '${story.pages.length} pages · read and listen',
                  style: const TextStyle(color: _gold)),
              ]),
            ),
            const SizedBox(height: 17),
            Text(_ar
                ? 'افتح الكتاب، وانتقل بين الصفحات، واستمع إلى كل صفحة. اجتز سؤال الفهم لحفظ الدرس.'
                : 'Turn the pages, listen to the story, and answer the comprehension question to complete the lesson.',
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.6)),
            const SizedBox(height: 15),
            FilledButton.icon(
              key: const ValueKey('academy-open-storybook'),
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => AcademyStoryReader(unit: u),
                  ),
                );
                if (!mounted || result != true) return;
                setState(() => _storyPassed = true);
                _notice(_ar
                    ? 'أحسنت! اجتزت سؤال فهم القصة. احفظ التقدم الآن.'
                    : 'Excellent! You passed the story question. Save your progress.');
              },
              icon: Icon(_storyPassed
                  ? Icons.check_circle_rounded : Icons.menu_book_rounded),
              label: Text(_storyPassed
                  ? (_ar ? 'إعادة قراءة القصة' : 'Read the story again')
                  : (_ar ? 'افتح القصة واقرأها' : 'Open storybook')),
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(55)),
            ),
          ],
        );
      case AcademyLessonKind.listening:
        return Column(children: [
          Text(_ar ? 'استمع وحدد الكلمات التي تعرفها.'
            : 'Listen and identify familiar words.',
            style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 13),
          _listen(u.listening),
          TextButton.icon(
            onPressed: () => setState(() => _transcript = !_transcript),
            icon: const Icon(Icons.subject_rounded),
            label: Text(_ar ? (_transcript ? 'إخفاء النص' : 'إظهار النص')
                : (_transcript ? 'Hide transcript' : 'Show transcript')),
          ),
          if (_transcript)
            _info(_ar ? 'النص الصوتي' : 'Transcript', u.listening, target: true),
        ]);
      case AcademyLessonKind.speaking:
        return Column(children: [
          _info(_ar ? 'نموذج المحادثة' : 'Speaking example',
            u.speaking, target: true),
          const SizedBox(height: 10),
          _listen(u.speaking),
          const SizedBox(height: 10),
          _info(_ar ? 'تدريب التحدث' : 'Your practice', u.speakingHelp),
          const SizedBox(height: 9),
          Text(_ar
            ? 'ردد العبارة بصوتك؛ التدريب ذاتي وليس تقييمًا آليًا للنطق.'
            : 'Repeat aloud. This is self-practice, not scored pronunciation.',
            style: const TextStyle(color: Color(0xFF647A6B))),
        ]);
      case AcademyLessonKind.quiz:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _info(_ar ? 'السؤال' : 'Question', u.quizQuestion, target: true),
            const SizedBox(height: 12),
            for (var i = 0; i < u.quizOptions.length; i++)
              Padding(padding: const EdgeInsets.only(bottom: 7),
                child: ChoiceChip(
                  label: SizedBox(width: double.infinity,
                    child: Text(u.quizOptions[i])),
                  selected: _chosen == i,
                  onSelected: _complete ? null : (_) =>
                      setState(() { _chosen = i; _checked = false;
                        _correct = false; }),
                )),
            FilledButton(
              onPressed: _chosen == null || _complete ? null : () =>
                setState(() {
                  _checked = true;
                  _correct = _chosen == u.quizCorrectIndex;
                }),
              child: Text(_ar ? 'تحقق من الإجابة' : 'Check answer')),
            if (_checked)
              Padding(padding: const EdgeInsets.all(12),
                child: Text(_correct
                  ? (_ar ? '✅ إجابة صحيحة' : '✅ Correct')
                  : (_ar ? '❌ حاول مرة أخرى' : '❌ Try again'),
                  style: TextStyle(fontWeight: FontWeight.w800,
                    color: _correct ? _green : Colors.redAccent))),
          ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = _ar;
    return Scaffold(
      appBar: AppBar(
        title: Text(academyKindTitle(widget.kind, ar)),
        backgroundColor: _green, foregroundColor: Colors.white),
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
        children: [
          Row(children: [
            Icon(academyKindIcon(widget.kind), color: _green),
            const SizedBox(width: 10),
            Expanded(child: Text(
              '${widget.unit.nativeTitle} · ${academyKindTitle(widget.kind, ar)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF9DECC4) : _green,
                fontWeight: FontWeight.w900))),
          ]),
          const SizedBox(height: 16),
          _body(),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: _saving || _complete ||
                (widget.kind == AcademyLessonKind.quiz && !_correct) ||
                (widget.kind == AcademyLessonKind.story && !_storyPassed)
                ? null : _save,
            icon: Icon(_complete
                ? Icons.check_circle_rounded : Icons.bookmark_added_rounded),
            label: Text(_complete
                ? (ar ? 'الدرس مكتمل ومحفوظ' : 'Completed and saved')
                : _saving ? (ar ? 'جارٍ الحفظ' : 'Saving')
                : (ar ? 'إكمال الدرس وحفظ التقدم' : 'Complete and save')),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: _green, foregroundColor: Colors.white),
          ),
        ],
      )),
    );
  }
}
