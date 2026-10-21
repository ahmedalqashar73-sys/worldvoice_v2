import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worldvoice/features/learn/data/academy_spanish_a1_course.dart';
import 'package:worldvoice/features/learn/data/academy_spanish_lesson_stage_progress.dart';
import 'package:worldvoice/features/learn/data/academy_spanish_speech_chunks.dart';
import 'package:worldvoice/features/learn/presentation/academy_spanish_a1_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Long Spanish C-level podcasts split without losing ordinary words', () {
    final script=List<String>.generate(1000,
      (i)=>'La decisión número $i fue discutida cuidadosamente.').join(' ');
    expect(script.length,greaterThan(2400));
    final chunks=SpanishSpeechChunks.split(script);
    expect(chunks.length,greaterThan(3));
    expect(chunks.every((s)=>s.isNotEmpty&&s.length<=2400),isTrue);
    expect(chunks.join(' '),script);
    expect(chunks.first,startsWith('La decisión número 0'));
    expect(chunks.last,contains('999'));
  });

  test('Audio splitting handles newlines, accents and smaller thresholds', () {
    expect(SpanishSpeechChunks.split(' \n \t '),isEmpty);
    final chunks=SpanishSpeechChunks.split(
      '  ¡Qué bien!  Mañana iremos a Sevilla. \n ¿Qué opinas? ',
      maxCharacters:20);
    expect(chunks.every((p)=>p.isNotEmpty&&p.length<=20),isTrue);
    expect(chunks.join(' '),
      '¡Qué bien! Mañana iremos a Sevilla. ¿Qué opinas?');
    expect(()=>SpanishSpeechChunks.split('hola',maxCharacters:5),
      throwsRangeError);
  });

  test('Intermediate checkpoints remain separate by UID, level and lesson',
    () async {
    SharedPreferences.setMockInitialValues(<String,Object>{});
    const first='worldvoice.es.b1.u1.l01';
    const second='worldvoice.es.b1.u1.l02';
    const level='B1';
    expect(await SpanishLessonStageProgress.load('student',
      level:level,lessonId:first),0);
    await SpanishLessonStageProgress.save('student',
      level:level,lessonId:first,unlockedStage:3);
    expect(await SpanishLessonStageProgress.load('student',
      level:level,lessonId:first),3);
    expect(await SpanishLessonStageProgress.load('another',
      level:level,lessonId:first),0);
    expect(await SpanishLessonStageProgress.load('student',
      level:'B2',lessonId:first),0);
    expect(await SpanishLessonStageProgress.load('student',
      level:level,lessonId:second),0);
    await SpanishLessonStageProgress.save('student',
      level:level,lessonId:first,unlockedStage:1);
    expect(await SpanishLessonStageProgress.load('student',
      level:level,lessonId:first),3);
    await SpanishLessonStageProgress.save('student',
      level:level,lessonId:first,unlockedStage:7);
    expect(await SpanishLessonStageProgress.load('student',
      level:level,lessonId:first),7);
    await SpanishLessonStageProgress.clear('student',
      level:level,lessonId:first);
    expect(await SpanishLessonStageProgress.load('student',
      level:level,lessonId:first),0);
    await expectLater(
      SpanishLessonStageProgress.save('student',level:level,
        lessonId:first,unlockedStage:8),throwsRangeError);
  });

  testWidgets('Previously passed Spanish A1 stages reopen at next section',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String,Object>{});
    final lesson=SpanishA1Course.find(1,1);
    await SpanishLessonStageProgress.save(null,
      level:'A1',lessonId:lesson.id,unlockedStage:2);
    tester.view.physicalSize=const Size(900,1500);
    tester.view.devicePixelRatio=1;
    addTearDown((){
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(home:
      AcademySpanishA1LessonScreen(lesson:lesson,level:'A1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('spanish-story-cover')),findsOneWidget);
    expect(find.byKey(const ValueKey('spanish-vocabulary-next')),findsNothing);
    expect(find.byKey(const ValueKey('spanish-eight-section-heading')),
      findsOneWidget);
  });
}
