import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worldvoice/features/learn/data/academy_spanish_a1_course.dart';
import 'package:worldvoice/features/learn/data/academy_spanish_a2_course.dart';
import 'package:worldvoice/features/learn/data/academy_spanish_b1_course.dart';
import 'package:worldvoice/features/learn/data/academy_spanish_b2_course.dart';
import 'package:worldvoice/features/learn/data/academy_spanish_c1_course.dart';
import 'package:worldvoice/features/learn/data/academy_spanish_c2_course.dart';
import 'package:worldvoice/features/learn/presentation/academy_spanish_a1_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final lessons=<String, SpanishA1Lesson>{
    'A1':SpanishA1Course.find(1,1),
    'A2':SpanishA2Course.find(1,1),
    'B1':SpanishB1Course.find(1,1),
    'B2':SpanishB2Course.find(1,1),
    'C1':SpanishC1Course.find(1,1),
    'C2':SpanishC2Course.find(1,1),
  };

  for(final entry in lessons.entries) {
    testWidgets('Spanish ${entry.key} shows eight English-style learning cards',
      (tester) async {
        tester.view.physicalSize=const Size(900,1500);
        tester.view.devicePixelRatio=1;
        addTearDown((){
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        SharedPreferences.setMockInitialValues(<String,Object>{});
        await tester.pumpWidget(MaterialApp(
          home:AcademySpanishA1LessonScreen(
            level:entry.key,lesson:entry.value)));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('spanish-eight-section-heading')),
          findsOneWidget);
        for(var index=0;index<8;index++){
          expect(find.byKey(ValueKey('spanish-section-$index')),
            findsOneWidget,reason:'${entry.key} section $index');
        }
        expect(find.text(entry.value.grammar),findsOneWidget);
        expect(find.byKey(ValueKey(
          'spanish-${entry.key.toLowerCase()}-finish')),findsNothing);
      });
  }

  test('All Spanish CEFR stages preserve 3 x 10 units and 40 words',(){
    final courses=<String,List<SpanishA1Lesson>>{
      'A1':SpanishA1Course.lessons,
      'A2':SpanishA2Course.lessons,
      'B1':SpanishB1Course.lessons,
      'B2':SpanishB2Course.lessons,
      'C1':SpanishC1Course.lessons,
      'C2':SpanishC2Course.lessons,
    };
    for(final entry in courses.entries){
      expect(entry.value,hasLength(30));
      for(final lesson in entry.value){
        expect(lesson.words,hasLength(40),reason:lesson.id);
        for(final kind in SpanishWordKind.values){
          expect(lesson.words.where((w)=>w.kind==kind),
            hasLength(10),reason:lesson.id);
        }
        expect(lesson.story.length,greaterThanOrEqualTo(3),
          reason:lesson.id);
      }
    }
  });
}
