import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/data/story_library_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('The Red Umbrella full A1 novel and all its images are bundled', () async {
    final repository = StoryLibraryRepository();
    final entries = await repository.storiesFor(language: 'en', level: 'A1');
    final entry = entries.singleWhere((e) => e.id == 'the_red_umbrella');
    expect(entry.format, 'novel');
    expect(entry.chapterCount, 7);
    final raw = await rootBundle.loadString(entry.asset);
    final book = jsonDecode(raw) as Map<String, dynamic>;
    expect(book['id'], entry.id);
    expect((book['chapters'] as List).length, 7);
    expect((book['vocabulary'] as List).length, 40);
    expect((book['questions'] as List).length, 15);
    expect((book['final_test'] as List).length, 20);
    for (var i = 0; i < 7; i++) {
      final chapter = book['chapters'][i] as Map<String, dynamic>;
      expect(chapter['number'], i + 1);
      expect((chapter['paragraphs'] as List).length, greaterThanOrEqualTo(5));
      final image = chapter['image'] as String;
      expect(image, startsWith('assets/stories/en/A1/illustrations/'));
      expect((await rootBundle.load(image)).lengthInBytes, greaterThan(1000));
    }
    expect((await rootBundle.load(entry.coverImage!)).lengthInBytes,
        greaterThan(1000));
  });
}
