import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:worldvoice/features/learn/data/academy_a1_grammar_workshops.dart';
import 'package:worldvoice/features/learn/data/academy_a1_tutor_lessons.dart';
import 'package:worldvoice/features/learn/data/academy_advanced_grammar_workshops.dart';
import 'package:worldvoice/features/learn/data/academy_english_a1_catalog.dart';
import 'package:worldvoice/features/learn/data/academy_english_advanced_models.dart';
import 'package:worldvoice/features/learn/presentation/academy_english_a1_integrated_lesson.dart';
import 'package:worldvoice/features/learn/presentation/academy_english_advanced_screen.dart';

void main() {
  test('All 30 A1 lessons have tutor-style grammar with multiple examples',
      () {
    expect(AcademyA1TutorCatalog.lessons, hasLength(3));
    expect(AcademyGrammarWorkshops.count, 27);
    for (final unit in EnglishA1Catalog.units) {
      for (var n = 1; n <= unit.lessons.length; n++) {
        final tutor = AcademyA1TutorCatalog.forUnitLesson(unit.id, n);
        final workshop = AcademyGrammarWorkshops.forLesson(unit.id, n);
        if (tutor != null) {
          expect(workshop, isNull);
          expect(tutor.examples.length, greaterThanOrEqualTo(5));
          expect(tutor.checks.length, greaterThanOrEqualTo(3));
        } else {
          expect(workshop, isNotNull, reason: 'unit ${unit.id} lesson $n');
          expect(workshop!.examples, hasLength(4));
          expect(workshop.options, hasLength(3));
          expect(workshop.answer, inInclusiveRange(0, 2));
          expect(workshop.ruleEnglish.trim(), isNotEmpty);
          expect(workshop.wrong, isNot(workshop.correct));
          for (final example in workshop.examples) {
            expect(example.english.trim(), isNotEmpty);
            expect(example.arabic.trim(), isNotEmpty);
            expect(example.english, isNot(example.arabic));
          }
        }
      }
    }
  });

  test('Every published A2–C2 lesson has six contextual examples and quiz',
      () {
    expect(AdvancedGrammarWorkshops.count,
        EnglishAdvancedSyllabus.lessons.length);
    for (final lesson in EnglishAdvancedSyllabus.lessons) {
      final workshop = AdvancedGrammarWorkshops.forLesson(
          lesson.level, lesson.number, unitNumber: lesson.unitNumber);
      expect(workshop, isNotNull, reason: lesson.id);
      expect(lesson.grammarExamples, hasLength(3));
      expect(workshop!.examples, hasLength(3));
      expect(workshop.options, hasLength(3));
      expect(workshop.answer, inInclusiveRange(0, 2));
      expect(workshop.wrong, isNot(workshop.correct));
      expect(workshop.explanationEnglish, isNotEmpty);
      for (final example in workshop.examples) {
        expect(example.arabic, isNotEmpty);
        expect(example.english, isNotEmpty);
      }
    }
  });

  testWidgets('A1 lesson four requires passing its grammar before next section',
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
          unit: unit, lesson: unit.lessons[3], lessonNumber: 4),
    ));
    await tester.tap(find.byKey(const ValueKey('academy-section-0')));
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      expect(find.byKey(ValueKey('academy-workshop-example-$i')),
          findsOneWidget);
    }
    expect(find.byKey(const ValueKey('academy-integrated-next')),
        findsNothing);
    final work = AcademyGrammarWorkshops.forLesson(1, 4)!;
    final option = find.byKey(ValueKey('academy-workshop-option-${work.answer}'));
    await tester.ensureVisible(option);
    await tester.pumpAndSettle();
    await tester.tap(option);
    await tester.pump();
    final check = find.byKey(const ValueKey('academy-workshop-check'));
    await tester.ensureVisible(check);
    await tester.pumpAndSettle();
    await tester.tap(check);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('academy-integrated-next')),
        findsOneWidget);
  });

  testWidgets('A2 advanced grammar is gated and includes six examples',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1450);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final lesson = EnglishAdvancedSyllabus.forLevel('A2').first;
    await tester.pumpWidget(MaterialApp(
      home: AcademyEnglishAdvancedLessonScreen(lesson: lesson),
    ));
    await tester.tap(find.byKey(const ValueKey('advanced-section-0')));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      expect(find.byKey(ValueKey('advanced-grammar-example-$i')),
          findsOneWidget);
    }
    final next = find.byKey(const ValueKey('advanced-section-next'));
    await tester.ensureVisible(next);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(next).onPressed, isNull);
    final workshop = AdvancedGrammarWorkshops.forLesson('A2', 1)!;
    final option = find.byKey(
        ValueKey('advanced-grammar-option-${workshop.answer}'));
    await tester.ensureVisible(option);
    await tester.pumpAndSettle();
    await tester.tap(option);
    await tester.pump();
    final check = find.byKey(const ValueKey('advanced-grammar-check'));
    await tester.ensureVisible(check);
    await tester.pumpAndSettle();
    await tester.tap(check);
    await tester.pumpAndSettle();
    await tester.ensureVisible(next);
    expect(tester.widget<FilledButton>(next).onPressed, isNotNull);
  });
}

