import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/academy_catalog.dart';
import '../data/academy_multilingual_starters.dart';
import 'academy_multilingual_starter_screen.dart';
import '../data/academy_english_a1_catalog.dart';
import '../data/academy_english_advanced_models.dart';
import 'academy_english_advanced_screen.dart';
import 'academy_english_a1_screen.dart';
import 'academy_spanish_a1_screen.dart';
import '../data/academy_journey_catalog.dart';
import '../data/academy_story_catalog.dart';
import '../services/academy_progress_service.dart';
import 'academy_first_conversation.dart';
import 'academy_placement_screen.dart';
import 'academy_story_reader.dart';

const _green = Color(0xFF12523B);
const _gold = Color(0xFFF0C875);

String academyKindTitle(AcademyLessonKind kind, bool ar) => switch (kind) {
  AcademyLessonKind.vocabulary => ar ? 'المفردات' : 'Vocabulary',
  AcademyLessonKind.grammar => ar ? 'القواعد' : 'Grammar',
  AcademyLessonKind.story => ar ? 'قصص' : 'Stories',
  AcademyLessonKind.listening => ar ? 'الاستماع' : 'Listening',
  AcademyLessonKind.speaking => ar ? 'النطق' : 'Pronunciation',
  AcademyLessonKind.quiz => ar ? 'الاختبارات' : 'Quizzes',
};

IconData academyKindIcon(AcademyLessonKind kind) => switch (kind) {
  AcademyLessonKind.vocabulary => Icons.menu_book_outlined,
  AcademyLessonKind.grammar => Icons.rule_folder_outlined,
  AcademyLessonKind.story => Icons.auto_stories_rounded,
  AcademyLessonKind.listening => Icons.headphones_rounded,
  AcademyLessonKind.speaking => Icons.mic_rounded,
  AcademyLessonKind.quiz => Icons.fact_check_outlined,
};

/// Course entry: first visit starts diagnostic, then shows levels, not a
/// 12-card list. All advanced stage tiles are truthful "coming later" cards.
class AcademyCourseScreen extends StatefulWidget {
  const AcademyCourseScreen({required this.course, this.progress, super.key});
  final AcademyCourse course;
  final AcademyProgressService? progress;

  @override
  State<AcademyCourseScreen> createState() => _AcademyCourseScreenState();
}

class _AcademyCourseScreenState extends State<AcademyCourseScreen> {
  late final AcademyProgressService _progress =
      widget.progress ?? AcademyProgressService();
  String? _placementLevel;
  bool _checkingPlacement = true;
  bool _openingPlacement = false;
  int _pendingCount = 0;
  int _integratedA1Done = 0;

  String get _progressUser => FirebaseAuth.instance.currentUser?.uid ?? 'guest';
  String get _placementKey =>
      'worldvoice.academy.placement.v1.$_progressUser.${widget.course.code}';

  @override
  void initState() {
    super.initState();
    _loadPlacement();
  }

  Future<void> _loadPlacement() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_placementKey);
      final pending = await _progress.pendingCount();
      final integratedDone = widget.course.code == 'en'
          ? (await EnglishA1Progress.load(
              _progressUser == 'guest' ? null : _progressUser)).length
          : widget.course.code == 'es'
              ? (await SpanishA1Progress.load(
                  _progressUser == 'guest' ? null : _progressUser)).length : 0;
      if (!mounted) return;
      setState(() {
        _integratedA1Done = integratedDone;
        _placementLevel = saved;
        _pendingCount = pending;
        _checkingPlacement = false;
      });
      if (saved == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openPlacement();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checkingPlacement = false);
    }
  }

  Future<void> _openPlacement() async {
    if (_openingPlacement || !mounted) return;
    _openingPlacement = true;
    try {
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => AcademyPlacementScreen(course: widget.course),
        ),
      );
      if (!mounted) return;
      if (result == null) return; // Back does not count as an assessment.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_placementKey, result);
      if (mounted) setState(() => _placementLevel = result);
    } finally {
      _openingPlacement = false;
    }
  }

  Future<void> _openA1() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => widget.course.code == 'en'
            ? const AcademyEnglishA1Path()
            : widget.course.code == 'es'
                ? const AcademySpanishA1Path()
            : _AcademyA1Home(
                course: widget.course, progress: _progress,
              ),
      ),
    );
    final pending = await _progress.pendingCount();
    final integratedDone = widget.course.code == 'en'
        ? (await EnglishA1Progress.load(
            _progressUser == 'guest' ? null : _progressUser)).length
        : widget.course.code == 'es'
            ? (await SpanishA1Progress.load(
                _progressUser == 'guest' ? null : _progressUser)).length : 0;
    if (mounted) {
      setState(() {
        _pendingCount = pending;
        _integratedA1Done = integratedDone;
      });
    }
  }

  Future<void> _openAdvanced(String level) async {
    await Navigator.of(context).push<void>(MaterialPageRoute(
      builder: (_) => AcademyEnglishAdvancedLevelScreen(level: level),
    ));
  }

  Future<void> _sync() async {
    final synced = await _progress.synchronizePending();
    final pending = await _progress.pendingCount();
    if (!mounted) return;
    setState(() => _pendingCount = pending);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
      Localizations.localeOf(context).languageCode == 'ar'
          ? (pending == 0 ? 'تمت مزامنة دروسك!' :
            'تمت مزامنة $synced درسًا؛ ما زال $pending ينتظر Firebase.')
          : (pending == 0 ? 'All lessons synchronized!' :
            'Synced $synced; $pending still waiting for Firebase.'),
    )));
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    final accent = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF9DECC4) : _green;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _green, foregroundColor: Colors.white,
        title: Text('${widget.course.flag} ${widget.course.nativeName}'),
      ),
      body: _checkingPlacement
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<Set<String>>(
        stream: uid == null
            ? Stream.value(<String>{}) : _progress.completedLessons(uid),
        builder: (context, snapshot) {
          final done = snapshot.data ?? <String>{};
          final total = widget.course.code == 'en'
              ? EnglishA1Catalog.lessonCount
              : widget.course.code == 'es' ? 30 : widget.course.lessonCount;
          final count = widget.course.code == 'en' || widget.course.code == 'es'
              ? _integratedA1Done
              : widget.course.units.fold<int>(0, (n, unit) =>
                  n + AcademyLessonKind.values.where(
                      (kind) => done.contains(unit.lessonId(kind))).length);
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
            children: [
              Container(
                padding: const EdgeInsets.all(21),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    Color(0xFF124D38), Color(0xFF268A60),
                  ]),
                  borderRadius: BorderRadius.circular(23),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.school_rounded, color: _gold, size: 36),
                    const SizedBox(height: 10),
                    Text(ar ? 'رحلتك لتعلم ${widget.course.arabicName}'
                            : 'Your ${widget.course.nativeName} learning path',
                      style: const TextStyle(color: Colors.white, fontSize: 22,
                          fontWeight: FontWeight.w900)),
                    const SizedBox(height: 9),
                    Text(ar ? '$count من $total نشاطًا متاحًا أُنجزت'
                            : '$count of $total available activities completed',
                      style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: total == 0 ? 0 : count / total,
                      minHeight: 8, color: _gold,
                      backgroundColor: Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Card(
                color: scheme.surface,
                child: ListTile(
                  key: const ValueKey('academy-retake-placement'),
                  onTap: _openPlacement,
                  leading: Icon(Icons.psychology_alt_rounded, color: accent),
                  title: Text(ar ? 'اختبار تحديد المستوى' : 'Placement assessment',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(_placementLevel == null
                      ? (ar ? 'ابدأ الاختبار قبل الدراسة'
                            : 'Start with a placement assessment')
                      : (ar ? 'نقطة البداية المقترحة: $_placementLevel · إعادة الاختبار'
                            : 'Suggested starting point: $_placementLevel · Retake')),
                  trailing: Icon(Icons.chevron_right_rounded, color: accent),
                ),
              ),
              if (_pendingCount > 0)
                Card(color: scheme.surface,
                  child: ListTile(
                    leading: const Icon(Icons.cloud_upload_outlined),
                    title: Text(ar ? 'دروس محفوظة محليًا'
                        : 'Lessons saved on this device'),
                    subtitle: Text(ar
                        ? '$_pendingCount تنتظر مزامنة Firebase'
                        : '$_pendingCount waiting for Firebase sync'),
                    trailing: TextButton(
                      onPressed: _sync,
                      child: Text(ar ? 'مزامنة' : 'Sync'),
                    ),
                  )),
              const SizedBox(height: 17),
              Text(ar ? 'اختر مستوى التعلم' : 'Choose your learning level',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900, color: accent)),
              const SizedBox(height: 10),
              ...AcademyJourneyCatalog.levels.map((level) {
                final a1 = level.isBeginner;
                final advancedLessons = widget.course.code == 'en'
                    ? EnglishAdvancedSyllabus.forLevel(level.id).length : 0;
                final published = a1 || advancedLessons > 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(19),
                    child: InkWell(
                      key: ValueKey('academy-level-${level.id}'),
                      borderRadius: BorderRadius.circular(19),
                      onTap: a1 ? _openA1 : advancedLessons > 0
                          ? () => _openAdvanced(level.id) : null,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: scheme.outlineVariant),
                          borderRadius: BorderRadius.circular(19),
                        ),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: published ? scheme.primaryContainer
                                : scheme.surfaceContainerHighest,
                            child: Text(level.id,
                              style: TextStyle(color: published ? accent
                                  : scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w900)),
                          ),
                          const SizedBox(width: 13),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ar ? level.titleArabic : level.titleEnglish,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 17)),
                              const SizedBox(height: 4),
                              Text(a1
                                  ? (ar
                                      ? '${widget.course.code == 'en' || widget.course.code == 'es' ? 3 : widget.course.units.length} وحدات جاهزة للبدء'
                                      : '${widget.course.code == 'en' || widget.course.code == 'es' ? 3 : widget.course.units.length} units ready')
                                  : advancedLessons > 0
                                      ? (ar ? '$advancedLessons درس تجريبي منشور · المزيد قيد التأليف'
                                          : '$advancedLessons published pilot lesson · more in progress')
                                      : (ar ? 'قيد إعداد الدروس'
                                          : 'Lessons are being prepared'),
                                style: TextStyle(color: scheme.onSurfaceVariant)),
                            ],
                          )),
                          Icon(published ? Icons.play_circle_rounded
                              : Icons.lock_outline_rounded,
                              color: published ? accent : scheme.onSurfaceVariant),
                        ]),
                      ),
                    ),
                  ),
                );
              }),
              Text(widget.course.code == 'es'
                  ? (ar
                      ? 'الإسبانية A1: ثلاث وحدات وثلاثون درسًا متكاملًا. المستويات الأعلى قيد الإعداد.'
                      : 'Spanish A1: three units and thirty lessons. Higher levels are not published yet.')
                  : (ar
                      ? 'اختبار المستوى تمهيدي. هذه دروس الأكاديمية المتاحة حاليًا.'
                      : 'Placement is preliminary. The listed Academy lessons are available.'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12,
                    color: scheme.onSurfaceVariant)),
            ],
          );
        },
      ),
    );
  }
}

String academyVoiceLocale(String code) => switch (code) {
  'en' => 'en-US',
  'es' => 'es-ES',
  'zh' => 'zh-CN',
  'fr' => 'fr-FR',
  'ko' => 'ko-KR',
  _ => code,
};

Future<void> academyTestVoice(BuildContext context, AcademyCourse course) async {
  final ar = Localizations.localeOf(context).languageCode == 'ar';
  final locale = academyVoiceLocale(course.code);
  final sample = switch (course.code) {
    'en' => 'Hello! Nice to meet you.',
    'es' => 'Hola. Mucho gusto.',
    'zh' => '你好！很高兴认识你。',
    'fr' => 'Bonjour. Enchanté.',
    'ko' => '안녕하세요. 만나서 반가워요.',
    _ => 'Hello.',
  };
  final tts = FlutterTts();
  String message;
  try {
    final available = await tts.isLanguageAvailable(locale);
    final installed = defaultTargetPlatform == TargetPlatform.android
        ? await tts.isLanguageInstalled(locale) : true;
    if (available == false || installed == false) {
      message = ar
          ? 'صوت $locale غير مثبّت. افتح إعدادات الهاتف ← تحويل النص إلى كلام ← تثبيت بيانات الصوت، ثم اختر اللغة.'
          : 'Voice $locale is missing. Open device Settings → Text-to-speech → Install voice data.';
    } else {
      await tts.setLanguage(locale);
      await tts.setVolume(1.0);
      await tts.setSpeechRate(.50);
      final started = await tts.speak(sample);
      message = started == 0
          ? (ar ? 'فشل تشغيل الصوت. راجع إعدادات محرك النطق.'
                : 'Speech could not start. Check your TTS engine.')
          : (ar ? 'تم إرسال تجربة النطق. تأكد من رفع صوت الوسائط في هاتفك.'
                : 'Voice sample started. Check your phone media volume.');
    }
  } catch (_) {
    message = ar
        ? 'تعذّر فحص الصوت. افتح إعدادات الهاتف ← تحويل النص إلى كلام وثبّت صوت هذه اللغة.'
        : 'Voice check failed. Install this language in device text-to-speech settings.';
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message),
        duration: const Duration(seconds: 6)));
  }
}

class _AcademyA1Home extends StatelessWidget {
  const _AcademyA1Home({required this.course, required this.progress});
  final AcademyCourse course;
  final AcademyProgressService progress;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    final accent = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF9DECC4) : _green;
    final kinds = <AcademyLessonKind?>[
      null, AcademyLessonKind.story, AcademyLessonKind.vocabulary,
      AcademyLessonKind.grammar, AcademyLessonKind.listening,
      AcademyLessonKind.speaking, AcademyLessonKind.quiz,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(ar ? 'A1 · المبتدئ' : 'A1 · Beginner'),
        backgroundColor: _green, foregroundColor: Colors.white),
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(ar ? 'ماذا تريد أن تتعلم اليوم؟' : 'What will you learn today?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900, color: accent)),
          const SizedBox(height: 8),
          Text(ar ? 'قصص ومحادثات ومفردات ونطق — اختر القسم وابدأ دروسه.'
              : 'Stories, dialogues, vocabulary and pronunciation — choose a section.',
            style: TextStyle(color: scheme.onSurfaceVariant)),
          if (AcademyMultilingualStarters.forCode(course.code) case final starter?) ...[
            const SizedBox(height: 18),
            Card(
              color: scheme.surface, elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: scheme.outlineVariant),
              ),
              child: ListTile(
                key: const ValueKey('academy-new-guided-start'),
                contentPadding: const EdgeInsets.all(15),
                leading: CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(Icons.school_rounded, color: accent)),
                title: Text(ar ? 'الدرس الأول · شرح متكامل' :
                    'Lesson 1 · Guided study',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(ar
                    ? 'قواعد · 20 كلمة · محادثة · قصة · استماع واختبار'
                    : 'Grammar · 20 words · dialogue · story · quiz'),
                trailing: Icon(Icons.play_circle_fill_rounded,
                    color: accent, size: 30),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => AcademyGuidedStartScreen(lesson: starter)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          OutlinedButton.icon(
            key: const ValueKey('academy-test-course-voice'),
            onPressed: () => academyTestVoice(context, course),
            icon: const Icon(Icons.volume_up_rounded),
            label: Text(ar ? 'اختبار صوت اللغة قبل الدرس' : 'Test language voice'),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: kinds.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
              mainAxisExtent: 135,
            ),
            itemBuilder: (context, index) {
              final kind = kinds[index];
              final label = kind == null
                  ? (ar ? 'المحادثات' : 'Conversations')
                  : academyKindTitle(kind, ar);
              return Material(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(21),
                child: InkWell(
                  key: ValueKey('academy-section-${kind?.name ?? 'dialogue'}'),
                  borderRadius: BorderRadius.circular(21),
                  onTap: () async {
                    if (kind == null) {
                      final finished = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => AcademyFirstConversation(course: course),
                        ),
                      );
                      if (finished == true && context.mounted) {
                        await Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => _AcademySectionList(
                              course: course,
                              kind: AcademyLessonKind.vocabulary,
                              progress: progress,
                            ),
                          ),
                        );
                      }
                    } else {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => _AcademySectionList(
                            course: course, kind: kind, progress: progress,
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(21),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(kind == null ? Icons.forum_rounded
                                : academyKindIcon(kind),
                            size: 34, color: accent),
                        const SizedBox(height: 10),
                        Text(label, textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w900,
                                fontSize: 17)),
                        const SizedBox(height: 5),
                        Text(ar ? '${course.units.length} درس' :
                            '${course.units.length} lessons',
                          style: TextStyle(color: scheme.onSurfaceVariant,
                              fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(ar ? 'اختر أي قسم، ويمكنك العودة لإكمال الأقسام الأخرى.'
              : 'Choose any section; come back to finish the others.',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      )),
    );
  }
}

class _AcademySectionList extends StatefulWidget {
  const _AcademySectionList({
    required this.course, required this.kind, required this.progress});
  final AcademyCourse course;
  final AcademyLessonKind kind;
  final AcademyProgressService progress;

  @override
  State<_AcademySectionList> createState() => _AcademySectionListState();
}

class _AcademySectionListState extends State<_AcademySectionList> {
  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: Text(academyKindTitle(widget.kind, ar)),
          backgroundColor: _green, foregroundColor: Colors.white),
      body: SafeArea(child: StreamBuilder<Set<String>>(
        stream: uid == null ? Stream.value(<String>{})
            : widget.progress.completedLessons(uid),
        builder: (context, snapshot) {
          final completed = snapshot.data ?? <String>{};
          return ListView(
            padding: const EdgeInsets.all(19),
            children: [
              Text(ar ? 'دروس ${academyKindTitle(widget.kind, ar)}'
                      : '${academyKindTitle(widget.kind, ar)} lessons',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              for (final unit in widget.course.units)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(color: scheme.surface, elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(19),
                      side: BorderSide(color: scheme.outlineVariant)),
                    child: ListTile(
                      key: ValueKey('academy-unit-${unit.number}'),
                      contentPadding: const EdgeInsets.all(14),
                      leading: CircleAvatar(
                        backgroundColor: scheme.primaryContainer,
                        child: Text('${unit.number}',
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                      title: Text(ar ? unit.title : unit.nativeTitle,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(unit.nativeTitle),
                      trailing: Icon(completed.contains(unit.lessonId(widget.kind))
                          ? Icons.check_circle_rounded
                          : Icons.chevron_right_rounded),
                      onTap: () async {
                        await Navigator.of(context).push<void>(
                          MaterialPageRoute(builder: (_) => AcademyLessonScreen(
                            unit: unit, kind: widget.kind,
                            progress: widget.progress,
                            completed: completed.contains(unit.lessonId(widget.kind)),
                          )),
                        );
                        if (mounted) setState(() {});
                      },
                    ),
                  ),
                ),
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
      final supportsLanguage = await _tts.isLanguageAvailable(_speechLocale);
      if (supportsLanguage == false) {
        throw StateError('Target language voice is not available');
      }
      await _tts.setLanguage(_speechLocale);
      await _tts.setVolume(1.0);
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
      final synced = await (widget.progress ?? AcademyProgressService())
          .complete(widget.unit, widget.kind);
      if (!mounted) return;
      setState(() => _complete = true);
      _notice(synced
          ? (_ar ? 'تم حفظ التقدم في Firebase!' : 'Progress saved to Firebase!')
          : (_ar
              ? 'تم حفظ الدرس على الجهاز. ينتظر مزامنة Firebase.'
              : 'Saved on this device, pending Firebase sync.'));
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
