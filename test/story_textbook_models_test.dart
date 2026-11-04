import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/data/story_library_repository.dart';
import 'package:worldvoice/features/learn/domain/models/story_library_models.dart';
import 'package:worldvoice/features/learn/domain/models/story_textbook_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('both indexed A1 formats load with their correct readers', () async {
    final repository = StoryLibraryRepository();
    final entries = await repository.storiesFor(language: 'en', level: 'A1');
    expect(entries, hasLength(2));
    final legacy = entries.firstWhere((e) => e.format == 'legacy');
    final textbook = entries.firstWhere((e) => e.format == 'textbook');
    expect((await repository.loadStory(legacy)).pages, hasLength(9));
    expect((await repository.loadTextbook(textbook)).chapters, hasLength(2));
  });

  test('Saturday Garden: two chapters, 20 graded paragraphs and 10 images',
      () async {
    final repository = StoryLibraryRepository();
    final entry = (await repository.loadIndex()).firstWhere(
      (e) => e.id == 'en-a1-001',
    );
    final book = await repository.loadTextbook(entry);
    expect(book.language, 'en');
    expect(book.level, 'A1');
    expect(book.chapters.map((c) => c.paragraphCount), [10, 10]);
    expect(book.chapters.map((c) => c.blocks.length), [5, 5]);
    expect(book.vocabulary.length, greaterThanOrEqualTo(20));
    expect(book.questions.length, 8);
    expect(book.questions.every((q) => q.options.length == 4), isTrue);
    final roles = book.chapters.expand((c) => c.blocks).expand(
      (b) => b.paragraphs,
    ).expand((p) => p.segments).map((s) => s.speaker).toSet();
    expect(roles, containsAll(StoryTextbookSpeaker.values));
    for (final chapter in book.chapters) {
      final speakers = chapter.blocks
          .expand((b) => b.paragraphs)
          .expand((p) => p.segments)
          .map((s) => s.speaker)
          .toSet();
      expect(speakers, contains(StoryTextbookSpeaker.male));
      expect(speakers, contains(StoryTextbookSpeaker.female));
      for (final block in chapter.blocks) {
        expect(block.paragraphs, hasLength(2));
        expect(block.image, isNotNull);
        final image = await rootBundle.loadString(block.image!);
        expect(image, contains('<svg'));
        expect(image, contains('</svg>'));
        for (final paragraph in block.paragraphs) {
          expect(paragraph.spokenText, isNot(contains('**')));
          final words = paragraph.spokenText.trim().split(RegExp(r'\s+'));
          expect(words.length, inInclusiveRange(25, 40));
          final raw = paragraph.segments.map((s) => s.text).join(' ');
          final highlights = RegExp(r'\*\*([^*]+)\*\*').allMatches(raw).toList();
          expect(highlights.length, inInclusiveRange(2, 4));
          for (final match in highlights) {
            expect(book.meanings, contains(match.group(1)!.toLowerCase()));
          }
        }
      }
    }
  });

  test('textbook parser rejects a missing vocabulary translation', () async {
    final source = jsonDecode(
      await rootBundle.loadString('assets/stories/en/A1/en-a1-001.json'),
    ) as Map<String, dynamic>;
    final story = source['story'] as Map<String, dynamic>;
    final words = story['vocabulary'] as List<dynamic>;
    words.removeWhere((item) => (item as Map<String, dynamic>)['word'] == 'garden');
    expect(() => StoryTextbookBook.fromJson(source), throwsFormatException);
  });

  test('previous standalone stories stay in legacy format', () async {
    final repository = StoryLibraryRepository();
    final entries = await repository.loadIndex();
    final old = entries.firstWhere((e) => e.id == 'the_small_green_bag');
    expect(old.format, 'legacy');
    expect(() => repository.loadTextbook(old), throwsFormatException);
    expect(StoryLibraryEntry.levels, ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']);
  });
}
