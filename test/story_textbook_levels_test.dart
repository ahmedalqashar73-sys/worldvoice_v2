import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/data/story_library_repository.dart';
import 'package:worldvoice/features/learn/domain/models/story_textbook_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('English A2 has five complete books with ten graded paragraphs each',
      () async {
    final repository = StoryLibraryRepository();
    final allEntries = await repository.storiesFor(language: 'en', level: 'A2');
    final entries = allEntries.where((item) => item.format == 'textbook').toList();
    final novels = allEntries.where((item) => item.format == 'novel').toList();
    expect(allEntries, hasLength(12));
    expect(entries, hasLength(5));
    expect(novels, hasLength(7));
    expect(entries.map((item) => item.id).toSet(), hasLength(5));
    expect(novels.map((item) => item.id).toSet(), equals(<String>{
      'the_trial_of_the_mask',
      'the_silk_road_home',
      'seven_days_across_the_atlas',
      'the_grand_hotel_of_rio',
      'beyond_the_frozen_pass',
      'the_newspaper_in_alexandria',
      'the_last_radio_message',
    }));

    final titles = <String>{};
    for (final entry in entries) {
      final book = await repository.loadTextbook(entry);
      expect(book.level, 'A2');
      expect(book.language, 'en');
      expect(titles.add(book.title), isTrue);
      expect(book.chapters.map((chapter) => chapter.paragraphCount), [5, 5]);
      expect(book.chapters.map((chapter) => chapter.blocks.length), [2, 2]);
      expect(book.vocabulary.length, greaterThanOrEqualTo(20));
      expect(book.questions.length, 8);
      expect(book.questions.map((q) => q.answer).toSet().length,
          greaterThanOrEqualTo(3));
      expect(book.meanings, hasLength(book.vocabulary.length));

      for (final chapter in book.chapters) {
        final voices = chapter.blocks
            .expand((block) => block.paragraphs)
            .expand((paragraph) => paragraph.segments)
            .map((segment) => segment.speaker)
            .toSet();
        expect(voices, contains(StoryTextbookSpeaker.female));
        expect(voices, contains(StoryTextbookSpeaker.male));
        expect(voices, contains(StoryTextbookSpeaker.narrator));
        for (final block in chapter.blocks) {
          expect(block.paragraphs.length, inInclusiveRange(2, 3));
          expect(block.image, isNotNull);
          final graphic = await rootBundle.loadString(block.image!);
          expect(graphic, contains('<svg'));
          expect(graphic, contains('</svg>'));
          for (final paragraph in block.paragraphs) {
            expect(paragraph.translationAr.trim(), isNotEmpty);
            final count = paragraph.spokenText.trim()
                .split(RegExp(r'\s+')).length;
            expect(count, inInclusiveRange(40, 60));
            final highlighted = RegExp(r'\*\*([^*]+)\*\*')
                .allMatches(paragraph.segments.map((s) => s.text).join(' '))
                .map((match) => match.group(1)!.toLowerCase()).toList();
            expect(highlighted.length, inInclusiveRange(2, 4));
            for (final keyword in highlighted) {
              expect(book.meanings, contains(keyword));
            }
          }
        }
      }
    }
  });

  test('English B1 has five original readers, 10 intermediate paragraphs and illustrations', () async {
    final repository = StoryLibraryRepository();
    final entries = await repository.storiesFor(language: 'en', level: 'B1');
    expect(entries, hasLength(5));
    expect(entries.map((e) => e.title).toSet(), hasLength(5));

    for (final entry in entries) {
      expect(entry.format, 'textbook');
      final book = await repository.loadTextbook(entry);
      expect(book.level, 'B1');
      expect(book.language, 'en');
      expect(book.chapters.map((c) => c.paragraphCount), [5, 5]);
      expect(book.chapters.map((c) => c.blocks.length), [2, 2]);
      expect(book.vocabulary.length, greaterThanOrEqualTo(20));
      expect(book.questions.length, 8);
      expect(book.questions.map((q) => q.answer).toSet().length,
          greaterThanOrEqualTo(3));
      final words = book.meanings;
      expect(words, hasLength(book.vocabulary.length));

      for (final chapter in book.chapters) {
        final speakers = chapter.blocks
            .expand((block) => block.paragraphs)
            .expand((paragraph) => paragraph.segments)
            .map((segment) => segment.speaker)
            .toSet();
        expect(speakers, containsAll(StoryTextbookSpeaker.values));

        for (final block in chapter.blocks) {
          expect(block.paragraphs.length, inInclusiveRange(2, 3));
          expect(block.image, isNotNull);
          final illustration = await rootBundle.loadString(block.image!);
          expect(illustration, contains('<svg'));
          expect(illustration, contains('</svg>'));

          for (final paragraph in block.paragraphs) {
            expect(paragraph.translationAr, isNotEmpty);
            final count = paragraph.spokenText
                .trim().split(RegExp(r'\s+')).length;
            expect(count, inInclusiveRange(60, 90));
            final rich = paragraph.segments.map((s) => s.text).join(' ');
            final marked = RegExp(r'\*\*([^*]+)\*\*')
                .allMatches(rich)
                .map((match) => match.group(1)!.toLowerCase()).toList();
            expect(marked.length, inInclusiveRange(2, 4));
            for (final word in marked) {
              expect(book.meanings, contains(word));
            }
          }
        }
      }
    }
  });


  test('English B2 has five verified upper-intermediate books with accessible continuous reading', () async {
    final repository = StoryLibraryRepository();
    final entries = await repository.storiesFor(language: 'en', level: 'B2');
    expect(entries, hasLength(5));
    expect(entries.map((e) => e.id).toSet(), hasLength(5));
    expect(entries.map((e) => e.title).toSet(), hasLength(5));

    for (final entry in entries) {
      expect(entry.format, 'textbook');
      final book = await repository.loadTextbook(entry);
      expect(book.language, 'en');
      expect(book.level, 'B2');
      expect(book.chapters.map((c) => c.paragraphCount), [5, 5]);
      expect(book.chapters.map((c) => c.blocks.length), [2, 2]);
      expect(book.vocabulary.length, greaterThanOrEqualTo(20));
      expect(book.questions.length, 8);
      expect(book.questions.map((q) => q.answer).toSet().length,
          greaterThanOrEqualTo(3));

      final meaningKeys = book.meanings;
      expect(meaningKeys, hasLength(book.vocabulary.length));
      for (final chapter in book.chapters) {
        final speakers = chapter.blocks.expand((b) => b.paragraphs)
            .expand((p) => p.segments).map((s) => s.speaker).toSet();
        expect(speakers, containsAll(StoryTextbookSpeaker.values));
        for (final block in chapter.blocks) {
          expect(block.paragraphs.length, inInclusiveRange(2, 3));
          expect(block.image, isNotNull);
          final illustration = await rootBundle.loadString(block.image!);
          expect(illustration, contains('<svg'));
          expect(illustration, contains('</svg>'));
          for (final paragraph in block.paragraphs) {
            expect(paragraph.translationAr, isNotEmpty);
            final words = paragraph.spokenText.trim()
                .split(RegExp(r'\s+')).length;
            expect(words, inInclusiveRange(90, 130));
            final richText = paragraph.segments.map((s) => s.text).join(' ');
            final marked = RegExp(r'\*\*([^*]+)\*\*')
                .allMatches(richText)
                .map((match) => match.group(1)!.toLowerCase()).toList();
            expect(marked.length, inInclusiveRange(2, 4));
            for (final word in marked) {
              expect(meaningKeys, contains(word));
            }
          }
        }
      }
    }
  });


  test('English C1 offers five complete advanced stories with full assets', () async {
    final repository = StoryLibraryRepository();
    final entries = await repository.storiesFor(language: 'en', level: 'C1');
    expect(entries, hasLength(5));
    expect(entries.map((entry) => entry.id).toSet(), hasLength(5));
    expect(entries.map((entry) => entry.title).toSet(), hasLength(5));
    for (final entry in entries) {
      expect(entry.format, 'textbook');
      expect(entry.coverImage, isNotNull);
      final cover = await rootBundle.loadString(entry.coverImage!);
      expect(cover, contains('<svg'));
      final book = await repository.loadTextbook(entry);
      expect(book.language, 'en');
      expect(book.level, 'C1');
      expect(book.chapters.map((c) => c.paragraphCount), [5, 5]);
      expect(book.chapters.map((c) => c.blocks.length), [2, 2]);
      expect(book.vocabulary.length, greaterThanOrEqualTo(20));
      expect(book.questions, hasLength(8));
      expect(book.questions.map((q) => q.answer).toSet().length,
          greaterThanOrEqualTo(3));
      for (final chapter in book.chapters) {
        final speakers = chapter.blocks
            .expand((block) => block.paragraphs)
            .expand((paragraph) => paragraph.segments)
            .map((segment) => segment.speaker).toSet();
        expect(speakers, containsAll(StoryTextbookSpeaker.values));
        for (final block in chapter.blocks) {
          expect(block.paragraphs.length, inInclusiveRange(2, 3));
          expect(block.image, isNotNull);
          final svg = await rootBundle.loadString(block.image!);
          expect(svg, contains('<svg'));
          expect(svg, contains('</svg>'));
          for (final paragraph in block.paragraphs) {
            expect(paragraph.translationAr, isNotEmpty);
            final wordCount = paragraph.spokenText
                .trim().split(RegExp(r'\s+')).length;
            expect(wordCount, inInclusiveRange(130, 180));
            final richText = paragraph.segments.map((s) => s.text).join(' ');
            final highlighted = RegExp(r'\*\*([^*]+)\*\*')
                .allMatches(richText)
                .map((match) => match.group(1)!.toLowerCase()).toList();
            expect(highlighted.length, inInclusiveRange(2, 4));
            for (final word in highlighted) {
              expect(book.meanings, contains(word));
            }
          }
        }
      }
    }
  });


  test('English C2 has five advanced literary readers with complete illustrations', () async {
    final repository = StoryLibraryRepository();
    final entries = await repository.storiesFor(language: 'en', level: 'C2');
    expect(entries, hasLength(5));
    expect(entries.map((e) => e.id).toSet(), hasLength(5));
    expect(entries.map((e) => e.title).toSet(), hasLength(5));
    for (final entry in entries) {
      expect(entry.format, 'textbook');
      expect(entry.coverImage, isNotNull);
      final cover = await rootBundle.loadString(entry.coverImage!);
      expect(cover, contains('<svg'));
      final book = await repository.loadTextbook(entry);
      expect(book.language, 'en');
      expect(book.level, 'C2');
      expect(book.chapters.map((c) => c.paragraphCount), [5, 5]);
      expect(book.chapters.map((c) => c.blocks.length), [2, 2]);
      expect(book.vocabulary.length, greaterThanOrEqualTo(20));
      expect(book.questions, hasLength(8));
      expect(book.questions.map((q) => q.answer).toSet().length,
          greaterThanOrEqualTo(3));
      for (final chapter in book.chapters) {
        final speakers = chapter.blocks.expand((b) => b.paragraphs)
            .expand((p) => p.segments).map((s) => s.speaker).toSet();
        expect(speakers, containsAll(StoryTextbookSpeaker.values));
        for (final block in chapter.blocks) {
          expect(block.paragraphs.length, inInclusiveRange(2, 3));
          expect(block.image, isNotNull);
          final illustration = await rootBundle.loadString(block.image!);
          expect(illustration, contains('<svg'));
          expect(illustration, contains('</svg>'));
          for (final paragraph in block.paragraphs) {
            expect(paragraph.translationAr, isNotEmpty);
            final words = paragraph.spokenText
                .trim().split(RegExp(r'\s+')).length;
            expect(words, inInclusiveRange(150, 220));
            final richText = paragraph.segments.map((s) => s.text).join(' ');
            final highlights = RegExp(r'\*\*([^*]+)\*\*')
                .allMatches(richText)
                .map((m) => m.group(1)!.toLowerCase()).toList();
            expect(highlights.length, inInclusiveRange(2, 4));
            for (final highlighted in highlights) {
              expect(book.meanings, contains(highlighted));
            }
          }
        }
      }
    }
  });

}
