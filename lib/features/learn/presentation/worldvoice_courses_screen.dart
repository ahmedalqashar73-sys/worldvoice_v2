import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/localization/locale_controller.dart';
import '../data/course_catalog.dart';

const _courseGreen = Color(0xFF125B45);

/// A standalone course experience: no room, live, or conversation dependency.
class WorldVoiceCoursesScreen extends StatefulWidget {
  const WorldVoiceCoursesScreen({required this.localeController, super.key});

  final LocaleController localeController;

  @override
  State<WorldVoiceCoursesScreen> createState() => _WorldVoiceCoursesScreenState();
}

class _WorldVoiceCoursesScreenState extends State<WorldVoiceCoursesScreen> {
  final TextEditingController _search = TextEditingController();
  final Set<String> _completed = <String>{};
  bool _loading = true;

  bool get _arabic => widget.localeController.locale?.languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _search.addListener(_onSearch);
  }

  void _onSearch() {
    if (mounted) setState(() {});
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = <String>{};
      for (final course in CourseCatalog.all) {
        for (final lesson in course.lessons) {
          final key = _progressKey(course.code, lesson.id);
          if (prefs.getBool(key) ?? false) keys.add(key);
        }
      }
      if (!mounted) return;
      setState(() {
        _completed
          ..clear()
          ..addAll(keys);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _search.removeListener(_onSearch);
    _search.dispose();
    super.dispose();
  }

  Future<void> _openCourse(CourseLanguage course) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _CourseOverviewScreen(course: course, arabic: _arabic),
      ),
    );
    await _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final search = _search.text.trim().toLowerCase();
    final courses = CourseCatalog.all.where((course) {
      return course.name.toLowerCase().contains(search) ||
          course.code.toLowerCase().contains(search);
    }).toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(_arabic ? 'كورسات WorldVoice' : 'WorldVoice Courses',
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _courseGreen,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_stories_rounded,
                      size: 32, color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    _arabic ? 'ابدأ تعلم لغة جديدة' : 'Start learning a language',
                    style: const TextStyle(
                      fontSize: 23, fontWeight: FontWeight.w900, color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _arabic
                        ? 'كلمات واضحة، نطق مكتوب، صوت أصلي، وتقدم محفوظ.'
                        : 'Clear words, pronunciation guides, speech, and saved progress.',
                    style: const TextStyle(color: Color(0xFFE0F0EA), fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: _arabic ? 'ابحث عن لغة' : 'Find a language',
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _arabic ? 'اختر اللغة التي تريد تعلمها' : 'Choose a language to learn',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            if (courses.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(_arabic ? 'لم نجد هذه اللغة' : 'Language not found'),
                ),
              ),
            ...courses.map((course) {
              final done = course.lessons.where(
                (lesson) => _completed.contains(_progressKey(course.code, lesson.id)),
              ).length;
              final fraction = course.lessons.isEmpty ? 0.0 : done / course.lessons.length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _openCourse(course),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .45)),
                      ),
                      child: Row(
                        children: [
                          Text(course.flag, style: const TextStyle(fontSize: 31)),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(course.name, textDirection: course.rightToLeft
                                    ? TextDirection.rtl : TextDirection.ltr,
                                    style: const TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.w800,
                                    )),
                                const SizedBox(height: 4),
                                Text(
                                  _arabic
                                      ? '${course.lessons.length} دروس · ${course.wordCount} كلمات وعبارات'
                                      : '${course.lessons.length} lessons · ${course.wordCount} words and phrases',
                                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: fraction,
                                    backgroundColor: scheme.surfaceContainerHighest,
                                    color: _courseGreen,
                                    minHeight: 5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_loading)
                            const SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2))
                          else
                            Icon(Icons.chevron_right_rounded,
                                color: scheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

String _progressKey(String code, String lessonId) =>
    'worldvoice.learn.completed.v1.' + code + '.' + lessonId;

class _CourseOverviewScreen extends StatefulWidget {
  const _CourseOverviewScreen({required this.course, required this.arabic});

  final CourseLanguage course;
  final bool arabic;

  @override
  State<_CourseOverviewScreen> createState() => _CourseOverviewScreenState();
}

class _CourseOverviewScreenState extends State<_CourseOverviewScreen> {
  final Set<String> _completed = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = <String>{};
      for (final lesson in widget.course.lessons) {
        if (prefs.getBool(_progressKey(widget.course.code, lesson.id)) ?? false) {
          ids.add(lesson.id);
        }
      }
      if (mounted) setState(() => _completed
        ..clear()
        ..addAll(ids));
    } catch (_) {
      // The lessons remain available even when local storage is unavailable.
    }
  }

  Future<void> _open(CourseLesson lesson) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _VocabularyLessonScreen(
          course: widget.course,
          lesson: lesson,
          arabic: widget.arabic,
          completed: _completed.contains(lesson.id),
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.course.name,
          style: const TextStyle(fontWeight: FontWeight.w800))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(children: [
              Text(widget.course.flag, style: const TextStyle(fontSize: 44)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.arabic ? 'مسار المبتدئين' : 'Beginner course',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900)),
                    Text(widget.arabic ? 'استمع، اقرأ النطق، ثم احفظ تقدمك' :
                      'Listen, read the pronunciation, and track your progress.',
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 24),
            ...widget.course.lessons.asMap().entries.map((entry) {
              final lesson = entry.value;
              final completed = _completed.contains(lesson.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Material(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    onTap: () => _open(lesson),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: .5),
                        ),
                      ),
                      child: Row(children: [
                        Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _courseGreen.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: completed
                              ? const Icon(Icons.check_circle_rounded, color: _courseGreen)
                              : Text('${entry.key + 1}',
                                  style: const TextStyle(fontSize: 20,
                                      fontWeight: FontWeight.w900, color: _courseGreen)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.arabic ? lesson.titleArabic : lesson.titleEnglish,
                                  style: const TextStyle(fontWeight: FontWeight.w800,
                                      fontSize: 17)),
                              const SizedBox(height: 5),
                              Text(
                                widget.arabic
                                    ? '${lesson.words.length} كلمات وعبارات'
                                    : '${lesson.words.length} words and phrases',
                                style: TextStyle(color: scheme.onSurfaceVariant,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: scheme.onSurfaceVariant),
                      ]),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _VocabularyLessonScreen extends StatefulWidget {
  const _VocabularyLessonScreen({
    required this.course,
    required this.lesson,
    required this.arabic,
    required this.completed,
  });

  final CourseLanguage course;
  final CourseLesson lesson;
  final bool arabic;
  final bool completed;

  @override
  State<_VocabularyLessonScreen> createState() => _VocabularyLessonScreenState();
}

class _VocabularyLessonScreenState extends State<_VocabularyLessonScreen> {
  late final FlutterTts _tts;
  int? _speaking;
  bool _saving = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _completed = widget.completed;
    _tts = FlutterTts();
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = null);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _speaking = null);
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _speaking = null);
    });
  }

  Future<void> _play(int index, {bool slow = false}) async {
    final word = widget.lesson.words[index];
    if (_speaking == index) {
      await _tts.stop();
      if (mounted) setState(() => _speaking = null);
      return;
    }
    try {
      await _tts.stop();
      if (!mounted) return;
      setState(() => _speaking = index);
      await _tts.setLanguage(widget.course.speechLocale);
      await _tts.setSpeechRate(slow ? .30 : .50);
      await _tts.setPitch(1.0);
      await _tts.speak(word.text);
    } catch (_) {
      if (!mounted) return;
      setState(() => _speaking = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.arabic
            ? 'تعذّر تشغيل الصوت. تأكد من تثبيت صوت هذه اللغة على هاتفك.'
            : 'Speech unavailable. Check that this language voice is installed.')),
      );
    }
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = await prefs.setBool(
        _progressKey(widget.course.code, widget.lesson.id), true,
      );
      if (!mounted) return;
      if (!saved) throw StateError('Could not save lesson completion');
      setState(() => _completed = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.arabic
            ? 'أحسنت! تم حفظ تقدمك على هذا الجهاز.'
            : 'Well done! Your progress is saved on this device.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.arabic
            ? 'تعذر حفظ التقدم. حاول مرة أخرى.'
            : 'Could not save progress. Please retry.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
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
    final lessonTitle = widget.arabic
        ? widget.lesson.titleArabic : widget.lesson.titleEnglish;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.arabic ? 'المفردات' : 'Vocabulary',
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Text(lessonTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900, color: _courseGreen)),
            const SizedBox(height: 5),
            Text(widget.arabic
                ? 'الكلمة · النطق المكتوب · المعنى · الصوت'
                : 'Word · pronunciation · meaning · audio',
                style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            ...widget.lesson.words.asMap().entries.map((entry) {
              final index = entry.key;
              final word = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: Container(
                  padding: const EdgeInsets.all(19),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: .42),
                    ),
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: Text(
                            word.text,
                            textDirection: widget.course.rightToLeft
                                ? TextDirection.rtl : TextDirection.ltr,
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontSize: 26,
                              height: 1.3,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filledTonal(
                          onPressed: () => _play(index),
                          tooltip: widget.arabic ? 'استمع للكلمة' : 'Listen',
                          style: IconButton.styleFrom(
                            backgroundColor: _courseGreen.withValues(alpha: .11),
                            foregroundColor: _courseGreen,
                          ),
                          icon: Icon(_speaking == index
                              ? Icons.stop_rounded : Icons.volume_up_rounded, size: 28),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Text(widget.arabic ? 'النطق' : 'Pronunciation',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12, fontWeight: FontWeight.w600,
                        )),
                      const SizedBox(height: 4),
                      SelectableText(
                        word.pronunciation,
                        style: const TextStyle(
                          color: _courseGreen,
                          fontSize: 18,
                          height: 1.4,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(widget.arabic ? word.arabic : word.english,
                        style: TextStyle(
                          fontSize: 17, height: 1.4, color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        )),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          onPressed: () => _play(index, slow: true),
                          icon: const Icon(Icons.slow_motion_video_rounded),
                          label: Text(widget.arabic ? 'استمع ببطء' : 'Play slowly'),
                          style: TextButton.styleFrom(foregroundColor: _courseGreen),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _saving ? null : _finish,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2,
                          color: Colors.white))
                  : Icon(_completed ? Icons.check_circle_rounded
                      : Icons.bookmark_added_rounded),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  _completed
                      ? (widget.arabic ? 'تم إكمال الدرس' : 'Lesson completed')
                      : (widget.arabic ? 'إكمال الدرس وحفظ التقدم' :
                          'Complete lesson and save progress'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _courseGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                widget.arabic
                    ? 'تعمل ميزة الصوت عند توفر صوت اللغة على جهازك.'
                    : 'Audio requires a compatible language voice on your device.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
