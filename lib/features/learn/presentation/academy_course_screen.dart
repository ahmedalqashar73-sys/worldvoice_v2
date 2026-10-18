import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/academy_catalog.dart';
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
              const SizedBox(height: 20),
              for (final unit in course.units) ...[
                Text(ar ? 'الوحدة ${unit.number} · ${unit.title}' :
                    'Unit ${unit.number} · ${unit.nativeTitle}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _green, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text(unit.nativeTitle,
                  style: const TextStyle(color: Color(0xFF688075))),
                const SizedBox(height: 9),
                for (final kind in AcademyLessonKind.values)
                  Card(
                    color: const Color(0xFFF4F9F4), elevation: 0,
                    margin: const EdgeInsets.only(bottom: 7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: const BorderSide(color: Color(0xFFD7E9DD))),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFDCEEE2),
                        child: Icon(academyKindIcon(kind), color: _green)),
                      title: Text(academyKindTitle(kind, ar),
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(ar ? 'الدرس ${kind.index + 1} من 6'
                          : 'Lesson ${kind.index + 1} of 6'),
                      trailing: Icon(done.contains(unit.lessonId(kind))
                          ? Icons.check_circle_rounded
                          : Icons.chevron_right_rounded,
                        color: done.contains(unit.lessonId(kind))
                            ? _green : const Color(0xFF92A499)),
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(builder: (_) => AcademyLessonScreen(
                          unit: unit, kind: kind, progress: repository,
                          completed: done.contains(unit.lessonId(kind))),
                        )),
                    ),
                  ),
                const SizedBox(height: 13),
              ],
              Text(ar
                ? 'Intermediate وAdvanced قادمان لاحقًا بمحتوى مستقل.'
                : 'Intermediate and Advanced will follow with their own lessons.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF688075),
                    fontSize: 12)),
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
  static const _tts = MethodChannel('worldvoice/live_tts');
  int? _chosen;
  bool _checked = false, _correct = false, _saving = false;
  bool _speaking = false, _transcript = false;
  late bool _complete;

  @override
  void initState() {
    super.initState();
    _complete = widget.completed;
  }
  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

  void _notice(String text) => ScaffoldMessenger.of(context)
    .showSnackBar(SnackBar(content: Text(text)));

  Future<void> _hear(String text) async {
    if (_speaking) return;
    setState(() => _speaking = true);
    try {
      await _tts.invokeMethod<void>('speak', {
        'text': text, 'languageCode': widget.unit.language,
      });
    } on MissingPluginException {
      if (mounted) {
        _notice(_ar
            ? 'النطق الصوتي متاح حاليًا على أندرويد. اقرأ النص للمراجعة.'
            : 'Voice playback is currently available on Android.');
      }
    } on PlatformException {
      if (mounted) {
        _notice(_ar
            ? 'تأكد من تثبيت صوت هذه اللغة في إعدادات الجهاز.'
            : 'Install the selected language voice in your device settings.');
      }
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  Future<void> _save() async {
    if (_saving || _complete) return;
    if (widget.kind == AcademyLessonKind.quiz && !_correct) return;
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

  Widget _info(String title, String text, {bool target = false}) =>
      Container(
        width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F8F4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD8E6DA))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w900, color: _green)),
          const SizedBox(height: 9),
          Text(text,
            textDirection: target ? TextDirection.ltr : null,
            style: const TextStyle(fontSize: 17, height: 1.55)),
        ]),
      );

  Widget _listen(String text) => FilledButton.icon(
    onPressed: _speaking ? null : () => _hear(text),
    icon: Icon(_speaking ? Icons.hourglass_top_rounded
        : Icons.volume_up_rounded),
    label: Text(_ar ? 'استمع للنطق' : 'Listen'),
    style: FilledButton.styleFrom(
      backgroundColor: _green, foregroundColor: Colors.white),
  );

  Widget _body() {
    final u = widget.unit;
    switch (widget.kind) {
      case AcademyLessonKind.vocabulary:
        return Column(children: [
          for (final word in u.words)
            Card(color: const Color(0xFFF3F8F3), elevation: 0,
              child: ListTile(
                title: Text(word.term,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 19)),
                subtitle: Text('${word.arabic} · ${word.pronunciation}'),
                trailing: IconButton(
                  onPressed: _speaking ? null : () => _hear(word.term),
                  tooltip: _ar ? 'استمع' : 'Listen',
                  icon: const Icon(Icons.volume_up_rounded,
                    color: _green)),
              )),
          const SizedBox(height: 9),
          Text(_ar ? 'جرّب استخدام كل كلمة في جملة.'
            : 'Try using each word in a sentence.'),
        ]);
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
        return Column(children: [
          _info(_ar ? 'اقرأ القصة' : 'Read the story', u.story, target: true),
          const SizedBox(height: 10),
          _listen(u.story),
          const SizedBox(height: 10),
          _info(_ar ? 'الشرح بالعربية' : 'Arabic interpretation', u.storyArabic),
        ]);
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
                color: _green, fontWeight: FontWeight.w900))),
          ]),
          const SizedBox(height: 16),
          _body(),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: _saving || _complete ||
                (widget.kind == AcademyLessonKind.quiz && !_correct)
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
