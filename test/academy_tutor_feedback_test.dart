import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:worldvoice/features/learn/data/academy_english_a1_catalog.dart';
import 'package:worldvoice/features/learn/data/academy_tutor_translations.dart';
import 'package:worldvoice/features/learn/presentation/academy_english_a1_integrated_lesson.dart';

void main() {
  test('Each English tutor worked example has a different, specific note', () {
    final notes = <String>{};
    for (var lesson = 1; lesson <= 3; lesson++) {
      for (var example = 0; example < 5; example++) {
        final note = AcademyTutorTranslations.exampleNoteFor(
            'en', lesson, example);
        expect(note.trim().length, greaterThan(25));
        expect(notes.add(note), isTrue);
      }
    }
    expect(notes, hasLength(15));
    expect(AcademyTutorTranslations.exampleNoteFor('es', 1, 0),
        AcademyTutorTranslations.exampleNote('es'));
  });

  testWidgets('English A1 tutor does not print the same sentence twice',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final unit = EnglishA1Catalog.units.first;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      home: AcademyEnglishA1IntegratedLesson(
        unit: unit, lesson: unit.lessons.first, lessonNumber: 1,
      ),
    ));
    await tester.tap(find.byKey(const ValueKey('academy-section-0')));
    await tester.pumpAndSettle();
    expect(find.text('I am Sara.'), findsOneWidget);
    expect(find.text(AcademyTutorTranslations.exampleNoteFor('en', 1, 0)),
        findsOneWidget);
    expect(find.text(AcademyTutorTranslations.exampleNote('en')), findsNothing);
  });
}
