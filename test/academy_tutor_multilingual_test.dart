import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:worldvoice/core/localization/supported_language.dart';
import 'package:worldvoice/features/learn/data/academy_a1_tutor_lessons.dart';
import 'package:worldvoice/features/learn/data/academy_tutor_translations.dart';
import 'package:worldvoice/features/learn/data/academy_english_a1_catalog.dart';
import 'package:worldvoice/features/learn/presentation/academy_english_a1_integrated_lesson.dart';

void main() {
  test('teacher curriculum and examples are translated for every UI locale', () {
    final codes = SupportedLanguages.all.map((e) => e.code).toSet();
    expect(AcademyTutorLanguage.supported.toSet(), codes);
    for (final code in codes) {
      expect(AcademyTutorLanguage.supports(code), true);
      for (var lesson = 1; lesson <= 3; lesson++) {
        final translated = AcademyTutorLanguage.lesson(code, lesson);
        expect(translated.welcome.trim().length, greaterThan(20), reason: '$code/$lesson');
        expect(translated.goal.trim().length, greaterThan(15), reason: '$code/$lesson');
        expect(translated.rule.trim().length, greaterThan(20), reason: '$code/$lesson');
        expect(translated.mistake.trim(), isNotEmpty);
        expect(translated.tip.trim(), isNotEmpty);
        expect(translated.pronunciation.trim(), isNotEmpty);
        for (var i = 0; i < 5; i++) {
          expect(AcademyTutorExamples.forExample(code, lesson, i).trim(),
              isNotEmpty, reason: '$code/$lesson/$i');
        }
        for (var i = 0; i < 16; i++) {
          expect(AcademyTutorUi.text(code, i).trim(), isNotEmpty,
              reason: '$code/$i');
        }
      }
    }
    expect(AcademyA1TutorCatalog.lessons.length, 3);
  });

  for (final code in ['es', 'fr', 'zh', 'ko', 'ja', 'hi']) {
    testWidgets('English A1 teacher speaks $code UI locale in grammar',
        (tester) async {
      tester.view.physicalSize = const Size(1100, 1500);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final unit = EnglishA1Catalog.units.first;
      await tester.pumpWidget(MaterialApp(
        locale: Locale(code),
        supportedLocales: SupportedLanguages.locales,
        home: AcademyEnglishA1IntegratedLesson(
          unit: unit, lesson: unit.lessons.first, lessonNumber: 1),
      ));
      await tester.tap(find.byKey(const ValueKey('academy-section-0')));
      await tester.pumpAndSettle();
      expect(find.text(AcademyTutorUi.text(code, 0)), findsOneWidget);
      expect(find.text(AcademyTutorLanguage.lesson(code, 1).welcome), findsOneWidget);
      expect(find.text('I am / You are'), findsOneWidget);
      expect(find.text(AcademyTutorExamples.forExample(code, 1, 0)), findsOneWidget);
      expect(find.text(AcademyA1TutorCatalog.lessons.first.welcomeArabic),
          findsNothing);
    });
  }
}
