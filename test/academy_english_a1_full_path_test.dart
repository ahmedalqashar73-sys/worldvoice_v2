import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:worldvoice/features/learn/data/academy_english_a1_catalog.dart';
import 'package:worldvoice/features/learn/data/academy_english_a1_vocabulary.dart';
import 'package:worldvoice/features/learn/data/academy_english_a1_long_stories.dart';
import 'package:worldvoice/features/learn/data/academy_english_a1_lesson_checks.dart';
import 'package:worldvoice/features/learn/presentation/academy_english_a1_screen.dart';
import 'package:worldvoice/features/learn/presentation/academy_english_a1_integrated_lesson.dart';
import 'package:worldvoice/features/learn/presentation/academy_illustrated_story_art.dart';

void main() {
  test('A1 has three units and every one of 30 lessons contains full content', () {
    expect(EnglishA1Catalog.units.length, 3);
    expect(EnglishA1Catalog.lessonCount, 30);
    final ids = <String>{};
    for (final unit in EnglishA1Catalog.units) {
      expect(unit.lessons, hasLength(10));
      expect(unit.goal.trim(), isNotEmpty);
      for (var index = 0; index < 10; index++) {
        final lesson = unit.lessons[index];
        final num = index + 1;
        expect(ids.add(lesson.id), isTrue);
        expect(lesson.titleAr, isNotEmpty);
        expect(lesson.spoken.trim(), isNotEmpty);
        expect(lesson.teaching.trim(), isNotEmpty);
        expect(lesson.question, isNotEmpty);
        expect(lesson.options, hasLength(3));
        expect(lesson.answer, inInclusiveRange(0, 2));
        final words = EnglishA1Vocabulary.forLesson(unit.id, num);
        expect(words, hasLength(20));
        expect(words.map((w) => w.term.toLowerCase()).toSet().length, 20);
        for (final word in words) {
          expect(word.term.trim(), isNotEmpty);
          expect(word.arabic.trim(), isNotEmpty);
          expect(word.pronunciation.trim(), isNotEmpty);
        }
        final grammar = EnglishA1LessonChecks.grammarFor(unit.id, num);
        expect(grammar.example, isNotEmpty);
        expect(grammar.helpArabic, isNotEmpty);
        final chapter = EnglishA1StorySyllabus.chapterFor(unit.id, num);
        expect(chapter.paragraphs, hasLength(3));
        final quiz = EnglishA1LessonChecks.storyCheck(unit.id, num);
        expect(quiz.options, hasLength(3));
        expect(quiz.answer, inInclusiveRange(0, 2));
      }
    }
    expect(ids, hasLength(30));
  });

  test('Nine distinct four-chapter stories, exactly three in each unit', () {
    expect(EnglishA1StorySyllabus.stories, hasLength(9));
    final ids = <String>{};
    for (var unit = 1; unit <= 3; unit++) {
      final books = EnglishA1StorySyllabus.stories.where((s) => s.unit == unit);
      expect(books.length, 3);
    }
    for (final story in EnglishA1StorySyllabus.stories) {
      expect(ids.add(story.id), isTrue);
      expect(story.chapters, hasLength(4));
      expect(story.titleArabic, isNotEmpty);
      for (final chapter in story.chapters) {
        expect(chapter.paragraphs, hasLength(3));
        for (final para in chapter.paragraphs) {
          expect(para.english.trim().length, greaterThan(30));
          expect(para.arabic.trim().length, greaterThan(25));
        }
      }
    }
    expect(EnglishA1StorySyllabus.storyFor(1, 1).id,
        EnglishA1StorySyllabus.storyFor(1, 4).id);
    expect(EnglishA1StorySyllabus.storyFor(1, 5).id,
        isNot(EnglishA1StorySyllabus.storyFor(1, 4).id));
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

  testWidgets('lesson starts with grammar, then teaches twenty words',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final unit = EnglishA1Catalog.units.first;
    await tester.pumpWidget(MaterialApp(
      home: AcademyEnglishA1IntegratedLesson(
        unit: unit, lesson: unit.lessons.first, lessonNumber: 1),
    ));
    expect(find.byKey(const ValueKey('academy-lesson-sections')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('academy-section-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('academy-section-7')), findsOneWidget);
    // Locked sections must not bypass the lesson stages.
    final locked = tester.widget<InkWell>(
        find.byKey(const ValueKey('academy-section-2')));
    expect(locked.onTap, isNull);
    await tester.tap(find.byKey(const ValueKey('academy-section-0')));
    await tester.pumpAndSettle();
    expect(find.text('I am / You are'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('academy-integrated-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('academy-lesson-sections')),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('academy-section-1')));
    await tester.pumpAndSettle();
    expect(find.text('20 words to learn and review'), findsOneWidget);
    expect(find.text('hello'), findsWidgets);
  });

  testWidgets('single-page story shows all three paragraphs at once',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1450);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final unit = EnglishA1Catalog.units.first;
    await tester.pumpWidget(MaterialApp(
      home: AcademyEnglishA1IntegratedLesson(
        unit: unit, lesson: unit.lessons.first, lessonNumber: 1),
    ));
    for (var step = 0; step < 2; step++) {
      await tester.tap(find.byKey(ValueKey('academy-section-$step')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('academy-integrated-next')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const ValueKey('academy-section-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('academy-integrated-read-story')),
        findsOneWidget);
    await tester.tap(find.byKey(
        const ValueKey('academy-integrated-read-story')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('academy-story-single-page')),
        findsOneWidget);
    for (var i = 0; i < 3; i++) {
      expect(find.byKey(ValueKey('academy-story-paragraph-$i')),
          findsOneWidget);
    }
  });

  test('old partial activity completion remains intact but not counted as a full lesson',
      () async {
    SharedPreferences.setMockInitialValues({
      'worldvoice.academy.en.a1.v1.person-c.done':
          <String>['en_a1_1_01', 'en_a1_1_02'],
    });
    expect(await EnglishA1Progress.loadLegacy('person-c'), hasLength(2));
    expect(await EnglishA1Progress.load('person-c'), isEmpty);
    await EnglishA1Progress.complete('person-c', 'en_a1_1_01');
    expect(await EnglishA1Progress.load('person-c'), hasLength(1));
    expect(await EnglishA1Progress.loadLegacy('person-c'), hasLength(2));
  });

  testWidgets('animated story art draws all nine scenes without remote images',
      (tester) async {
    for (var scene = 0; scene < 9; scene++) {
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
