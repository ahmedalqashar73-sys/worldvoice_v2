import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/data/story_library_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Daniel Carter complete A1 book is indexed and readable offline', () async {
    final repo = StoryLibraryRepository();
    final entries = await repo.storiesFor(language: 'en', level: 'A1');
    final novel = entries.singleWhere((e) => e.id == 'daniel_carter');
    expect(novel.format, 'novel');
    expect(novel.chapterCount, 5);
    final data = jsonDecode(await rootBundle.loadString(novel.asset)) as Map<String,dynamic>;
    expect(data['title'], novel.title);
    final chapters = data['chapters'] as List;
    expect(chapters.length, 5);
    for (var i = 0; i < chapters.length; i++) {
      final chapter = chapters[i] as Map<String, dynamic>;
      expect(chapter['number'], i+1);
      expect((chapter['paragraphs'] as List).length, greaterThanOrEqualTo(5));
    }
    expect((data['vocabulary'] as List).length, 40);
    expect((data['questions'] as List).length, 15);
    expect((data['final_test'] as List).length, 20);
  });
}
