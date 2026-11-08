import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/data/story_library_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('The Empty House A1 novel is complete and all art assets load', () async {
    final repository = StoryLibraryRepository();
    final list = await repository.storiesFor(language: 'en', level: 'A1');
    final novels = list.where((e) => e.format == 'novel').toList();
    final emptyHouse = novels.singleWhere((e) => e.id == 'the_empty_house');
    expect(emptyHouse.chapterCount, 7);
    expect(novels.any((e) => e.id == 'the_blue_envelope'), isTrue);

    final decoded = jsonDecode(
      await rootBundle.loadString(emptyHouse.asset),
    ) as Map<String, dynamic>;

    expect(decoded['title'], 'The Empty House');
    expect(decoded['level'], 'A1');
    final chapters = decoded['chapters'] as List;
    expect(chapters.length, 7);
    for (var i = 0; i < chapters.length; i++) {
      final chapter = chapters[i] as Map<String, dynamic>;
      expect(chapter['number'], i + 1);
      expect((chapter['paragraphs'] as List).length, greaterThanOrEqualTo(5));
      final scene = await rootBundle.loadString(chapter['image'] as String);
      expect(scene, contains('<svg'));
    }
    expect((decoded['vocabulary'] as List).length, 40);
    expect((decoded['questions'] as List).length, 15);
    expect((decoded['final_test'] as List).length, 20);
    expect(await rootBundle.loadString(emptyHouse.coverImage!), contains('<svg'));
  });
}
