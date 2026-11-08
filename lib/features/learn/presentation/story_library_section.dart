import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter_svg/flutter_svg.dart';

import '../data/academy_catalog.dart';
import '../data/story_library_repository.dart';
import '../data/graded_story_repository.dart';
import '../domain/models/story_library_models.dart';
import 'story_library_reader_screen.dart';
import 'graded_story_reader_screen.dart';

/// Independent graded stories; existing lesson stories remain unchanged.
class StoryLibrarySection extends StatefulWidget {
  const StoryLibrarySection({super.key, this.initialA1Stories});

  /// Test/preview injection. Production always loads the signed-in main assets.
  final List<GradedStoryEntry>? initialA1Stories;

  @override
  State<StoryLibrarySection> createState() => _StoryLibrarySectionState();
}

class _StoryLibrarySectionState extends State<StoryLibrarySection> {
  late final StoryLibraryRepository _repository = StoryLibraryRepository();
  late final Future<List<StoryLibraryEntry>> _index = _repository.loadIndex();
  final GradedStoryRepository _gradedRepository = GradedStoryRepository();
  late final Future<List<GradedStoryEntry>> _gradedA1Index =
      widget.initialA1Stories == null
          ? _gradedRepository.loadIndex()
          : SynchronousFuture<List<GradedStoryEntry>>(
              widget.initialA1Stories!);
  String _language = 'en';
  String _level = 'A1';

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    final accent = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF9DECC4)
        : const Color(0xFF164E39);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ar ? 'مكتبة القصص' : 'Stories Library',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900, color: accent),
        ),
        const SizedBox(height: 6),
        Text(
          ar
              ? 'اختر اللغة والمستوى لقراءة قصص مستقلة عن الدروس.'
              : 'Choose a language and level to read stories beyond lessons.',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        Text(ar ? 'اللغة' : 'Language',
          style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final course in academyCourses)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ChoiceChip(
                  key: ValueKey('stories-language-${course.code}'),
                  label: Text(
                    '${course.flag} ${ar ? course.arabicName : course.nativeName}',
                  ),
                  selected: _language == course.code,
                  onSelected: (_) => setState(() {
                    _language = course.code;
                    _level = 'A1';
                  }),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 17),
        Text(ar ? 'المستوى' : 'Level',
          style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final level in StoryLibraryEntry.levels)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 7),
                child: ChoiceChip(
                  key: ValueKey('stories-level-$level'),
                  label: Text(level),
                  selected: _level == level,
                  onSelected: (_) => setState(() => _level = level),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 18),
        if (_language == 'en' && _level == 'A1')
          _gradedA1Shelf(ar, scheme, accent)
        else
          FutureBuilder<List<StoryLibraryEntry>>(
          future: _index,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Text(ar ? 'تعذّر تحميل مكتبة القصص.'
                    : 'Could not load the story library.'),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final available = snapshot.data!.where((entry) =>
              entry.language == _language && entry.level == _level)
              .toList(growable: false);
            // The old standalone A1 example stays in the repository and
            // remains readable; show the five curated textbook books in A1.
            final hasTextbooks =
                available.any((entry) => entry.format == 'textbook');
            final stories = available.where((entry) =>
                !hasTextbooks || entry.format == 'textbook')
              .toList(growable: false);
            if (stories.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 35),
                child: Center(child: Column(children: [
                  Icon(Icons.auto_stories_outlined, size: 42, color: accent),
                  const SizedBox(height: 10),
                  Text(
                    ar ? 'لا توجد قصص منشورة لهذا المستوى بعد.'
                        : 'No stories published at this level yet.',
                    textAlign: TextAlign.center,
                  ),
                ])),
              );
            }
            return Column(children: [
              for (final story in stories)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    color: scheme.surface,
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: scheme.outlineVariant),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: ValueKey('stories-book-${story.id}'),
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => StoryLibraryReaderScreen(
                            entry: story, repository: _repository))),
                      child: Padding(
                        padding: const EdgeInsets.all(11),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 116,
                                height: 114,
                                child: story.coverImage == null
                                    ? ColoredBox(
                                        color: scheme.primaryContainer,
                                        child: Icon(Icons.auto_stories_rounded,
                                          color: accent, size: 36),
                                      )
                                    : SvgPicture.asset(
                                        story.coverImage!,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ar ? story.titleAr : story.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: accent,
                                  )),
                                const SizedBox(height: 5),
                                Text(ar ? story.title : story.titleAr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 12,
                                  )),
                                const SizedBox(height: 13),
                                Row(children: [
                                  Icon(Icons.book_rounded,
                                    color: accent, size: 15),
                                  const SizedBox(width: 5),
                                  Flexible(child: Text(
                                    ar ? 'A1 · فصلان · 10 فقرات'
                                       : 'A1 · 2 chapters · 10 paragraphs',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )),
                                ]),
                              ],
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ]);
          },
        ),
      ],
    );
  }
  /// Original WorldVoice novels are separate from external graded storybooks.
  Widget _originalNovelA1Shelf(bool ar, ColorScheme scheme) {
    return FutureBuilder<List<StoryLibraryEntry>>(
      future: _index,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final novels = snapshot.data!.where((entry) =>
          entry.level == 'A1' && entry.language == 'en' &&
          entry.format == 'novel').toList(growable: false);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (novels.isNotEmpty)
              Text(ar ? 'روايات WorldVoice الأصلية · A1'
                  : 'WorldVoice original novels · A1',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900)),
            const SizedBox(height: 9),
            for (final novel in novels)
              Card(
                margin: const EdgeInsets.only(bottom: 14),
                color: scheme.surfaceContainerLow,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: ValueKey('stories-novel-open-' + novel.id),
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(builder: (_) =>
                      StoryLibraryReaderScreen(
                        entry: novel, repository: _repository))),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: novel.coverImage != null
                          ? SvgPicture.asset(novel.coverImage!,
                              height: 115, width: 86, fit: BoxFit.cover)
                          : const SizedBox(width: 86, height: 115,
                              child: Icon(Icons.menu_book_rounded)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(novel.title, textDirection: TextDirection.ltr,
                            style: const TextStyle(fontWeight: FontWeight.w900,
                              fontSize: 17)),
                          const SizedBox(height: 6),
                          Text(novel.titleAr,
                            style: TextStyle(color: scheme.onSurfaceVariant)),
                          const SizedBox(height: 8),
                          Text(ar ? 'رواية كاملة · ${novel.chapterCount ?? 7} فصول · A1'
                                  : 'Complete novel · ${novel.chapterCount ?? 7} chapters · A1',
                            style: TextStyle(fontSize: 12,
                              color: scheme.onSurfaceVariant)),
                        ],
                      )),
                      const Icon(Icons.chevron_right_rounded),
                    ]),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Only English A1 is migrated in this stage. Keep A2–C2 unchanged.
  Widget _gradedA1Shelf(bool ar, ColorScheme scheme, Color accent) {
    return FutureBuilder<List<GradedStoryEntry>>(
      future: _gradedA1Index,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(ar
              ? 'تعذّر تحميل قصص A1، تحقق من ملفات المكتبة.'
              : 'Could not load A1 stories.');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final stories = snapshot.data!
            .where((entry) => entry.language == 'en' &&
                entry.level == 'A1' && entry.rightsStatus == 'cc_by_3_0')
            .toList(growable: false);
        if (stories.isEmpty) {
          return Text(ar ? 'لا توجد قصص A1 جاهزة بعد.'
              : 'No A1 stories available yet.');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _originalNovelA1Shelf(ar, scheme),
            Text(ar
                ? 'قصص A1 · صوت بشري ونص أصلي'
                : 'A1 graded stories · Original human narration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            Text(ar
                ? 'قصص قصيرة للتدرّب على القراءة والاستماع. اختر جملة لترجمتها إلى لغتك الأم. مستوياتنا تقديرية وليست تصنيف CEFR رسميًا.'
                : 'Short stories for reading and listening. Translate only the sentence you choose. CEFR A1 is an editorial learning estimate.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 14),
            for (final story in stories)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                clipBehavior: Clip.antiAlias,
                color: scheme.surfaceContainerLow,
                child: InkWell(
                  key: ValueKey('stories-a1-open-${story.id}'),
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(builder: (_) =>
                      GradedStoryReaderScreen(
                        entry: story, repository: _gradedRepository))),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          'https://www.storybookscanada.ca/images/${story.id.substring(5)}/01.jpg',
                          width: 105, height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              SizedBox(width: 105, height: 110,
                                child: ColoredBox(
                                  color: scheme.primaryContainer,
                                  child: Icon(Icons.auto_stories_rounded,
                                    color: accent, size: 42))),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(story.title,
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(story.titleAr,
                            style: TextStyle(
                                color: scheme.onSurfaceVariant, fontSize: 12)),
                          const SizedBox(height: 8),
                          Row(children: [
                            Icon(Icons.headphones_rounded,
                                size: 17, color: accent),
                            const SizedBox(width: 5),
                            Expanded(child: Text(
                              ar ? 'A1 · تسجيل بشري · CC BY'
                                  : 'A1 · human narration · CC BY',
                              style: TextStyle(fontSize: 11, color: accent),
                            )),
                          ]),
                        ],
                      )),
                      Icon(Icons.chevron_right_rounded, color: accent),
                    ]),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

}
