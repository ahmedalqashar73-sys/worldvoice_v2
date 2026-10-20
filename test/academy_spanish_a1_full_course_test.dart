import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:worldvoice/features/learn/data/academy_spanish_a1_course.dart';
import 'package:worldvoice/features/learn/presentation/academy_spanish_a1_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Spanish A1 contains three complete units with ten lessons each', () {
    expect(SpanishA1Course.units, hasLength(3));
    expect(SpanishA1Course.lessons, hasLength(30));
    final ids = <String>{};
    final grammarTitles = <String>{};
    for (final unit in SpanishA1Course.units) {
      expect(unit.lessons, hasLength(10));
      for (final lesson in unit.lessons) {
        expect(lesson.unit, unit.number);
        expect(lesson.id,
            'worldvoice.es.a1.u${unit.number}.l${lesson.number.toString().padLeft(2, '0')}');
        expect(ids.add(lesson.id), isTrue);
        expect(grammarTitles.add(lesson.grammar), isTrue);
        expect(lesson.grammarHelpAr.trim(), isNotEmpty);
        expect(lesson.grammarAr.trim(), isNotEmpty);
        expect(lesson.grammarExamples, hasLength(6));
        expect(lesson.story, hasLength(3));
        expect(lesson.story.join(' ').trim().split(RegExp(r'\s+')).length,
            greaterThan(38));
      }
    }
    expect(ids, hasLength(30));
  });

  test('all Spanish lessons include 10 nouns verbs adjectives and adverbs', () {
    for (final lesson in SpanishA1Course.lessons) {
      final words = lesson.words;
      expect(words, hasLength(40), reason: lesson.id);
      expect(words.map((word) => word.es.toLowerCase()).toSet(),
          hasLength(40), reason: lesson.id);
      for (final kind in SpanishWordKind.values) {
        expect(words.where((word) => word.kind == kind), hasLength(10),
            reason: '${lesson.id} $kind');
      }
      expect(words.every((word) =>
        word.es.trim().isNotEmpty && word.ar.trim().isNotEmpty), isTrue);
      final story = SpanishA1Course.reading(lesson);
      expect(story, hasLength(4));
      expect(story.first, lesson.story.first);
      expect(story.last, contains(words.first.es));
      final dialogue = SpanishA1Course.dialogue(lesson);
      expect(dialogue, hasLength(8));
      expect(dialogue.join(' '), contains(words.first.es));
      final podcast = SpanishA1Course.podcast(lesson);
      expect(podcast, contains(lesson.title));
      expect(podcast, contains(lesson.story.first));
      for (final word in words) {
        expect(podcast.toLowerCase(), contains(word.es.toLowerCase()),
            reason: '${lesson.id} ${word.es}');
      }
    }
  });

  test('Spanish local progress is scoped by account and validates lesson IDs', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final lesson = SpanishA1Course.find(1, 1);
    expect(await SpanishA1Progress.load('userA'), isEmpty);
    await SpanishA1Progress.complete('userA', lesson);
    expect(await SpanishA1Progress.load('userA'), contains(lesson.id));
    expect(await SpanishA1Progress.load('userB'), isEmpty);
    expect(await SpanishA1Progress.load(null), isEmpty);
  });

  testWidgets('Spanish A1 path presents three unit cards',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const MaterialApp(home: AcademySpanishA1Path()));
    await tester.pumpAndSettle();
    for (var i = 1; i <= 3; i++) {
      expect(find.byKey(ValueKey('spanish-a1-unit-$i')), findsOneWidget);
    }
  });

  testWidgets('first grammar stage precedes vocabulary and protects completion',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final lesson = SpanishA1Course.find(1, 1);
    await tester.pumpWidget(MaterialApp(
      home: AcademySpanishA1LessonScreen(lesson: lesson)));
    await tester.pumpAndSettle();
    expect(find.text(lesson.grammar), findsOneWidget);
    expect(find.byKey(const ValueKey('spanish-grammar-check')),
      findsOneWidget);
    expect(find.byKey(const ValueKey('spanish-a1-finish')), findsNothing);
    for (var i = 0; i < 3; i++) {
      expect(find.byKey(ValueKey('spanish-grammar-option-$i')),
          findsOneWidget);
    }
    final rightAnswer = find.byKey(
        const ValueKey('spanish-grammar-option-1'));
    await tester.scrollUntilVisible(rightAnswer, 350,
        scrollable: find.byType(Scrollable).first, maxScrolls: 25);
    await tester.pumpAndSettle();
    await tester.tap(rightAnswer);
    await tester.pumpAndSettle();
    final check = find.byKey(const ValueKey('spanish-grammar-check'));
    await tester.scrollUntilVisible(check, 250,
        scrollable: find.byType(Scrollable).first, maxScrolls: 25);
    await tester.pumpAndSettle();
    await tester.tap(check);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('spanish-vocabulary-next')),
      findsOneWidget);
  });
}
