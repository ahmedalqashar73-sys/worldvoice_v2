import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/data/novel_book_pagination.dart';
import 'package:worldvoice/features/learn/data/story_library_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Original English A1 library keeps all five novels and all paragraphs',
      () async {
    final repository = StoryLibraryRepository();
    final library = await repository.storiesFor(
      language: 'en',
      level: 'A1',
    );
    final novels =
        library.where((entry) => entry.format == 'novel').toList();
    expect(novels.length, 5);

    const expectedTitles = <String>{
      'The Blue Envelope',
      'The Empty House',
      'The Last Train',
      'The Red Umbrella',
      'Daniel Carter: The Kidnapping Case',
    };
    expect(novels.map((novel) => novel.title).toSet(), expectedTitles);

    for (final novel in novels) {
      final raw = jsonDecode(await rootBundle.loadString(novel.asset))
          as Map<String, dynamic>;
      final chapters = (raw['chapters'] as List).cast<Map<String, dynamic>>();
      final pages = buildNovelBookPages(raw);

      expect(pages.first.kind, 'cover', reason: novel.id);
      expect(pages[1].kind, 'title', reason: novel.id);
      expect(pages[2].kind, 'contents', reason: novel.id);
      expect(pages.last.kind, 'ending', reason: novel.id);
      expect(chapters.length, greaterThanOrEqualTo(5), reason: novel.id);

      final chapterPages =
          pages.where((page) => page.kind == 'chapter').toList();
      expect(
        chapterPages.where((page) => !page.continued).length,
        chapters.length,
        reason: novel.id,
      );
      for (var i = 0; i < chapters.length; i++) {
        final original = (chapters[i]['paragraphs'] as List).cast<String>();
        final rendered = chapterPages
            .where((page) => page.chapterNumber == i + 1)
            .expand((page) => page.parts)
            .where((part) => part.text != null)
            .map((part) => part.text!)
            .toList();
        expect(rendered, original,
            reason: novel.id + ': chapter ' + (i + 1).toString());

        final expectedImages = <String>[
          if (chapters[i]['image'] is String) chapters[i]['image'] as String,
          if (chapters[i]['extra_image'] is String)
            chapters[i]['extra_image'] as String,
        ];
        final actualImages = chapterPages
            .where((page) => page.chapterNumber == i + 1)
            .expand((page) => page.parts)
            .where((part) => part.imageAsset != null)
            .map((part) => part.imageAsset!)
            .toList();
        expect(actualImages, expectedImages,
            reason: novel.id + ': chapter ' + (i + 1).toString() +
              ' illustrations');
      }
    }
  });
}
