import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/data/novel_book_pagination.dart';
import 'package:worldvoice/features/learn/data/story_library_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Original A1 books have complete and correctly ordered page turns',
      () async {
    final repo = StoryLibraryRepository();
    final novels = (await repo.storiesFor(language: 'en', level: 'A1'))
        .where((entry) => entry.format == 'novel').toList();
    expect(novels.length, greaterThanOrEqualTo(5));

    for (final entry in novels) {
      final novel = jsonDecode(await rootBundle.loadString(entry.asset))
          as Map<String, dynamic>;
      final pages = buildNovelBookPages(novel);
      expect(pages.first.kind, 'cover');
      expect(pages[1].kind, 'title');
      expect(pages[2].kind, 'contents');
      expect(pages[3].kind, 'introduction');
      expect(pages.any((p) => p.kind == 'contents'), isTrue);
      expect(pages.last.kind, 'ending');
      final chapters = novel['chapters'] as List;
      final printed = pages.where((p) => p.kind == 'chapter').toList();
      expect(printed.length, greaterThanOrEqualTo(chapters.length));
      final originals = <String>[];
      final illustrated = <String>[];
      for (var i = 0; i < chapters.length; i++) {
        final chapter = chapters[i] as Map<String, dynamic>;
        originals.addAll((chapter['paragraphs'] as List).cast<String>());
        if (chapter['image'] is String) {
          illustrated.add(chapter['image'] as String);
        }
        if (chapter['extra_image'] is String) {
          illustrated.add(chapter['extra_image'] as String);
        }
        expect(printed.any((p) =>
            p.chapterNumber == i + 1 && !p.continued), isTrue);
      }
      final inBook = printed
          .expand((p) => p.parts)
          .where((p) => p.text != null)
          .map((p) => p.text!)
          .toList();
      final artInBook = printed
          .expand((p) => p.parts)
          .where((p) => p.imageAsset != null)
          .map((p) => p.imageAsset!)
          .toList();
      expect(inBook, originals, reason: entry.title);
      expect(artInBook, illustrated, reason: entry.title);
    }
  });
}
