import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/data/academy_catalog.dart';
import 'package:worldvoice/features/learn/data/academy_journey_catalog.dart';
import 'package:worldvoice/features/learn/data/academy_story_catalog.dart';

void main() {
  test('CEFR journey is in order and planned stages are never declared released', () {
    expect(AcademyJourneyCatalog.levels.map((l) => l.id),
        ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']);
    expect(AcademyJourneyCatalog.plannedUnits, 96);
    expect(AcademyJourneyCatalog.levels.first.isBeginner, true);
    for (final level in AcademyJourneyCatalog.levels) {
      expect(level.titleArabic.trim(), isNotEmpty);
      expect(level.titleEnglish.trim(), isNotEmpty);
      expect(level.goalArabic.trim(), isNotEmpty);
      expect(level.goalEnglish.trim(), isNotEmpty);
      expect(level.topicsArabic, isNotEmpty);
      expect(level.topicsEnglish, isNotEmpty);
      expect(level.plannedUnits, greaterThan(0));
    }
  });

  test('every published Academy A1 unit has a multi-page graded story', () {
    expect(academyCourses.length, 5);
    expect(academyUnits.length, 10);
    final uniqueStories = <String>{};
    for (final unit in academyUnits) {
      final story = AcademyStoryCatalog.forUnit(unit);
      expect(uniqueStories.add('${unit.language}_${unit.number}'), isTrue);
      expect(story.pages.length, greaterThanOrEqualTo(4),
          reason: '${unit.language}: ${unit.number}');
      expect(story.coverSymbol, isNotEmpty);
      expect(story.title, isNotEmpty);
      expect(story.titleArabic, isNotEmpty);
      expect(story.question, isNotEmpty);
      expect(story.questionArabic, isNotEmpty);
      expect(story.options.length, 3);
      expect(story.optionsArabic.length, story.options.length);
      expect(story.correctIndex, inInclusiveRange(0, story.options.length - 1));
      for (final page in story.pages) {
        expect(page.text.trim().length, greaterThanOrEqualTo(15));
        expect(page.arabic.trim().length, greaterThanOrEqualTo(15));
      }
    }
  });

  test('the new stories do not change saved Academy progress IDs', () {
    final first = academyUnits.firstWhere(
        (unit) => unit.language == 'es' && unit.number == 1);
    final story = AcademyStoryCatalog.forUnit(first);
    expect(first.lessonId(AcademyLessonKind.story), 'es_1_story');
    expect(story.title, 'La nota misteriosa');
    expect(story.correctIndex, 2);
  });
}
