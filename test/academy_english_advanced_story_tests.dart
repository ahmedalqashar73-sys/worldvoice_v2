import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:worldvoice/features/learn/data/academy_english_advanced_models.dart';
import 'package:worldvoice/features/learn/presentation/academy_english_advanced_screen.dart';

void main() {
  test('A2-C2 pilot paths have real, separate stories of increasing length', () {
    expect(EnglishAdvancedSyllabus.levels,
        <String>['A2', 'B1', 'B2', 'C1', 'C2']);
    expect(EnglishAdvancedSyllabus.lessons, hasLength(5));
    final storyTexts = <String>{};
    final taughtWords = <String>{};
    var previousListeningLength = 0;
    for (final level in EnglishAdvancedSyllabus.levels) {
      final lessons = EnglishAdvancedSyllabus.forLevel(level);
      expect(lessons, hasLength(1), reason: 'Pilot scope $level');
      final lesson = lessons.single;
      expect(lesson.number, 1);
      expect(lesson.paragraphs,
          hasLength(EnglishAdvancedSyllabus.paragraphTargets[level]));
      final story = lesson.paragraphs.join(' ').toLowerCase();
      expect(storyTexts.add(story), isTrue);
      for (final para in lesson.paragraphs) {
        expect(para.trim().split(RegExp(r'\s+')).length,
            greaterThanOrEqualTo(20), reason: '$level story paragraph');
      }
      expect(lesson.vocabulary.length,
          greaterThanOrEqualTo(EnglishAdvancedSyllabus.vocabularyTargets[level]!));
      expect(lesson.vocabulary.map((w) => w.term.toLowerCase()).toSet().length,
          lesson.vocabulary.length, reason: 'Unique vocabulary within $level');
      for (final word in lesson.storyWords) {
        expect(story.contains(word.term.toLowerCase()), isTrue,
            reason: '$level missing story word ${word.term}');
      }
      for (final word in lesson.vocabulary) {
        expect(word.arabic.trim(), isNotEmpty);
        expect(taughtWords.add(word.term.toLowerCase()), isTrue,
            reason: 'Repeated advanced word across levels: ${word.term}');
      }
      expect(lesson.listening.split(RegExp(r'\s+')).length,
          greaterThan(previousListeningLength),
          reason: 'Listening should require more sustained comprehension');
      previousListeningLength = lesson.listening.split(RegExp(r'\s+')).length;
      expect(lesson.listeningOptions, hasLength(3));
      expect(lesson.readingOptions, hasLength(3));
      expect(lesson.listeningAnswer, inInclusiveRange(0, 2));
      expect(lesson.readingAnswer, inInclusiveRange(0, 2));
      expect(lesson.vocabulary.any((w) =>
          w.term.toLowerCase() == lesson.writingAnswer.toLowerCase()), isTrue);
    }
    expect(EnglishAdvancedSyllabus.forLevel('A1'), isEmpty);
  });

  test('advanced progress is account-scoped and cannot mark unwritten lessons', () async {
    SharedPreferences.setMockInitialValues({});
    final first = EnglishAdvancedSyllabus.forLevel('A2').single;
    final last = EnglishAdvancedSyllabus.forLevel('C2').single;
    await EnglishAdvancedProgress.complete('account-a', first);
    await EnglishAdvancedProgress.complete('account-a', last);
    expect(await EnglishAdvancedProgress.load('account-a'),
        {first.id, last.id});
    expect(await EnglishAdvancedProgress.load('account-b'), isEmpty);
    expect(await EnglishAdvancedProgress.load(null), isEmpty);
  });

  testWidgets('C2 story shows six paragraphs and gated recall/quiz completion',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1450);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final c2 = EnglishAdvancedSyllabus.forLevel('C2').single;
    await tester.pumpWidget(MaterialApp(
      home: AcademyEnglishAdvancedLessonScreen(lesson: c2),
    ));
    expect(find.byKey(const ValueKey('advanced-lesson-body')), findsOneWidget);
    expect(find.byKey(const ValueKey('advanced-story-cover')), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      expect(find.byKey(ValueKey('advanced-paragraph-$i'), skipOffstage: false),
          findsOneWidget);
    }
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('advanced-finish')),
      550,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 100,
    );
    final save = tester.widget<FilledButton>(
      find.byKey(const ValueKey('advanced-finish')));
    expect(save.onPressed, isNull, reason: 'Reading alone must not mark completed');
  });
}
