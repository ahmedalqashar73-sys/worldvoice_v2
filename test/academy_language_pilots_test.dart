import 'package:flutter_test/flutter_test.dart';

import 'package:worldvoice/features/learn/data/academy_language_pilots.dart';

void main() {
  test('Spanish, French, Chinese and Korean A1 pilots have genuine first lessons', () {
    expect(AcademyLanguagePilots.courses.length, 4);
    final seen = <String>{};
    for (final course in AcademyLanguagePilots.courses) {
      expect(seen.add(course.code), isTrue);
      expect(course.words, hasLength(20), reason: course.code);
      expect(course.words.map((w) => w.term).toSet().length, 20);
      expect(course.story, hasLength(3));
      expect(course.storyArabic, hasLength(3));
      expect(course.story.every((p) => p.trim().length > 80), isTrue);
      expect(course.storyArabic.every((p) => p.trim().length > 30), isTrue);
      expect(course.dialogue.trim(), isNotEmpty);
      expect(course.grammar.trim().length, greaterThan(100));
      expect(course.grammarArabic.trim().length, greaterThan(65));
      expect(course.listening.trim(), isNotEmpty);
      expect(course.comprehension.trim(), isNotEmpty);
      expect(course.options, hasLength(3));
      expect(course.correctIndex, inInclusiveRange(0, 2));
      expect(course.words.every((w) =>
        w.term.trim().isNotEmpty &&
        w.arabic.trim().isNotEmpty &&
        w.pronunciation.trim().isNotEmpty), isTrue);
      if (course.code == 'zh') {
        expect(course.voiceLocale, 'zh-CN');
        expect(course.words.first.pronunciation, contains('ǐ'));
      }
      if (course.code == 'ko') {
        expect(course.voiceLocale, 'ko-KR');
      }
    }
    expect(seen, {'es','fr','zh','ko'});
  });
}
