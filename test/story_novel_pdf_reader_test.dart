import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/presentation/story_novel_pdf_reader_screen.dart';
import 'package:worldvoice/features/learn/data/story_library_repository.dart';
import 'package:worldvoice/features/learn/domain/models/story_library_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const titles = <String>[
    'the_blue_envelope',
    'the_empty_house',
    'the_last_train',
    'the_red_umbrella',
    'daniel_carter',
  ];

  test('every original A1 novel has a stable PDF asset location', () {
    for (final title in titles) {
      expect(
        novelPdfAssetPath(title),
        'assets/stories/en/A1/books/' + title + '.pdf',
      );
    }
    expect(() => novelPdfAssetPath('../dangerous'), throwsArgumentError);
  });

  test('published novels use language- and level-specific PDF paths',
      () async {
    final catalog = await StoryLibraryRepository().loadIndex();
    final novels = catalog.where((entry) => entry.format == 'novel');
    expect(novels, isNotEmpty);
    for (final book in novels) {
      expect(
        novelPdfAssetPathForEntry(book),
        'assets/stories/' + book.language + '/' + book.level +
            '/books/' + book.id + '.pdf',
      );
    }
    for (final code in const ['en', 'es', 'fr', 'ko', 'zh', 'ar']) {
      final entry = StoryLibraryEntry(
        id: 'sample_story',
        language: code,
        level: 'A2',
        title: 'Sample Story',
        titleAr: 'قصة تجريبية',
        asset: 'assets/stories/' + code + '/A2/sample_story.json',
        format: 'novel',
      );
      expect(novelPdfAssetPathForEntry(entry),
          'assets/stories/' + code + '/A2/books/sample_story.pdf');
    }
    final invalid = StoryLibraryEntry(
      id: 'sample_story',
      language: 'en',
      level: 'A1',
      title: 'Sample Story',
      titleAr: 'قصة تجريبية',
      asset: 'assets/stories/en/A1/some_other_story.json',
      format: 'novel',
    );
    expect(() => novelPdfAssetPathForEntry(invalid), throwsArgumentError);
  });

  test('room/live book picker never mixes session languages', () {
    StoryLibraryEntry novel(String language, String id) => StoryLibraryEntry(
      id: id,
      language: language,
      level: 'A1',
      title: id,
      titleAr: id,
      asset: 'assets/stories/' + language + '/A1/' + id + '.json',
      format: 'novel',
    );
    final books = <StoryLibraryEntry>[
      novel('en', 'english_novel'),
      novel('es', 'spanish_novel'),
      novel('ar', 'arabic_novel'),
      const StoryLibraryEntry(
        id: 'english_short',
        language: 'en',
        level: 'A1',
        title: 'Short',
        titleAr: 'قصير',
        asset: 'assets/stories/en/A1/english_short.json',
        format: 'textbook',
      ),
    ];
    expect(libraryNovelsForSessionLanguage(books, 'en-US')
        .map((book) => book.id), ['english_novel']);
    expect(libraryNovelsForSessionLanguage(books, 'es')
        .map((book) => book.id), ['spanish_novel']);
    expect(libraryNovelsForSessionLanguage(books, 'ar')
        .map((book) => book.id), ['arabic_novel']);
    expect(libraryNovelsForSessionLanguage(books, 'ko'), isEmpty);
  });

  test('all five original PDF books are bundled and have valid headers',
      () async {
    for (final title in titles) {
      final data = await rootBundle.load(novelPdfAssetPath(title));
      expect(data.lengthInBytes, greaterThan(100000), reason: title);
      final prefix = data.buffer.asUint8List(data.offsetInBytes, 5);
      expect(String.fromCharCodes(prefix), '%PDF-', reason: title);
    }
  });
}
