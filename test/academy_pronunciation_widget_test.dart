import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/data/academy_catalog.dart';
import 'package:worldvoice/features/learn/presentation/academy_course_screen.dart';

void main() {
  test('existing academy languages provide readable pronunciation guides', () {
    expect(academyCourses.map((course) => course.code).toSet(),
        {'en', 'es', 'zh', 'fr', 'ko'});
    for (final unit in academyUnits) {
      for (final word in unit.words) {
        expect(word.pronunciation.trim(), isNotEmpty,
            reason: unit.language + ': ' + word.term);
        expect(word.arabic.trim(), isNotEmpty);
      }
    }
    expect(academyUnits.firstWhere((unit) => unit.language == 'en')
        .words.first.pronunciation, 'هَلّو');
    expect(academyUnits.firstWhere((unit) => unit.language == 'es')
        .words.first.pronunciation, 'أُولا');
    expect(academyUnits.firstWhere((unit) => unit.language == 'zh')
        .words.first.pronunciation, 'nǐ hǎo');
    expect(academyUnits.firstWhere((unit) => unit.language == 'ko')
        .words.first.pronunciation, 'annyeonghaseyo');
  });

  testWidgets('a vocabulary card separates target, pronunciation and meaning',
      (tester) async {
    final unit = academyUnits.firstWhere(
        (unit) => unit.language == 'es' && unit.number == 1);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: AcademyLessonScreen(
        unit: unit,
        kind: AcademyLessonKind.vocabulary,
        completed: false,
      ),
    ));
    expect(find.text('hola'), findsOneWidget);
    expect(find.text('أُولا'), findsOneWidget);
    expect(find.text('مرحبًا'), findsOneWidget);
    expect(find.byIcon(Icons.volume_up_rounded), findsWidgets);
    expect(find.text('استمع ببطء'), findsWidgets);
  });
}
