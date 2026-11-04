import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/data/story_library_repository.dart';
import 'package:worldvoice/features/learn/domain/models/story_library_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('English A1 has nine registered illustrations and valid motion types',
      () async {
    final repository = StoryLibraryRepository();
    final entries = await repository.storiesFor(language: 'en', level: 'A1');
    final legacy = entries.firstWhere(
      (entry) => entry.id == 'the_small_green_bag',
    );
    final story = await repository.loadStory(legacy);
    expect(story.pages, hasLength(9));
    for (final page in story.pages) {
      expect(page.image, isNotNull);
      expect(page.image, startsWith('assets/stories/en/A1/illustrations/'));
      final svg = await rootBundle.loadString(page.image!);
      expect(svg, contains('<svg'));
      expect(svg, contains('</svg>'));
      expect(page.animation, isA<StoryLibraryAnimation>());
    }
  });
}
