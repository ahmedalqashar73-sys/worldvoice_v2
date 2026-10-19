import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:worldvoice/core/localization/supported_language.dart';
import 'package:worldvoice/features/learn/data/academy_a1_tutor_lessons.dart';
import 'package:worldvoice/features/learn/data/academy_tutor_translations.dart';
import 'package:worldvoice/features/learn/data/academy_english_a1_catalog.dart';
import 'package:worldvoice/features/learn/presentation/academy_english_a1_integrated_lesson.dart';

void main() {
  test('every WorldVoice interface language has a localized tutor', () {
    final installedCodes =
        SupportedLanguages.all.map((language) => language.code).toSet();
    expect(AcademyTutorTranslations.supported.toSet(), installedCodes);
    for (final code in installedCodes) {
      expect(AcademyTutorTranslations.supports(code), isTrue);
      for (var lesson = 1; lesson <= 3; lesson++) {
        for (var field = 0; field < 6; field++) {
          final explanation =
              AcademyTutorTranslations.explain(code, lesson, field);
          expect(explanation.trim().length, greaterThan(7),
              reason: '$code lesson $lesson field $field');
        }
        for (var example = 0; example < 5; example++) {
          expect(AcademyTutorTranslations
              .exampleMeaning(code, lesson, example).trim(), isNotEmpty);
        }
      }
      for (var label = 0; label < 16; label++) {
        expect(AcademyTutorTranslations.label(code, label).trim(),
          isNotEmpty, reason: '$code label $label');
      }
      for (var stage = 0; stage < 8; stage++) {
        expect(AcademyTutorTranslations.section(code, stage).trim(),
          isNotEmpty, reason: '$code section $stage');
      }
      expect(AcademyTutorTranslations.menuIntroduction(code).trim().length,
          greaterThan(20));
    }
    expect(AcademyTutorTranslations.isRtl('ar'), isTrue);
    expect(AcademyTutorTranslations.isRtl('ur'), isTrue);
    expect(AcademyTutorTranslations.isRtl('fa'), isTrue);
    expect(AcademyTutorTranslations.isRtl('fr'), isFalse);
  });

  testWidgets('Spanish UI translates tutor speech and examples, not English grammar text',
      (tester) async {
    final unit = EnglishA1Catalog.units.first;
    tester.view.physicalSize = const Size(960, 1650);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AcademyEnglishA1IntegratedLesson(
        unit: unit, lesson: unit.lessons.first, lessonNumber: 1),
    ));
    await tester.tap(find.byKey(const ValueKey('academy-section-0')));
    await tester.pumpAndSettle();
    expect(find.text('Emma · Clase guiada'), findsOneWidget);
    expect(find.text('Objetivo de hoy'), findsOneWidget);
    expect(find.text('I am / You are'), findsOneWidget);
    expect(find.text('Soy Sara.'), findsOneWidget);
    expect(find.text(AcademyA1TutorCatalog.lessons.first.welcomeArabic),
        findsNothing);
  });
}
