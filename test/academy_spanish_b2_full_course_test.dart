import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:worldvoice/features/learn/data/academy_spanish_a1_course.dart';
import 'package:worldvoice/features/learn/data/academy_spanish_a2_course.dart';
import 'package:worldvoice/features/learn/data/academy_spanish_b1_course.dart';
import 'package:worldvoice/features/learn/data/academy_spanish_b2_course.dart';
import 'package:worldvoice/features/learn/presentation/academy_spanish_a1_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Spanish B2 publishes exactly three units of ten authored lessons', () {
    expect(SpanishB2Course.units, hasLength(3));
    expect(SpanishB2Course.lessons, hasLength(30));
    final ids=<String>{};
    final rules=<String>{};
    for(final unit in SpanishB2Course.units) {
      expect(unit.lessons, hasLength(10));
      for(var number=1;number<=10;number++){
        final lesson=SpanishB2Course.find(unit.number,number);
        expect(lesson.id,'worldvoice.es.b2.u${unit.number}.l${number.toString().padLeft(2,'0')}');
        expect(ids.add(lesson.id),isTrue);
        expect(rules.add(lesson.grammar),isTrue);
        expect(lesson.title.trim(),isNotEmpty);
        expect(lesson.grammarAr.trim(),isNotEmpty);
        expect(lesson.grammarHelpAr.trim(),isNotEmpty);
        expect(lesson.grammarExamples,hasLength(8));
        expect(lesson.grammarMistakes,hasLength(2));
        final options=SpanishB2Course.grammarOptions(lesson);
        expect(options,hasLength(3));
        expect(options[1],lesson.grammarExamples.first);
        expect(options.toSet(),hasLength(3));
        expect(lesson.story,hasLength(5));
        for(final paragraph in lesson.story){
          expect(paragraph.split(RegExp(r'\s+')).length,
              greaterThanOrEqualTo(19),reason:lesson.id);
        }
      }
    }
    expect(ids,hasLength(30));
    expect(rules,hasLength(30));
  });

  test('B2 endings are authored individually for every lesson', (){
    final endings=SpanishB2Course.lessons.map((l)=>
        SpanishB2Course.reading(l).last).toList();
    expect(endings,hasLength(30));
    expect(endings.toSet(),hasLength(30));
    expect(endings.every((p)=>p.split(RegExp(r'\s+')).length>35),isTrue);
  });

  test('Every B2 lesson has forty balanced bilingual words reused in materials', (){
    for(final lesson in SpanishB2Course.lessons){
      final words=lesson.words;
      expect(words,hasLength(40),reason:lesson.id);
      expect(words.map((w)=>w.es.toLowerCase()).toSet(),
          hasLength(40),reason:lesson.id);
      expect(words.every((w)=>w.es.isNotEmpty&&w.ar.isNotEmpty),isTrue);
      for(final kind in SpanishWordKind.values){
        expect(words.where((w)=>w.kind==kind),hasLength(10),reason:lesson.id);
      }
      final reading=SpanishB2Course.reading(lesson);
      expect(reading,hasLength(7));
      expect(reading.first,lesson.story.first);
      expect(reading[5].toLowerCase(),contains(words.first.es.toLowerCase()));
      expect(reading.last.trim().split(RegExp(r'\s+')).length,greaterThan(35));
      final conversation=SpanishB2Course.conversation(lesson);
      expect(conversation,hasLength(8));
      expect(conversation.join(' ').toLowerCase(),
          contains(words.first.es.toLowerCase()));
      final podcast=SpanishB2Course.podcast(lesson);
      expect(podcast,contains(lesson.title));
      expect(podcast,contains(lesson.story.first));
      for(final word in words){
        expect(podcast.toLowerCase(),contains(word.es.toLowerCase()),
          reason:'${lesson.id} / ${word.es}');
      }
    }
  });

  test('B2 progress persists apart from Spanish A1 A2 B1 and other users',()async{
    SharedPreferences.setMockInitialValues(<String,Object>{});
    final a1=SpanishA1Course.find(1,1);
    final a2=SpanishA2Course.find(1,1);
    final b1=SpanishB1Course.find(1,1);
    final b2=SpanishB2Course.find(1,1);
    expect(<String>{a1.id,a2.id,b1.id,b2.id},hasLength(4));
    await SpanishA1Progress.complete('student',a1);
    await SpanishA1Progress.complete('student',a2,level:'A2');
    await SpanishA1Progress.complete('student',b1,level:'B1');
    expect(await SpanishA1Progress.load('student',level:'B2'),isEmpty);
    await SpanishA1Progress.complete('student',b2,level:'B2');
    expect(await SpanishA1Progress.load('student'),contains(a1.id));
    expect(await SpanishA1Progress.load('student',level:'A2'),contains(a2.id));
    expect(await SpanishA1Progress.load('student',level:'B1'),contains(b1.id));
    expect(await SpanishA1Progress.load('student',level:'B2'),contains(b2.id));
    expect(await SpanishA1Progress.load('another',level:'B2'),isEmpty);
    await expectLater(
      SpanishA1Progress.complete('student',a1,level:'B2'),throwsArgumentError);
  });

  testWidgets('Spanish B2 level shows three units without replacing earlier ones',
    (tester) async{
    SharedPreferences.setMockInitialValues(<String,Object>{});
    await tester.pumpWidget(const MaterialApp(home:
        AcademySpanishA1Path(level:'B2')));
    await tester.pumpAndSettle();
    expect(find.text('B2  ·  3 UNIDADES  ·  30 LECCIONES'),findsOneWidget);
    for(var number=1;number<=3;number++){
      expect(find.byKey(ValueKey('spanish-b2-unit-$number')),findsOneWidget);
    }
    expect(find.byKey(const ValueKey('spanish-b1-unit-1')),findsNothing);
  });

  testWidgets('B2 lesson starts with its own rule and protects the finish',
      (tester) async{
    tester.view.physicalSize=const Size(900,1500);
    tester.view.devicePixelRatio=1;
    addTearDown((){
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    SharedPreferences.setMockInitialValues(<String,Object>{});
    final lesson=SpanishB2Course.find(1,1);
    await tester.pumpWidget(MaterialApp(home:
      AcademySpanishA1LessonScreen(lesson:lesson,level:'B2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('spanish-lesson-section-menu')), findsOneWidget);
    expect(find.text(lesson.grammar), findsNothing);
    expect(find.byKey(const ValueKey('spanish-grammar-check')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('spanish-section-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('spanish-lesson-section-detail-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('spanish-section-back')), findsOneWidget);
    expect(find.text(lesson.grammar), findsOneWidget);
    expect(find.byKey(const ValueKey('spanish-b2-finish')),findsNothing);
    final correct=find.byKey(const ValueKey('spanish-grammar-option-1'));
    await tester.scrollUntilVisible(correct,350,
      scrollable:find.byType(Scrollable).first,maxScrolls:25);
    await tester.pumpAndSettle();
    await tester.tap(correct);
    await tester.pumpAndSettle();
    final check=find.byKey(const ValueKey('spanish-grammar-check'));
    await tester.scrollUntilVisible(check,260,
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
