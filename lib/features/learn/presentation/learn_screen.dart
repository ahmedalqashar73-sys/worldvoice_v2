import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';
import '../data/academy_catalog.dart';
import '../data/academy_english_a1_catalog.dart';
import 'academy_english_a1_screen.dart';
import '../services/academy_progress_service.dart';
import 'academy_course_screen.dart';

/// WorldVoice Academy: first-class courses, not placeholder chat contacts.
/// The six lesson types are implemented per unit; only reviewed A1 content is
/// available, so unfinished intermediate levels are not advertised as ready.
class LearnScreen extends StatefulWidget {
  const LearnScreen({required this.localeController, super.key});
  final LocaleController localeController;

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final _search = TextEditingController();
  final _progress = AcademyProgressService();
  String _query = '';
  int _englishDone = 0;

  @override
  void initState() {
    super.initState();
    _refreshEnglish();
  }

  Future<void> _refreshEnglish() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final done = await EnglishA1Progress.load(uid);
    if (mounted) setState(() => _englishDone = done.length);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.localeController.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    final ar = code == 'ar';
    final scheme = Theme.of(context).colorScheme;
    final accent = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF9DECC4) : const Color(0xFF164E39);
    final rtl = const {'ar', 'ur', 'fa'}.contains(code);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final courses = academyCourses.where((course) {
      final query = _query.trim().toLowerCase();
      if (query.isEmpty) return true;
      return course.nativeName.toLowerCase().contains(query) ||
          course.arabicName.contains(query) ||
          course.code.contains(query);
    }).toList(growable: false);

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        child: StreamBuilder<Set<String>>(
          stream: uid == null ? Stream.value(<String>{})
              : _progress.completedLessons(uid),
          builder: (context, snapshot) {
            final done = snapshot.data ?? <String>{};
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDFEFE4),
                      borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.school_rounded,
                      color: Color(0xFF156143), size: 28)),
                  const SizedBox(width: 11),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WorldVoice Academy',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: accent)),
                      Text(ar ? 'تعلم لغة خطوة بخطوة'
                          : 'Learn a language step by step',
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                    ],
                  )),
                ]),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(19),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0xFF124D38), Color(0xFF23825B)]),
                    borderRadius: BorderRadius.circular(22)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_stories_rounded,
                        color: Color(0xFFF0D48C), size: 29),
                      const SizedBox(height: 9),
                      Text(ar ? 'ابدأ رحلتك التعليمية' :
                          'Your learning journey starts here',
                        style: const TextStyle(color: Colors.white,
                          fontSize: 20, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 7),
                      Text(ar
                        ? 'مفردات، قواعد، قصص، استماع، محادثة واختبارات — خمس لغات ومسار Beginner مجاني.'
                        : 'Vocabulary, grammar, stories, listening, speaking and quizzes across five Beginner courses.',
                        style: const TextStyle(
                          color: Color(0xFFE6F2E8), height: 1.4)),
                      const SizedBox(height: 13),
                      const Row(children: [
                        Icon(Icons.verified_rounded,
                          color: Color(0xFFF0D48C), size: 18),
                        SizedBox(width: 7),
                        Text('5 Languages  ·  60 Lessons',
                          style: TextStyle(color: Color(0xFFF0D48C),
                            fontWeight: FontWeight.w800)),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 21),
                Text(ar ? 'اختر اللغة التي تريد تعلمها' :
                  'Choose your learning language',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900)),
                const SizedBox(height: 11),
                TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: ar ? 'ابحث عن لغة أو كورس'
                      : 'Search for a language or course',
                    prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFF1E7853)),
                    suffixIcon: _query.isEmpty ? null : IconButton(
                      onPressed: () => setState(() {
                        _search.clear(); _query = '';
                      }),
                      icon: const Icon(Icons.close_rounded)),
                    filled: true,
                    fillColor: scheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                if (courses.isEmpty)
                  Padding(padding: const EdgeInsets.all(24),
                    child: Center(child: Text(
                      ar ? 'لا توجد لغة مطابقة للبحث.'
                         : 'No matching language found.')))
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: courses.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 10,
                      mainAxisSpacing: 10, mainAxisExtent: 187),
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      final completed = course.code == 'en'
                          ? _englishDone
                          : course.units.fold<int>(0, (n, u) =>
                              n + AcademyLessonKind.values.where(
                                (kind) => done.contains(u.lessonId(kind))).length);
                      final total = course.code == 'en'
                          ? EnglishA1Catalog.lessonCount : course.lessonCount;
                      return Material(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          key: ValueKey('academy-course-${course.code}'),
                          borderRadius: BorderRadius.circular(18),
                          onTap: () async {
                            await Navigator.push<void>(context,
                              MaterialPageRoute(builder: (_) =>
                                AcademyCourseScreen(
                                  course: course, progress: _progress)));
                            await _refreshEnglish();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: scheme.outlineVariant)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(course.flag,
                                  style: const TextStyle(fontSize: 31)),
                                const SizedBox(height: 4),
                                Text(ar ? course.arabicName : course.nativeName,
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: accent, fontSize: 15)),
                                Text(course.nativeName, maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant, fontSize: 11)),
                                const Spacer(),
                                Text(ar ? 'A1 · $total درسًا'
                                    : 'A1 · $total lessons',
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 11, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 7),
                                LinearProgressIndicator(
                                  value: total == 0 ? 0 : completed / total,
                                  color: const Color(0xFFD3A954),
                                  minHeight: 5,
                                  borderRadius: BorderRadius.circular(6),
                                  backgroundColor: const Color(0xFFD3EADB)),
                                const SizedBox(height: 5),
                                Text(ar ? '$completed / $total مكتمل'
                                    : '$completed / $total completed',
                                  style: TextStyle(
                                    fontSize: 11, color: scheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 17),
                if (uid == null)
                  Text(ar ? 'يمكنك استكشاف الدروس؛ سجل الدخول لحفظ التقدم.'
                      : 'Explore lessons; sign in to save progress.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF7B6C46))),
                if (snapshot.hasError)
                  Text(ar ? 'تعذّر تحديث التقدم من Firebase.'
                      : 'Could not refresh progress from Firebase.',
                    style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 10),
                Text(ar
                  ? 'دروس المستوى المتوسط والمتقدم ستضاف لاحقًا بعد مراجعة المحتوى. لا توجد عملات أو اشتراكات مرتبطة بإكمال الدروس.'
                  : 'Intermediate and Advanced lessons will follow after content review. Completing lessons does not award coins or paid benefits.',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant, fontSize: 12, height: 1.45),
                  textAlign: TextAlign.center),
              ],
            );
          },
        ),
      ),
    );
  }
}
