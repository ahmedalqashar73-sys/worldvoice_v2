import 'package:flutter/material.dart';

import '../data/academy_catalog.dart';
import '../data/story_library_repository.dart';
import '../domain/models/story_library_models.dart';
import 'story_library_reader_screen.dart';

/// Independent graded stories; existing lesson stories remain unchanged.
class StoryLibrarySection extends StatefulWidget {
  const StoryLibrarySection({super.key});

  @override
  State<StoryLibrarySection> createState() => _StoryLibrarySectionState();
}

class _StoryLibrarySectionState extends State<StoryLibrarySection> {
  late final StoryLibraryRepository _repository = StoryLibraryRepository();
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
            final stories = snapshot.data!.where((entry) =>
              entry.language == _language && entry.level == _level)
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
                    child: ListTile(
                      key: ValueKey('stories-book-${story.id}'),
                      contentPadding: const EdgeInsets.all(15),
                      leading: CircleAvatar(
                        backgroundColor: scheme.primaryContainer,
                        child: Icon(Icons.menu_book_rounded, color: accent)),
                      title: Text(ar ? story.titleAr : story.title,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(ar
                          ? '${story.title} · ${story.level}'
                          : '${story.titleAr} · ${story.level}'),
                      trailing: Icon(Icons.chevron_right_rounded, color: accent),
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => StoryLibraryReaderScreen(
                            entry: story, repository: _repository))),
                    ),
                  ),
                ),
            ]);
          },
        ),
      ],
    );
  }
}
