import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/data/academy_catalog.dart';
import 'package:worldvoice/features/learn/presentation/academy_placement_screen.dart';

void main() {
  test('each existing academy language has eight complete placement items', () {
    for (final course in academyCourses) {
      final questions = AcademyPlacementCatalog.forLanguage(course.code);
      expect(questions, hasLength(8), reason: course.code);
      for (final q in questions) {
        expect(q.prompt.trim(), isNotEmpty);
        expect(q.options, hasLength(3));
        expect(q.correctIndex, inInclusiveRange(0, 2));
        expect(q.options.toSet().length, 3);
      }
    }
    expect(AcademyPlacementCatalog.recommendedLevel(0), 'A1');
    expect(AcademyPlacementCatalog.recommendedLevel(3), 'A2');
    expect(AcademyPlacementCatalog.recommendedLevel(5), 'B1');
    expect(AcademyPlacementCatalog.recommendedLevel(7), 'B2');
  });

  testWidgets('placement can be skipped to A1 without paying or claiming qualification',
      (tester) async {
    final course = academyCourses.firstWhere((c) => c.code == 'es');
    String? completedLevel;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () async {
            completedLevel = await Navigator.of(context).push<String>(
              MaterialPageRoute(builder: (_) =>
                  AcademyPlacementScreen(course: course)),
            );
          },
          child: const Text('Start'),
        ),
      )),
    ));
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.text('اختبار تحديد المستوى'), findsOneWidget);
    expect(find.textContaining('¿Cómo se dice'), findsOneWidget);
    await tester.tap(find.text('تخطي والبدء من A1'));
    await tester.pumpAndSettle();
    expect(completedLevel, 'A1');
  });
}
