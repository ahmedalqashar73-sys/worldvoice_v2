import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/academy_english_a1_catalog.dart';
import '../data/academy_english_a1_long_stories.dart';
import 'academy_english_a1_integrated_lesson.dart';

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

