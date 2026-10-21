import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/data/academy_catalog.dart';
import 'package:worldvoice/features/learn/presentation/academy_first_conversation.dart';
import 'package:worldvoice/features/learn/presentation/academy_story_reader.dart';

Widget _app(Widget page) => MaterialApp(
  locale: const Locale('ar'),
  supportedLocales: const [Locale('ar'), Locale('en')],
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: page,
);

void main() {
  testWidgets('first dialogue gives feedback and advances after a right answer',
      (tester) async {
    final course = academyCourses.firstWhere((c) => c.code == 'es');
    await tester.pumpWidget(_app(AcademyFirstConversation(course: course)));
    expect(find.text('¿Cómo te llamas?', findRichText: true), findsNothing);
    expect(find.textContaining('Me llamo Ana'), findsOneWidget);
    await tester.tap(find.text('Me llamo Luis.'));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('تحقق من الرد'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('تحقق من الرد'));
    await tester.pump();
    expect(find.textContaining('إجابة صحيحة'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('المحادثة التالية'), 140,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('المحادثة التالية'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Mucho gusto'), findsWidgets);
  });

  testWidgets('storybook can turn pages and reveals a comprehension quiz',
      (tester) async {
    final unit = academyUnits.firstWhere(
        (unit) => unit.language == 'en' && unit.number == 1);
    await tester.pumpWidget(_app(AcademyStoryReader(unit: unit)));
    expect(find.text('The Lost Notebook'), findsOneWidget);
    await tester.tap(find.text('ابدأ القراءة'));
    await tester.pumpAndSettle();
    expect(find.text('صفحة 1'), findsOneWidget);
    expect(find.textContaining('Sara has a small blue notebook'),
        findsOneWidget);
    await tester.tap(find.byTooltip('إظهار أو إخفاء الترجمة'));
    await tester.pump();
    expect(find.textContaining('لدى سارة دفتر أزرق'), findsOneWidget);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('الصفحة التالية'));
      await tester.pumpAndSettle();
    }
    expect(find.text('هل فهمت القصة؟'), findsOneWidget);
    expect(find.text('Who finds Sara’s notebook?'), findsOneWidget);
    await tester.tap(find.text('Tom'));
    await tester.pump();
    await tester.ensureVisible(find.text('تحقق من الإجابة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تحقق من الإجابة'));
    await tester.pump();
    expect(find.textContaining('ممتاز! فهمت القصة'), findsOneWidget);
    expect(find.text('أنهي القصة واحفظ التقدم'), findsOneWidget);
  });
}
