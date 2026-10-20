import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/data/academy_english_advanced_models.dart';
import 'package:worldvoice/features/learn/data/academy_english_advanced_learning_path.dart';

void main() {
  for (final level in <String>['A2', 'B1', 'B2', 'C1']) {
    test('$level links exactly forty graded words to reading, dialogue and podcast', () {
      final lessons = EnglishAdvancedSyllabus.forLevel(level);
      expect(lessons, hasLength(30));
      for (final lesson in lessons) {
        expect(EnglishAdvancedLearningPath.supports(lesson), isTrue);
        final words = EnglishAdvancedLearningPath.wordsFor(lesson);
        expect(words, hasLength(40), reason: lesson.id);
        expect(words.map((w) => w.term.toLowerCase()).toSet(),
            hasLength(40), reason: lesson.id);
        for (final kind in AdvancedWordKind.values) {
          expect(words.where((word) => word.kind == kind), hasLength(10),
              reason: '${lesson.id} $kind');
        }
        expect(words.every((word) => word.arabic.trim().isNotEmpty), isTrue);
        final chapters = EnglishAdvancedLearningPath.readingFor(lesson);
        expect(chapters, hasLength(lesson.paragraphs.length + (level == 'C1' || level == 'C2' ? 2 : 1)));
        expect(chapters.first, lesson.paragraphs.first);
        expect(chapters.skip(lesson.paragraphs.length).join(' '),
            contains(words.first.term));
        if (level == 'C1' || level == 'C2') {
          expect(chapters.length, greaterThanOrEqualTo(level == 'C1' ? 7 : 8));
          expect(chapters[chapters.length - 2].split(RegExp(r'\s+')).length,
              greaterThanOrEqualTo(100));
          expect(chapters.last.split(RegExp(r'\s+')).length,
              greaterThanOrEqualTo(100));
        }
        final dialogue = EnglishAdvancedLearningPath.conversationFor(lesson);
        expect(dialogue, hasLength(10));
        expect(dialogue.join(' '), contains(words.first.term));
        final podcast = EnglishAdvancedLearningPath.podcastFor(lesson);
        expect(podcast, startsWith(lesson.listening));
        for (final word in words) {
          expect(podcast.toLowerCase(), contains(word.term.toLowerCase()),
              reason: '${lesson.id}: ${word.term}');
        }
      }
    });
  }
}
