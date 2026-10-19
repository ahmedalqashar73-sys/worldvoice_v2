import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:worldvoice/core/localization/supported_language.dart';
import 'package:worldvoice/features/learn/data/academy_tutor_locales.dart';
import 'package:worldvoice/features/learn/data/academy_english_a1_catalog.dart';
import 'package:worldvoice/features/learn/presentation/academy_english_a1_integrated_lesson.dart';

void main() {
  test('tutor has authored explanations for every supported interface locale', () {
    final supported = SupportedLanguages.all.map((e) => e.code).toSet();
    expect(AcademyTutorLocales.supported, supported);
    for (final code in supported) {
      for (var label = 0; label < 13; label++) {
        expect(AcademyTutorLocales.label(code, label).trim(), isNotEmpty);
      }
      if (code == 'ar') continue; // Arabic tutor uses the original prose.
      for (var number = 1; number <= 3; number++) {
        final material = AcademyTutorLocales.forLesson(code, number);
        expect(material.intro.trim(), isNotEmpty);
        expect(material.rule.trim(), isNotEmpty);
        expect(material.mistake.trim(), isNotEmpty);
        expect(material.practice.trim(), isNotEmpty);
        expect(material.exampleMeanings.length, 5);
        expect(material.exampleMeanings.every((m) => m.trim().isNotEmpty), isTrue);
      }
    }
  });

  testWidgets('French app language displays French tutor teaching and glosses',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final unit = EnglishA1Catalog.units.first;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr'), Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AcademyEnglishA1IntegratedLesson(
        unit: unit, lesson: unit.lessons.first, lessonNumber: 1,
      ),
    ));
    await tester.tap(find.byKey(const ValueKey('academy-section-0')));
    await tester.pumpAndSettle();
    expect(find.text('Professeure Emma'), findsOneWidget);
    expect(find.text(AcademyTutorLocales.forLesson('fr', 1).rule),
      findsOneWidget);
    expect(find.textContaining('مرحبًا! أنا إيما'), findsNothing);
    expect(find.text('Je suis Sara.'), findsOneWidget);
  });
}
