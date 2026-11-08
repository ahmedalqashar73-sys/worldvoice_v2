import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/data/story_library_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('The Blue Envelope A1 has seven full chapters and working assets', () async {
    final repo = StoryLibraryRepository();
    final entries = await repo.storiesFor(language: 'en', level: 'A1');
    final novel = entries.singleWhere((e) => e.id == 'the_blue_envelope');
    expect(novel.format, 'novel');
    final decoded = jsonDecode(await rootBundle.loadString(novel.asset))
        as Map<String, dynamic>;
    expect(decoded['title'], novel.title);
    final chapters = decoded['chapters'] as List;
    expect(chapters.length, 7);
    for (var i = 0; i < chapters.length; i++) {
      final chapter = chapters[i] as Map<String, dynamic>;
      expect(chapter['number'], i + 1);
      expect((chapter['paragraphs'] as List).length, greaterThanOrEqualTo(5));
      expect((await rootBundle.loadString(chapter['image'] as String)),
        contains('<svg'));
    }
    expect((decoded['vocabulary'] as List).length, 40);
    expect((decoded['questions'] as List).length, greaterThanOrEqualTo(10));
    expect(await rootBundle.loadString(novel.coverImage!), contains('<svg'));
  });
}
