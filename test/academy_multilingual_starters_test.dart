import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worldvoice/features/learn/data/academy_multilingual_starters.dart';
import 'package:worldvoice/features/learn/presentation/academy_multilingual_starter_screen.dart';

void main() {
  test('the four new first lessons contain complete original beginner material', () {
    expect(AcademyMultilingualStarters.lessons.keys.toSet(),
        {'es', 'fr', 'zh', 'ko'});
    for (final lesson in AcademyMultilingualStarters.lessons.values) {
      expect(lesson.name.trim(), isNotEmpty);
      expect(lesson.title.trim(), isNotEmpty);
      expect(lesson.grammar.trim().length, greaterThan(20));
      expect(lesson.grammarArabic.trim(), isNotEmpty);
      expect(lesson.grammarEnglish.trim(), isNotEmpty);
      expect(lesson.dialogue.trim(), isNotEmpty);
      expect(lesson.words, hasLength(20));
      expect(lesson.words.map((x) => x.term).toSet(), hasLength(20));
      for (final word in lesson.words) {
        expect(word.term.trim(), isNotEmpty);
        expect(word.arabic.trim(), isNotEmpty);
        expect(word.phonetic.trim(), isNotEmpty);
      }
      expect(lesson.story, hasLength(2));
      expect(lesson.storyArabic, hasLength(2));
      expect(lesson.checks, hasLength(3));
      for (final check in lesson.checks) {
        expect(check.question.trim(), isNotEmpty);
        expect(check.options, hasLength(3));
        expect(check.answer, inInclusiveRange(0, 2));
      }
    }
  });

  testWidgets('Spanish guided A1 starter has grammar and twenty vocabulary cards',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1100, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AcademyGuidedStartScreen(
        lesson: AcademyMultilingualStarters.forCode('es')!),
    ));
    await tester.pump();
    expect(find.byKey(const ValueKey('academy-guided-grammar')), findsOneWidget);
    expect(find.textContaining('Me llamo Ana.'), findsWidgets);
    expect(find.byKey(const ValueKey('academy-guided-words')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('academy-guided-words')));
    await tester.pumpAndSettle();
    expect(find.text('hola'), findsOneWidget);
    expect(find.text('/ˈola/'), findsOneWidget);
  });
}
