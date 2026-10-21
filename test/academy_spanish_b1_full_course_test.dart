import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:worldvoice/features/learn/data/academy_spanish_a1_course.dart';
import 'package:worldvoice/features/learn/data/academy_spanish_a2_course.dart';
import 'package:worldvoice/features/learn/data/academy_spanish_b1_course.dart';
import 'package:worldvoice/features/learn/presentation/academy_spanish_a1_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Every B1 lesson has a distinct story epilogue connected to its reading',(){
    final paragraphs=SpanishB1Course.lessons.map((lesson) =>
        SpanishB1Course.reading(lesson).last).toList();
    expect(paragraphs,hasLength(30));
    expect(paragraphs.toSet(),hasLength(30));
    for(final p in paragraphs){
      expect(p.split(RegExp(r'\s+')).length,greaterThan(35));
    }
  });

  test('B1 has three authored units with exactly ten distinct lessons each', () {
    expect(SpanishB1Course.units, hasLength(3));
    expect(SpanishB1Course.lessons, hasLength(30));
    final ids = <String>{};
    final rules = <String>{};
    for (final unit in SpanishB1Course.units) {
      expect(unit.lessons, hasLength(10));
      for (var n=1; n<=10; n++) {
        final lesson=SpanishB1Course.find(unit.number,n);
        expect(lesson.id,
          'worldvoice.es.b1.u${unit.number}.l${n.toString().padLeft(2,'0')}');
        expect(ids.add(lesson.id),isTrue);
        expect(rules.add(lesson.grammar),isTrue);
        expect(lesson.grammarHelpAr.trim(),isNotEmpty);
        expect(lesson.grammarAr.trim(),isNotEmpty);
        expect(lesson.grammarExamples,hasLength(8));
        expect(lesson.grammarMistakes,hasLength(2));
        expect(lesson.story,hasLength(5));
        for(final p in lesson.story) {
          expect(p.trim().split(RegExp(r'\s+')).length,
            greaterThanOrEqualTo(15),reason:lesson.id);
        }
        final options=SpanishB1Course.grammarOptions(lesson);
        expect(options,hasLength(3));
        expect(options[1],lesson.grammarExamples.first);
        expect(options.toSet(),hasLength(3));
      }
    }
    expect(ids,hasLength(30));
    expect(rules,hasLength(30));
  });

  test('Every B1 lesson has 10 of each word class and aligned materials', () {
    for(final lesson in SpanishB1Course.lessons) {
      final words=lesson.words;
      expect(words,hasLength(40),reason:lesson.id);
      expect(words.map((w)=>w.es.toLowerCase()).toSet(),hasLength(40),
        reason:lesson.id);
      expect(words.every((w)=>w.es.trim().isNotEmpty &&
            w.ar.trim().isNotEmpty),isTrue);
      for(final kind in SpanishWordKind.values) {
        expect(words.where((w)=>w.kind==kind),hasLength(10),reason:lesson.id);
      }
      final reading=SpanishB1Course.reading(lesson);
      expect(reading,hasLength(7));
      expect(reading.first,lesson.story.first);
      expect(reading[5],contains(words.first.es));
      expect(reading.last.split(RegExp(r'\s+')).length,greaterThan(35));
      expect(reading.join(' ').split(RegExp(r'\s+')).length,
        greaterThanOrEqualTo(160),reason:lesson.id);
      final dialogue=SpanishB1Course.conversation(lesson);
      expect(dialogue,hasLength(8));
      expect(dialogue.join(' '),contains(words.first.es));
      final podcast=SpanishB1Course.podcast(lesson);
      expect(podcast,contains(lesson.title));
      expect(podcast,contains(lesson.story.first));
      for(final word in words) {
        expect(podcast.toLowerCase(),contains(word.es.toLowerCase()),
          reason:'${lesson.id}: ${word.es}');
      }
    }
  });

  test('Spanish B1 progress is separate from Spanish A1 and A2 accounts', () async {
    SharedPreferences.setMockInitialValues(<String,Object>{});
    final a1=SpanishA1Course.find(1,1);
    final a2=SpanishA2Course.find(1,1);
    final b1=SpanishB1Course.find(1,1);
    expect(<String>{a1.id,a2.id,b1.id},hasLength(3));
    await SpanishA1Progress.complete('student',a1);
    await SpanishA1Progress.complete('student',a2,level:'A2');
    expect(await SpanishA1Progress.load('student',level:'B1'),isEmpty);
    await SpanishA1Progress.complete('student',b1,level:'B1');
    expect(await SpanishA1Progress.load('student'),contains(a1.id));
    expect(await SpanishA1Progress.load('student',level:'A2'),contains(a2.id));
    expect(await SpanishA1Progress.load('student',level:'B1'),contains(b1.id));
    expect(await SpanishA1Progress.load('another',level:'B1'),isEmpty);
    await expectLater(SpanishA1Progress.complete('student',a1,level:'B1'),
      throwsArgumentError);
  });

  testWidgets('B1 shows its three units and not the A1 or A2 unit labels', (tester) async {
    SharedPreferences.setMockInitialValues(<String,Object>{});
    await tester.pumpWidget(const MaterialApp(
      home:AcademySpanishA1Path(level:'B1')));
    await tester.pumpAndSettle();
    expect(find.text('B1  ·  3 UNIDADES  ·  30 LECCIONES'),findsOneWidget);
    for(var n=1;n<=3;n++){
      expect(find.byKey(ValueKey('spanish-b1-unit-$n')),findsOneWidget);
    }
    expect(find.byKey(const ValueKey('spanish-a2-unit-1')),findsNothing);
  });

  testWidgets('B1 lesson begins with its own grammar and protects completion', (tester) async {
    tester.view.physicalSize=const Size(900,1500);
    tester.view.devicePixelRatio=1;
    addTearDown((){
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    SharedPreferences.setMockInitialValues(<String,Object>{});
    final lesson=SpanishB1Course.find(1,1);
    await tester.pumpWidget(MaterialApp(home:
      AcademySpanishA1LessonScreen(lesson:lesson,level:'B1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('spanish-lesson-section-menu')), findsOneWidget);
    expect(find.text(lesson.grammar), findsNothing);
    expect(find.byKey(const ValueKey('spanish-grammar-check')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('spanish-section-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('spanish-lesson-section-detail-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('spanish-section-back')), findsOneWidget);
    expect(find.text(lesson.grammar), findsOneWidget);
    expect(find.byKey(const ValueKey('spanish-b1-finish')),findsNothing);
    expect(find.byKey(const ValueKey('spanish-grammar-option-1')),findsOneWidget);
    final correct=find.byKey(const ValueKey('spanish-grammar-option-1'));
    await tester.scrollUntilVisible(correct,350,
      scrollable:find.byType(Scrollable).first,maxScrolls:25);
    await tester.pumpAndSettle();
    await tester.tap(correct);
    await tester.pumpAndSettle();
    final check=find.byKey(const ValueKey('spanish-grammar-check'));
    await tester.scrollUntilVisible(check,250,
      scrollable:find.byType(Scrollable).first,maxScrolls:25);
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
