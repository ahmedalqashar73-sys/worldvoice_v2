import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/data/story_library_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Daniel Carter A1 has five chapters, seven scenes, and a cover', () async {
    final repo = StoryLibraryRepository();
    final entries = await repo.storiesFor(language: 'en', level: 'A1');
    final novel = entries.singleWhere((e) => e.id == 'daniel_carter');
    expect(novel.format, 'novel');
    expect(novel.chapterCount, 5);
    final book = jsonDecode(await rootBundle.loadString(novel.asset))
        as Map<String, dynamic>;
    expect(book['title'], novel.title);
    final chapters = book['chapters'] as List;
    expect(chapters.length, 5);
    var scenes = 0;
    for (var i = 0; i < chapters.length; i++) {
      final chapter = chapters[i] as Map<String, dynamic>;
      expect(chapter['number'], i + 1);
      expect((chapter['paragraphs'] as List).length, greaterThanOrEqualTo(5));
      expect((await rootBundle.load(chapter['image'] as String)).lengthInBytes,
          greaterThan(200));
      scenes++;
      if (chapter['extra_image'] is String) {
        expect((await rootBundle.load(chapter['extra_image'] as String)).lengthInBytes,
            greaterThan(200));
        scenes++;
      }
    }
    expect(scenes, 7);
    expect((await rootBundle.load(novel.coverImage!)).lengthInBytes,
        greaterThan(200));
    expect((book['vocabulary'] as List).length, 40);
    expect((book['questions'] as List).length, 15);
    expect((book['final_test'] as List).length, 20);
  });
}
