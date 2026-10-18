import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/academy_english_a1_catalog.dart';
import '../data/academy_english_a1_long_stories.dart';
import 'academy_english_a1_integrated_lesson.dart';
import 'academy_illustrated_story_art.dart';

const _deepGreen = Color(0xFF145C46);
const _mint = Color(0xFF99E5BF);

/// Small-step A1 practice: 36 authored learning activities, not CEFR grading.
/// Completed lessons stay on this device, namespaced to the signed-in account.
/// Do not attempt Firestore writes against restrictive legacy six-kind rules.
abstract final class EnglishA1Progress {
  static String _key(String? uid) =>
      'worldvoice.academy.en.a1.v1.${uid ?? 'guest'}.done';

  static Future<Set<String>> load(String? uid) async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_key(uid)) ?? <String>[]).toSet();
  }

  static Future<void> complete(String? uid, String id) async {
    if (!EnglishA1Catalog.units.any((u) =>
        u.lessons.any((lesson) => lesson.id == id))) {
      throw ArgumentError.value(id, 'id', 'Unknown English A1 lesson');
    }
    final p = await SharedPreferences.getInstance();
    final known = (p.getStringList(_key(uid)) ?? <String>[]).toSet()..add(id);
    final saved = await p.setStringList(_key(uid), known.toList()..sort());
    if (!saved) throw StateError('Device could not save A1 completion.');
  }
}

IconData _lessonIcon(EnglishA1Kind kind) => switch (kind) {
  EnglishA1Kind.dialogue => Icons.forum_rounded,
  EnglishA1Kind.vocabulary => Icons.menu_book_rounded,
  EnglishA1Kind.pronunciation => Icons.mic_rounded,
  EnglishA1Kind.grammar => Icons.auto_stories_outlined,
  EnglishA1Kind.listening => Icons.headphones_rounded,
  EnglishA1Kind.story => Icons.book_rounded,
  EnglishA1Kind.practice => Icons.extension_rounded,
  EnglishA1Kind.quiz => Icons.fact_check_rounded,
};

String _label(EnglishA1Kind kind, bool ar) => switch (kind) {
  EnglishA1Kind.dialogue => ar ? 'محادثة' : 'Conversation',
  EnglishA1Kind.vocabulary => ar ? 'مفردات' : 'Vocabulary',
  EnglishA1Kind.pronunciation => ar ? 'نطق' : 'Pronunciation',
  EnglishA1Kind.grammar => ar ? 'قواعد' : 'Grammar',
  EnglishA1Kind.listening => ar ? 'استماع' : 'Listening',
  EnglishA1Kind.story => ar ? 'قصة مصورة' : 'Illustrated story',
  EnglishA1Kind.practice => ar ? 'تدريب' : 'Practice',
  EnglishA1Kind.quiz => ar ? 'اختبار' : 'Quiz',
};

class AcademyEnglishA1Path extends StatefulWidget {
  const AcademyEnglishA1Path({super.key});
  @override
  State<AcademyEnglishA1Path> createState() => _AcademyEnglishA1PathState();
}

class _AcademyEnglishA1PathState extends State<AcademyEnglishA1Path> {
  Set<String> _completed = <String>{};
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final result = await EnglishA1Progress.load(_uid);
    if (mounted) setState(() => _completed = result);
  }

  Future<void> _open(EnglishA1Unit unit) async {
    await Navigator.of(context).push<void>(MaterialPageRoute(
      builder: (_) => _EnglishA1UnitScreen(unit: unit),
    ));
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = Theme.of(context).brightness == Brightness.dark
        ? _mint : _deepGreen;
    return Scaffold(
      appBar: AppBar(
        title: Text(_ar ? 'الإنجليزية A1 · المبتدئ' : 'English A1 · Beginner'),
        backgroundColor: _deepGreen, foregroundColor: Colors.white,
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
              Text(_ar ? 'مغامرتك الأولى في الإنجليزية' : 'Your first English adventure',
                style: const TextStyle(color: Colors.white,
                    fontSize: 23, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(_ar ? '3 وحدات · 36 درسًا متكاملًا · 9 قصص طويلة مصورة'
                         : '3 units · 36 complete lessons · 9 illustrated stories',
                style: const TextStyle(color: Color(0xFFE5F5EF), fontSize: 14)),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _completed.length / EnglishA1Catalog.lessonCount,
                minHeight: 8, borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFFFD68E),
                backgroundColor: Colors.white24,
              ),
              const SizedBox(height: 8),
              Text('${_completed.length} / ${EnglishA1Catalog.lessonCount}',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(height: 11),
          Text(_ar
              ? 'هذا المسار يحفظ إنجازاتك على الجهاز فقط، وليس بعد في Firebase.'
              : 'This learning path currently stores completion on this device, not in Firebase.',
            textAlign: TextAlign.center, style: TextStyle(
                color: scheme.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 19),
          Text(_ar ? 'اختر الوحدة' : 'Choose a unit',
            style: TextStyle(color: accent, fontSize: 21,
                fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ...EnglishA1Catalog.units.map((unit) {
            final progress = unit.lessons.where((lesson) =>
                _completed.contains(lesson.id)).length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Material(
                color: scheme.surface, borderRadius: BorderRadius.circular(21),
                child: InkWell(
                  key: ValueKey('english-a1-unit-${unit.id}'),
                  borderRadius: BorderRadius.circular(21),
                  onTap: () => _open(unit),
                  child: Container(
                    padding: const EdgeInsets.all(19),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(21),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Row(children: [
                      CircleAvatar(
                        backgroundColor: scheme.primaryContainer, radius: 27,
                        child: Text('${unit.id}', style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 22,
                            color: accent)),
                      ),
                      const SizedBox(width: 13),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_ar ? unit.titleAr : unit.title,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 5),
                          Text(_ar ? '$progress / 12 درس' : '$progress / 12 lessons',
                            style: TextStyle(color: scheme.onSurfaceVariant)),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: progress / 12, minHeight: 5,
                            color: _deepGreen,
                            backgroundColor: scheme.surfaceContainerHighest,
                          ),
                        ],
                      )),
                      const Icon(Icons.chevron_right_rounded),
                    ]),
                  ),
                ),
              ),
            );
          }),
        ],
      )),
    );
  }
}

class _EnglishA1UnitScreen extends StatefulWidget {
  const _EnglishA1UnitScreen({required this.unit});
  final EnglishA1Unit unit;

  @override
  State<_EnglishA1UnitScreen> createState() => _EnglishA1UnitScreenState();
}

class _EnglishA1UnitScreenState extends State<_EnglishA1UnitScreen> {
  Set<String> _completed = {};
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final local = await EnglishA1Progress.load(_uid);
    if (mounted) setState(() => _completed = local);
  }

  Future<void> _open(EnglishA1Lesson lesson) async {
    final lessonNumber = widget.unit.lessons.indexOf(lesson) + 1;
    final passed = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => AcademyEnglishA1IntegratedLesson(
        unit: widget.unit, lesson: lesson, lessonNumber: lessonNumber,
      ),
    ));
    if (passed == true) {
      try {
        await EnglishA1Progress.complete(_uid, lesson.id);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_ar ? 'لم يتم حفظ الدرس على الجهاز.'
                : 'Could not save the lesson on this device.'),
          ));
        }
      }
    }
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = Theme.of(context).brightness == Brightness.dark
        ? _mint : _deepGreen;
    return Scaffold(
      appBar: AppBar(
        title: Text(_ar ? 'الوحدة ${widget.unit.id}' : 'Unit ${widget.unit.id}'),
        backgroundColor: _deepGreen, foregroundColor: Colors.white,
      ),
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.all(17),
        children: [
          Text(_ar ? widget.unit.titleAr : widget.unit.title,
            style: TextStyle(color: accent, fontSize: 25,
                fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(widget.unit.goal, textDirection: TextDirection.ltr,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14)),
          const SizedBox(height: 18),
          for (var i = 0; i < widget.unit.lessons.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Material(color: scheme.surface,
                borderRadius: BorderRadius.circular(17),
                child: InkWell(
                  key: ValueKey('english-a1-lesson-${widget.unit.lessons[i].id}'),
                  borderRadius: BorderRadius.circular(17),
                  onTap: () => _open(widget.unit.lessons[i]),
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Row(children: [
                      CircleAvatar(
                        backgroundColor: scheme.primaryContainer,
                        child: Icon(_lessonIcon(widget.unit.lessons[i].kind),
                            color: accent),
                      ),
                      const SizedBox(width: 11),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_ar
                              ? EnglishA1StorySyllabus.chapterFor(
                                  widget.unit.id, i + 1).titleArabic
                              : EnglishA1StorySyllabus.chapterFor(
                                  widget.unit.id, i + 1).title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                          Text(
                            _ar
                                ? 'الدرس ${i + 1} من 12 · 20 كلمة · محادثة وقصة واختبار'
                                : 'Lesson ${i + 1} of 12 · 20 words · story and practice',
                            style: TextStyle(color: scheme.onSurfaceVariant,
                                fontSize: 12)),
                        ],
                      )),
                      Icon(_completed.contains(widget.unit.lessons[i].id)
                          ? Icons.check_circle_rounded
                          : Icons.chevron_right_rounded,
                        color: _completed.contains(widget.unit.lessons[i].id)
                            ? accent : scheme.onSurfaceVariant),
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

mixin _EnglishSpeechSupport<T extends StatefulWidget> on State<T> {
  late final FlutterTts tts = FlutterTts();
  bool speaking = false;

  Future<void> speak(String text, {bool slow = false}) async {
    try {
      await tts.stop();
      if (!mounted) return;
      final available = await tts.isLanguageAvailable('en-US');
      if (available == false) throw StateError('English voice missing');
      await tts.setLanguage('en-US');
      await tts.setSpeechRate(slow ? .30 : .50);
      await tts.setVolume(1);
      setState(() => speaking = true);
      final started = await tts.speak(text);
      if (started == 0) throw StateError('Audio start failed');
    } catch (_) {
      if (!mounted) return;
      setState(() => speaking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر تشغيل الصوت. تحقق من إعدادات النطق في الهاتف.')),
      );
    }
  }

  void disposeSpeech() {
    tts.stop();
  }
}

class _EnglishA1ExerciseScreen extends StatefulWidget {
  const _EnglishA1ExerciseScreen({required this.lesson});
  final EnglishA1Lesson lesson;

  @override
  State<_EnglishA1ExerciseScreen> createState() => _EnglishA1ExerciseScreenState();
}

class _EnglishA1ExerciseScreenState extends State<_EnglishA1ExerciseScreen>
    with _EnglishSpeechSupport<_EnglishA1ExerciseScreen> {
  int? _selected;
  bool _checked = false;
  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void dispose() {
    disposeSpeech();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final scheme = Theme.of(context).colorScheme;
    final correct = _checked && _selected == lesson.answer;
    return Scaffold(
      appBar: AppBar(
        title: Text(_ar ? lesson.titleAr : lesson.title),
        backgroundColor: _deepGreen, foregroundColor: Colors.white,
      ),
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.all(19),
        children: [
          Row(children: [
            Icon(_lessonIcon(lesson.kind), color: _deepGreen),
            const SizedBox(width: 9),
            Text(_label(lesson.kind, _ar),
                style: const TextStyle(fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 17),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: scheme.surfaceContainerLow,
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(lesson.teaching, textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: scheme.onSurface, height: 1.65,
                    fontSize: 19, fontWeight: FontWeight.w700,
                  )),
                const SizedBox(height: 12),
                Text(lesson.arabic, textDirection: TextDirection.rtl,
                  style: TextStyle(color: scheme.onSurfaceVariant,
                    height: 1.5, fontSize: 15)),
                const SizedBox(height: 12),
                Wrap(spacing: 9, children: [
                  FilledButton.tonalIcon(
                    onPressed: () => speak(lesson.spoken),
                    icon: const Icon(Icons.volume_up_rounded),
                    label: Text(_ar ? 'استمع' : 'Listen'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => speak(lesson.spoken, slow: true),
                    icon: const Icon(Icons.slow_motion_video_rounded),
                    label: Text(_ar ? 'ببطء' : 'Slow'),
                  ),
                ]),
                if (lesson.kind == EnglishA1Kind.pronunciation)
                  Padding(
                    padding: const EdgeInsets.only(top: 9),
                    child: Text(_ar
                        ? 'ردد بصوتك بعد الاستماع. هذا تدريب ذاتي وليس تقييم نطق آليًا.'
                        : 'Repeat aloud. This is self-practice, not automated pronunciation scoring.',
                      style: TextStyle(color: scheme.onSurfaceVariant,
                          fontSize: 12)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(_ar ? 'سؤال التدريب' : 'Practice question',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 9),
          Text(lesson.question, textDirection: TextDirection.ltr,
              style: TextStyle(color: scheme.onSurface, fontSize: 19,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          for (var i = 0; i < lesson.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                onPressed: correct ? null : () => setState(() {
                  _selected = i; _checked = false;
                }),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                  backgroundColor: _selected == i
                      ? scheme.primaryContainer : scheme.surface,
                  side: BorderSide(color: _selected == i
                      ? _deepGreen : scheme.outlineVariant),
                ),
                child: Align(alignment: AlignmentDirectional.centerStart,
                  child: Text(lesson.options[i],
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontSize: 16, color: scheme.onSurface))),
              ),
            ),
          if (_checked)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(correct
                  ? (_ar ? 'إجابة صحيحة! ممتاز.' : 'Correct! Well done.')
                  : (_ar ? 'حاول مرة أخرى.' : 'Try again.'),
                style: TextStyle(fontWeight: FontWeight.w800,
                    color: correct ? _deepGreen : scheme.error)),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('english-a1-check'),
            onPressed: _selected == null ? null :
                correct ? () => Navigator.of(context).pop(true) :
                () => setState(() => _checked = true),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: _deepGreen, foregroundColor: Colors.white,
            ),
            icon: Icon(correct
                ? Icons.check_circle_rounded : Icons.task_alt_rounded),
            label: Text(correct
                ? (_ar ? 'إنهاء الدرس وحفظه' : 'Complete and save')
                : (_ar ? 'تحقق من الإجابة' : 'Check answer')),
          ),
        ],
      )),
    );
  }
}

class _EnglishA1IllustratedStoryReader extends StatefulWidget {
  const _EnglishA1IllustratedStoryReader({required this.story});
  final EnglishA1Story story;

  @override
  State<_EnglishA1IllustratedStoryReader> createState() =>
      _EnglishA1IllustratedStoryReaderState();
}

class _EnglishA1IllustratedStoryReaderState
    extends State<_EnglishA1IllustratedStoryReader>
    with _EnglishSpeechSupport<_EnglishA1IllustratedStoryReader> {
  int _page = 0;
  int? _answer;
  bool _checked = false;
  bool _translation = false;

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';
  bool get _quiz => _page == widget.story.pages.length;

  void _next() {
    if (_page >= widget.story.pages.length) return;
    tts.stop();
    setState(() {
      _page++;
      _translation = false;
      _answer = null;
      _checked = false;
    });
  }

  @override
  void dispose() {
    disposeSpeech();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final scheme = Theme.of(context).colorScheme;
    final correct = _checked && _answer == story.answer;
    return Scaffold(
      appBar: AppBar(
        title: Text(_ar ? story.titleAr : story.title,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: _deepGreen, foregroundColor: Colors.white,
      ),
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 12, 15, 15),
        child: Column(children: [
          LinearProgressIndicator(
            value: (_page + 1) / (story.pages.length + 1),
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
            color: _deepGreen,
            backgroundColor: scheme.surfaceContainerHighest,
          ),
          const SizedBox(height: 9),
          Expanded(child: ListView(
            key: ValueKey('english-story-page-$_page'),
            children: [
              AcademyIllustratedStoryArt(scene: story.scene, page: _page),
              const SizedBox(height: 15),
              Text(_ar ? story.titleAr : story.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 9),
              if (!_quiz) ...[
                Text(
                  _ar ? 'صفحة ${_page + 1} من ${story.pages.length}'
                      : 'Page ${_page + 1} of ${story.pages.length}',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 9),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: SelectableText(story.pages[_page].text,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 22, height: 1.65,
                      fontWeight: FontWeight.w600, color: scheme.onSurface,
                    )),
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 8, children: [
                  FilledButton.tonalIcon(
                    onPressed: () => speak(story.pages[_page].text),
                    icon: const Icon(Icons.volume_up_rounded),
                    label: Text(_ar ? 'اقرأ لي' : 'Read aloud'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => speak(story.pages[_page].text, slow: true),
                    icon: const Icon(Icons.slow_motion_video_rounded),
                    label: Text(_ar ? 'ببطء' : 'Slow'),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _translation = !_translation),
                    icon: const Icon(Icons.translate_rounded),
                    label: Text(_ar ? 'الترجمة' : 'Translation'),
                  ),
                ]),
                if (_translation)
                  Padding(
                    padding: const EdgeInsets.all(13),
                    child: Text(story.pages[_page].arabic,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(color: scheme.onSurface,
                          fontSize: 17, height: 1.65)),
                  ),
              ] else ...[
                Text(_ar ? 'هل فهمت القصة؟' : 'Story comprehension',
                    style: const TextStyle(fontSize: 19,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 13),
                Text(story.question, textDirection: TextDirection.ltr,
                    style: const TextStyle(fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 13),
                for (var i = 0; i < story.options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: OutlinedButton(
                      onPressed: correct ? null : () => setState(() {
                        _answer = i; _checked = false;
                      }),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(58),
                        backgroundColor: _answer == i
                            ? scheme.primaryContainer : scheme.surface,
                      ),
                      child: Align(alignment: AlignmentDirectional.centerStart,
                        child: Text(story.options[i],
                          style: TextStyle(fontSize: 17, color: scheme.onSurface))),
                    ),
                  ),
                if (_checked)
                  Text(correct
                      ? (_ar ? 'أحسنت! اكتمل تحدي القصة.'
                          : 'Well done! You understood the story.')
                      : (_ar ? 'لم تصل للإجابة بعد. حاول مرة أخرى.'
                          : 'Try again.'),
                    style: TextStyle(color: correct
                        ? _deepGreen : scheme.error, fontWeight: FontWeight.w800)),
              ],
            ],
          )),
          const SizedBox(height: 9),
          Row(children: [
            if (_page > 0)
              OutlinedButton(
                onPressed: () {
                  tts.stop();
                  setState(() { _page--; _checked = false; _translation = false; });
                },
                child: Text(_ar ? 'السابق' : 'Back'),
              ),
            const Spacer(),
            FilledButton.icon(
              key: const ValueKey('english-story-next'),
              onPressed: _quiz ? (_answer == null ? null
                : correct ? () => Navigator.of(context).pop(true)
                : () => setState(() => _checked = true)) : _next,
              style: FilledButton.styleFrom(backgroundColor: _deepGreen,
                  foregroundColor: Colors.white),
              icon: Icon(correct ? Icons.check_circle_rounded
                  : Icons.arrow_forward_rounded),
              label: Text(_quiz
                  ? (correct
                    ? (_ar ? 'إكمال القصة' : 'Finish story')
                    : (_ar ? 'تحقق من الإجابة' : 'Check answer'))
                  : (_ar ? 'الصفحة التالية' : 'Next page')),
            ),
          ]),
        ]),
      )),
    );
  }
}
