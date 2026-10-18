import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:worldvoice/features/learn/data/academy_english_a1_catalog.dart';
import 'package:worldvoice/features/learn/presentation/academy_english_a1_screen.dart';
import 'package:worldvoice/features/learn/presentation/academy_illustrated_story_art.dart';

void main() {
  test('English A1 contains three distinct units, 12 genuine lessons each', () {
    expect(EnglishA1Catalog.units.length, 3);
    expect(EnglishA1Catalog.lessonCount, 36);
    final allIds = <String>{};
    for (final unit in EnglishA1Catalog.units) {
      expect(unit.lessons.length, 12, reason: 'Unit ${unit.id}');
      expect(unit.goal.trim(), isNotEmpty);
      expect(unit.titleAr.trim(), isNotEmpty);
      final storyLessons = unit.lessons.where(
          (lesson) => lesson.kind == EnglishA1Kind.story).toList();
      expect(storyLessons.length, 2);
      final kinds = unit.lessons.map((lesson) => lesson.kind).toSet();
      expect(kinds.containsAll({
        EnglishA1Kind.dialogue, EnglishA1Kind.vocabulary,
        EnglishA1Kind.pronunciation, EnglishA1Kind.grammar,
        EnglishA1Kind.listening, EnglishA1Kind.story,
        EnglishA1Kind.practice, EnglishA1Kind.quiz,
      }), true);
      for (final lesson in unit.lessons) {
        expect(allIds.add(lesson.id), true);
        expect(lesson.title.trim(), isNotEmpty);
        expect(lesson.titleAr.trim(), isNotEmpty);
        expect(lesson.teaching.trim().length, greaterThan(15));
        expect(lesson.arabic.trim(), isNotEmpty);
        expect(lesson.spoken.trim(), isNotEmpty);
        expect(lesson.question.trim(), isNotEmpty);
        expect(lesson.options.length, 3);
        expect(lesson.answer, inInclusiveRange(0, 2));
        expect(lesson.options.toSet().length, 3);
        if (lesson.kind == EnglishA1Kind.story) {
          expect(EnglishA1Catalog.findStory(lesson.storyId!), isNotNull);
        } else {
          expect(lesson.storyId, isNull);
        }
      }
    }
    expect(allIds.length, 36);
  });

  test('six original five-page stories cover both slots in all units', () {
    expect(EnglishA1Catalog.stories.length, 6);
    final ids = <String>{};
    for (final story in EnglishA1Catalog.stories) {
      expect(ids.add(story.id), true);
      expect(story.pages.length, greaterThanOrEqualTo(5));
      expect(story.scene, inInclusiveRange(0, 5));
      expect(story.titleAr.trim(), isNotEmpty);
      expect(story.options.length, 3);
      expect(story.answer, inInclusiveRange(0, 2));
      for (final page in story.pages) {
        expect(page.text.trim().length, greaterThan(18));
        expect(page.arabic.trim().length, greaterThan(18));
      }
    }
  });

  test('device-only completion is account scoped and cannot forge unknown ids',
      () async {
    SharedPreferences.setMockInitialValues({});
    await EnglishA1Progress.complete('person-a', 'en_a1_1_01');
    expect((await EnglishA1Progress.load('person-a')),
        {'en_a1_1_01'});
    expect(await EnglishA1Progress.load('person-b'), isEmpty);
    expect(
      () => EnglishA1Progress.complete('person-a', 'en_a1_999_fake'),
      throwsArgumentError,
    );
    expect((await EnglishA1Progress.load('person-a')).length, 1);
  });

  testWidgets('animated story art draws all six scenes without remote images',
      (tester) async {
    for (var scene = 0; scene < 6; scene++) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Center(child: SizedBox(
          width: 360,
          child: AcademyIllustratedStoryArt(scene: scene, page: 1),
        ))),
      ));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(CustomPaint), findsWidgets);
    }
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SizedBox.shrink()),
    ));
  });
}
