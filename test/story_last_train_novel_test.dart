import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/data/story_library_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('The Last Train A1 is an original complete seven chapter novel', () async {
    final repository = StoryLibraryRepository();
    final stories = await repository.storiesFor(language: 'en', level: 'A1');
    final novel = stories.singleWhere((entry) => entry.id == 'the_last_train');
    expect(novel.format, 'novel');
    expect(novel.chapterCount, 7);
    expect(stories.any((entry) => entry.id == 'the_blue_envelope'), isTrue);
    expect(stories.any((entry) => entry.id == 'the_empty_house'), isTrue);

    final decoded = jsonDecode(await rootBundle.loadString(novel.asset))
        as Map<String, dynamic>;
    expect(decoded['title'], novel.title);
    expect(decoded['level'], 'A1');
    final chapters = decoded['chapters'] as List;
    expect(chapters.length, 7);
    var totalWords = 0;
    for (var i = 0; i < chapters.length; i++) {
      final chapter = chapters[i] as Map<String, dynamic>;
      expect(chapter['number'], i + 1);
      final paragraphs = chapter['paragraphs'] as List;
      expect(paragraphs.length, greaterThanOrEqualTo(5));
      for (final paragraph in paragraphs) {
        totalWords += (paragraph as String).trim().split(RegExp(r'\s+')).length;
      }
      final drawing = await rootBundle.load(chapter['image'] as String);
      expect(drawing.lengthInBytes, greaterThan(1000));
    }
    expect(totalWords, greaterThan(3500));
    expect((decoded['vocabulary'] as List).length, 40);
    expect((decoded['questions'] as List).length, 12);
    expect((decoded['final_test'] as List).length, 16);
    final cover = await rootBundle.load(novel.coverImage!);
    expect(cover.lengthInBytes, greaterThan(1000));
  });
}
