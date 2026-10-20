import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/data/academy_english_advanced_models.dart';
import 'package:worldvoice/features/learn/data/academy_english_advanced_learning_path.dart';

void main() {
  for (final level in <String>['A2', 'B1', 'B2']) {
    test('$level links exactly forty graded words to reading, dialogue and podcast', () {
      final lessons = EnglishAdvancedSyllabus.forLevel(level);
      expect(lessons, hasLength(30));
      if (level != 'A2') {
        // Follow-up levels are only activated after their own curriculum
        // and CI validations have been completed.
        expect(EnglishAdvancedLearningPath.supports(lessons.first), isFalse);
        return;
      }
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
        expect(chapters, hasLength(lesson.paragraphs.length + 1));
        expect(chapters.first, lesson.paragraphs.first);
        expect(chapters.last, contains(words.first.term));
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
