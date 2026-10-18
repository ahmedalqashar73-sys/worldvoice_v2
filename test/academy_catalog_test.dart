import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/data/academy_catalog.dart';

void main() {
  test('academy offers five reviewed beginner languages and exactly 60 lessons', () {
    expect(academyCourses.map((c) => c.code).toSet(),
      {'en', 'es', 'zh', 'fr', 'ko'});
    expect(academyUnits.length, 10);
    expect(AcademyLessonKind.values.length, 6);
    expect(academyCourses.fold<int>(0, (sum, course) =>
      sum + course.lessonCount), 60);
  });

  test('each course has two distinct, complete thematic units', () {
    final ids = <String>{};
    for (final course in academyCourses) {
      expect(course.units.length, 2);
      expect(course.units.map((u) => u.number), [1, 2]);
      expect(course.flag.isNotEmpty, true);
      expect(course.arabicName.isNotEmpty, true);
      for (final unit in course.units) {
        expect(unit.language, course.code);
        expect(unit.title.length, greaterThan(3));
        expect(unit.nativeTitle.length, greaterThan(3));
        expect(unit.words.length, 5);
        for (final word in unit.words) {
          expect(word.term.trim().isNotEmpty, true);
          expect(word.arabic.trim().isNotEmpty, true);
          expect(word.pronunciation.trim().isNotEmpty, true);
        }
        expect(unit.grammar.length, greaterThan(15));
        expect(unit.grammarExample.length, greaterThan(10));
        expect(unit.grammarTranslation.length, greaterThan(10));
        expect(unit.story.length, greaterThan(35));
        expect(unit.storyArabic.length, greaterThan(35));
        expect(unit.listening.length, greaterThan(18));
        expect(unit.speaking.length, greaterThan(9));
        expect(unit.speakingHelp.length, greaterThan(15));
        expect(unit.quizOptions.length, 3);
        expect(unit.quizCorrectIndex, inInclusiveRange(0, 2));
        expect(unit.quizQuestion.length, greaterThan(10));
        for (final kind in AcademyLessonKind.values) {
          expect(ids.add(unit.lessonId(kind)), true,
            reason: 'Lesson progress document IDs must be unique.');
        }
      }
    }
    expect(ids.length, 60);
  });

  test('learning progress IDs are stable across app relaunches', () {
    final course = academyCourses.firstWhere((course) =>
      course.code == 'ko');
    expect(course.units.first.lessonId(AcademyLessonKind.vocabulary),
      'ko_1_vocabulary');
    expect(course.units.last.lessonId(AcademyLessonKind.quiz),
      'ko_2_quiz');
  });

  test('Chinese and Korean units use native scripts with learning support', () {
    final chinese = academyCourses.firstWhere((c) => c.code == 'zh');
    final korean = academyCourses.firstWhere((c) => c.code == 'ko');
    expect(chinese.units.first.words.first.term, '你好');
    expect(chinese.units.first.words.first.pronunciation, 'nǐ hǎo');
    expect(korean.units.first.words.first.term, '안녕하세요');
    expect(korean.units.first.words.first.pronunciation, 'annyeonghaseyo');
  });
}
