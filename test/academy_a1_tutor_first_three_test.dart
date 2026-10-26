import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:worldvoice/features/learn/data/academy_a1_tutor_lessons.dart';
import 'package:worldvoice/features/learn/data/academy_english_a1_catalog.dart';
import 'package:worldvoice/features/learn/data/academy_english_a1_vocabulary.dart';
import 'package:worldvoice/features/learn/data/academy_english_pronunciation.dart';
import 'package:worldvoice/features/learn/presentation/academy_english_a1_integrated_lesson.dart';

void main() {
  test('first three English A1 lessons have teacher explanation and correction', () {
    for (var lesson = 1; lesson <= 3; lesson++) {
      final tutor = AcademyA1TutorCatalog.forUnitLesson(1, lesson);
      expect(tutor, isNotNull);
      expect(tutor!.welcomeArabic.length, greaterThan(70));
      expect(tutor.goalArabic.length, greaterThan(45));
      expect(tutor.ruleArabic.length, greaterThan(100));
      expect(tutor.examples.length, greaterThanOrEqualTo(5));
      expect(tutor.patterns.length, greaterThanOrEqualTo(4));
      expect(tutor.commonMistake.trim(), isNotEmpty);
      expect(tutor.correctForm.trim(), isNotEmpty);
      expect(tutor.pronunciationGuide, isNotEmpty);
      expect(tutor.pronunciationTipArabic, isNotEmpty);
      expect(tutor.checks, hasLength(3));
      for (final item in tutor.checks) {
        expect(item.options, hasLength(3));
        expect(item.correctIndex, inInclusiveRange(0, 2));
        expect(item.explanation.trim().length, greaterThan(20));
      }
    }
    expect(AcademyA1TutorCatalog.forUnitLesson(1, 4), isNull);
    expect(AcademyA1TutorCatalog.forUnitLesson(2, 1), isNull);
  });

  test('all first-three lesson words show English IPA, never Arabic respelling', () {
    for (var lesson = 1; lesson <= 3; lesson++) {
      final words = EnglishA1Vocabulary.forLesson(1, lesson);
      expect(words, hasLength(20));
      for (final word in words) {
        final ipa = AcademyEnglishPronunciation.ipaFor(word.term);
        expect(ipa, isNotNull, reason: word.term);
        expect(ipa!.startsWith('/'), isTrue);
        expect(ipa.endsWith('/'), isTrue);
        expect(RegExp(r'[\u0600-\u06FF]').hasMatch(ipa), isFalse);
      }
    }
    expect(
      RegExp(r'[\u0600-\u06FF]').hasMatch(
        AcademyEnglishPronunciation.displayHint('a future uncommon word')),
      isFalse,
    );
  });

  testWidgets('every enhanced lesson opens in tutor-led grammar section',
      (tester) async {
    tester.view.physicalSize = const Size(1050, 1650);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final unit = EnglishA1Catalog.units.first;
    for (var index = 0; index < 3; index++) {
      await tester.pumpWidget(MaterialApp(
        home: AcademyEnglishA1IntegratedLesson(
          key: ValueKey('tutor-lesson-${index + 1}'),
          unit: unit,
          lesson: unit.lessons[index],
          lessonNumber: index + 1,
        ),
      ));
      expect(find.textContaining('15 minutes'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('academy-section-0')));
      await tester.pumpAndSettle();
      final tutor = AcademyA1TutorCatalog.lessons[index];
      expect(find.text(tutor.title), findsOneWidget);
      expect(find.text(tutor.commonMistake), findsOneWidget);
      expect(find.byKey(const ValueKey('academy-integrated-next')), findsNothing);
      expect(find.byKey(const ValueKey('academy-tutor-check-answer')),
          findsOneWidget);
    }
  });
}
