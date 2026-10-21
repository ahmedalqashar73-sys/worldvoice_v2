import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:worldvoice/features/learn/data/academy_spanish_a1_course.dart';
import 'package:worldvoice/features/learn/data/academy_spanish_a2_course.dart';
import 'package:worldvoice/features/learn/presentation/academy_spanish_a1_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Spanish A2 has exactly three units and thirty complete lessons', () {
    expect(SpanishA2Course.units, hasLength(3));
    expect(SpanishA2Course.lessons, hasLength(30));
    final ids = <String>{};
    final ruleTitles = <String>{};
    for (final unit in SpanishA2Course.units) {
      expect(unit.lessons, hasLength(10), reason: unit.title);
      for (var i = 1; i <= 10; i++) {
        final lesson = SpanishA2Course.find(unit.number, i);
        expect(lesson.id,
          'worldvoice.es.a2.u${unit.number}.l${i.toString().padLeft(2, '0')}');
        expect(lesson.title.trim(), isNotEmpty);
        expect(lesson.titleAr.trim(), isNotEmpty);
        expect(lesson.grammarHelpAr.trim(), isNotEmpty);
        expect(ruleTitles.add(lesson.grammar), isTrue);
        expect(ids.add(lesson.id), isTrue);
        expect(lesson.grammarExamples, hasLength(6));
        final guidedExamples = SpanishA2Course.grammarExamplesFor(lesson);
        expect(guidedExamples, hasLength(8), reason: lesson.id);
        expect(guidedExamples.take(6), orderedEquals(lesson.grammarExamples));
        expect(guidedExamples.toSet(), hasLength(8), reason: lesson.id);
        expect(guidedExamples.every((x) => x.trim().isNotEmpty), isTrue);
        expect(lesson.grammarExamples.every((x) => x.trim().isNotEmpty), isTrue);
        final distractors = SpanishA2Course.grammarOptions(lesson);
        expect(distractors, hasLength(3));
        expect(distractors[1], lesson.grammarExamples.first);
        expect(distractors.toSet(), hasLength(3));
        expect(lesson.story, hasLength(4));
        for (final p in lesson.story) {
          expect(p.trim().split(RegExp(r'\s+')).length,
              greaterThanOrEqualTo(20), reason: lesson.id);
        }
      }
    }
    expect(ruleTitles, hasLength(30));
    expect(ids, hasLength(30));
  });

  test('A2 forty-word categories are unique and recycled in reading and audio', () {
    for (final lesson in SpanishA2Course.lessons) {
      final words = lesson.words;
      expect(words, hasLength(40), reason: lesson.id);
      expect(words.map((w) => w.es.toLowerCase()).toSet(),
          hasLength(40), reason: lesson.id);
      expect(words.every((w) => w.es.isNotEmpty && w.ar.isNotEmpty), isTrue);
      for (final kind in SpanishWordKind.values) {
        expect(words.where((w) => w.kind == kind), hasLength(10));
      }
      final story = SpanishA2Course.reading(lesson);
      expect(story, hasLength(5));
      expect(story.first, lesson.story.first);
      expect(story.last.toLowerCase(), contains(words.first.es.toLowerCase()));
      expect(story.last.toLowerCase(),
          contains(SpanishA2Course.wordsOf(lesson, SpanishWordKind.verb)
              .first.es.toLowerCase()));
      expect(story.join(' ').trim().split(RegExp(r'\s+')).length,
          greaterThanOrEqualTo(140), reason: lesson.id);
      final conversation = SpanishA2Course.conversation(lesson);
      expect(conversation, hasLength(8));
      expect(conversation.join(' '), contains(words.first.es));
      final podcast = SpanishA2Course.podcast(lesson);
      expect(podcast, contains(lesson.title));
      expect(podcast, contains(lesson.story.first));
      for (final word in words) {
        expect(podcast.toLowerCase(), contains(word.es.toLowerCase()),
            reason: '${lesson.id}: ${word.es}');
      }
    }
  });

  test('A1 and A2 progress use different keys and never cross accounts',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final a1 = SpanishA1Course.find(1, 1);
    final a2 = SpanishA2Course.find(1, 1);
    expect(a1.id, isNot(equals(a2.id)));
    await SpanishA1Progress.complete('learnerA', a1);
    expect(await SpanishA1Progress.load('learnerA'), contains(a1.id));
    expect(await SpanishA1Progress.load('learnerA', level: 'A2'), isEmpty);
    await SpanishA1Progress.complete('learnerA', a2, level: 'A2');
    expect(await SpanishA1Progress.load('learnerA', level: 'A2'),
        contains(a2.id));
    expect(await SpanishA1Progress.load('learnerA'), contains(a1.id));
    expect(await SpanishA1Progress.load('learnerB', level: 'A2'), isEmpty);
    expect(await SpanishA1Progress.load(null, level: 'A2'), isEmpty);
    await expectLater(
      SpanishA1Progress.complete('learnerA', a1, level: 'A2'),
      throwsArgumentError);
  });

  testWidgets('A2 course opens three distinct unit cards', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(
        const MaterialApp(home: AcademySpanishA1Path(level: 'A2')));
    await tester.pumpAndSettle();
    expect(find.text('A2  ·  3 UNIDADES  ·  30 LECCIONES'), findsOneWidget);
    for (var unit = 1; unit <= 3; unit++) {
      expect(find.byKey(ValueKey('spanish-a2-unit-$unit')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('spanish-a1-unit-1')), findsNothing);
  });

  testWidgets('A2 first grammar section unlocks forty words but not completion',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final lesson = SpanishA2Course.find(1, 1);
    await tester.pumpWidget(MaterialApp(
      home: AcademySpanishA1LessonScreen(lesson: lesson, level: 'A2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('spanish-lesson-section-menu')), findsOneWidget);
    expect(find.text(lesson.grammar), findsNothing);
    expect(find.byKey(const ValueKey('spanish-grammar-check')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('spanish-section-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('spanish-lesson-section-detail-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('spanish-section-back')), findsOneWidget);
    expect(find.text(lesson.grammar), findsOneWidget);
    expect(find.byKey(const ValueKey('spanish-a2-finish')), findsNothing);
    final right = find.byKey(const ValueKey('spanish-grammar-option-1'));
    await tester.scrollUntilVisible(right, 350,
        scrollable: find.byType(Scrollable).first, maxScrolls: 25);
    await tester.pumpAndSettle();
    await tester.tap(right);
    await tester.pumpAndSettle();
    final check = find.byKey(const ValueKey('spanish-grammar-check'));
    await tester.scrollUntilVisible(check, 250,
        scrollable: find.byType(Scrollable).first, maxScrolls: 25);
    await tester.pumpAndSettle();
    await tester.tap(check);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('spanish-lesson-section-menu')), findsOneWidget);
    expect(find.byKey(const ValueKey('spanish-grammar-check')), findsNothing);
    expect(find.byKey(const ValueKey('spanish-vocabulary-next')), findsNothing);
    expect(find.byKey(const ValueKey('spanish-section-1')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('spanish-section-1')));
    await tester.tap(find.byKey(const ValueKey('spanish-section-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('spanish-lesson-section-detail-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('spanish-vocabulary-next')), findsOneWidget);
  });
}
