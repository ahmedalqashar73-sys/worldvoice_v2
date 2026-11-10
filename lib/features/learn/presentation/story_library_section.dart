import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../data/academy_catalog.dart';
import '../data/story_library_repository.dart';
import '../domain/models/story_library_models.dart';
import 'story_novel_pdf_reader_screen.dart';

/// Only published PDF novels belong on the Academy > Stories shelves.
/// Legacy JSON stories and audio-graded books remain untouched for other
/// features but are not mixed into the novel library.
List<StoryLibraryEntry> visiblePdfNovelsFor(
  Iterable<StoryLibraryEntry> entries, {
  required String language,
  required String level,
}) {
  final code = language.trim().toLowerCase();
  final grade = level.trim().toUpperCase();
  return List<StoryLibraryEntry>.unmodifiable(entries.where((entry) =>
      entry.language == code &&
      entry.level == grade &&
      entry.format == 'novel' &&
      entry.asset ==
          'assets/stories/${entry.language}/${entry.level}/books/${entry.id}.pdf'));
}

/// Every level uses the same two-column PDF book-cover shelf as A1.
class StoryLibrarySection extends StatefulWidget {
  const StoryLibrarySection({super.key});

  @override
  State<StoryLibrarySection> createState() => _StoryLibrarySectionState();
}

class _StoryLibrarySectionState extends State<StoryLibrarySection> {
  final StoryLibraryRepository _repository = StoryLibraryRepository();
  late final Future<List<StoryLibraryEntry>> _index = _repository.loadIndex();

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
          ar ? 'مكتبة الروايات' : 'WorldVoice Library',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: accent,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          ar
              ? 'اختر اللغة والمستوى لقراءة الروايات الأصلية بصيغة PDF.'
              : 'Choose a language and level to read original PDF novels.',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        Text(ar ? 'اللغة' : 'Language',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
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
            ],
          ),
        ),
        const SizedBox(height: 17),
        Text(ar ? 'المستوى' : 'Level',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
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
            ],
          ),
        ),
        const SizedBox(height: 18),
        FutureBuilder<List<StoryLibraryEntry>>(
          future: _index,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Text(ar
                    ? 'تعذّر تحميل روايات المكتبة.'
                    : 'Could not load WorldVoice Library.'),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final novels = visiblePdfNovelsFor(
              snapshot.data!,
              language: _language,
              level: _level,
            );
            if (novels.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 35),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.auto_stories_outlined,
                          size: 42, color: accent),
                      const SizedBox(height: 10),
                      Text(
                        ar
                            ? 'لا توجد روايات PDF منشورة لهذا المستوى بعد.'
                            : 'No PDF novels published at this level yet.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                // Match the approved A1 design, while preventing overflow
                // on unusually narrow devices.
                final columns = constraints.maxWidth >= 315 ? 2 : 1;
                final width =
                    (constraints.maxWidth - (columns - 1) * 12) / columns;
                return Wrap(
                  key: const ValueKey('stories-pdf-novel-grid'),
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final novel in novels)
                      SizedBox(
                        width: width,
                        child: _NovelCoverCard(
                          novel: novel,
                          scheme: scheme,
                          ar: ar,
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _NovelCoverCard extends StatelessWidget {
  const _NovelCoverCard({
    required this.novel,
    required this.scheme,
    required this.ar,
  });

  final StoryLibraryEntry novel;
  final ColorScheme scheme;
  final bool ar;

  @override
  Widget build(BuildContext context) {
    final chapters = novel.chapterCount;
    final chapterLabel = chapters == null
        ? novel.level
        : '${novel.level} · $chapters${ar ? ' فصول' : ' chapters'}';

    return Card(
      key: ValueKey('stories-book-${novel.id}'),
      margin: EdgeInsets.zero,
      elevation: 1.5,
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        key: ValueKey('stories-novel-open-${novel.id}'),
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => StoryNovelPdfReaderScreen(entry: novel),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            height: 242,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: SizedBox(
                    height: 155,
                    width: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: IgnorePointer(
                        child: RepaintBoundary(
                          child: PdfViewer.asset(
                            novel.asset,
                            initialPageNumber: 1,
                            params: const PdfViewerParams(
                              margin: 0,
                              pageAnchor: PdfPageAnchor.all,
                              panEnabled: false,
                              scaleEnabled: false,
                              backgroundColor: Colors.transparent,
                              pageDropShadow: BoxShadow(
                                color: Colors.transparent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  novel.title,
                  textDirection: TextDirection.ltr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const Spacer(),
                Text(
                  chapterLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
