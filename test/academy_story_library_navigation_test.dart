import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/data/story_library_repository.dart';
import 'package:worldvoice/features/learn/presentation/story_library_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Academy Stories shows only published PDF novels at every level',
      () async {
    final index = await StoryLibraryRepository().loadIndex();

    final expected = <String, int>{
      'A1': 5,
      'A2': 7,
      'B1': 1,
      'B2': 0,
      'C1': 0,
      'C2': 0,
    };
    for (final entry in expected.entries) {
      final novels = visiblePdfNovelsFor(
        index,
        language: 'en',
        level: entry.key,
      );
      expect(novels, hasLength(entry.value), reason: entry.key);
      expect(
        novels.every((novel) =>
            novel.format == 'novel' &&
            novel.level == entry.key &&
            novel.asset ==
                'assets/stories/en/${entry.key}/books/${novel.id}.pdf'),
        isTrue,
        reason: 'Show original PDF novels, never JSON/audio storybooks.',
      );
    }
    final a2 = visiblePdfNovelsFor(index, language: 'EN', level: 'a2');
    expect(a2.map((book) => book.id).toSet(), hasLength(7));
    expect(
      visiblePdfNovelsFor(index, language: 'es', level: 'A1'),
      isEmpty,
      reason: 'Do not silently use English books for other languages.',
    );
    expect(
      visiblePdfNovelsFor(index, language: 'en', level: 'B1')
          .single.id,
      'the_boys_of_the_cedar_river',
    );
  });
}
