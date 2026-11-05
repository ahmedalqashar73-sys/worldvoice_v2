import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/data/story_library_repository.dart';
import 'package:worldvoice/features/learn/domain/models/story_textbook_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('English A2 has five complete books with ten graded paragraphs each',
      () async {
    final repository = StoryLibraryRepository();
    final entries = await repository.storiesFor(language: 'en', level: 'A2');
    expect(entries, hasLength(5));
    expect(entries.every((item) => item.format == 'textbook'), isTrue);
    expect(entries.map((item) => item.id).toSet(), hasLength(5));

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
}
