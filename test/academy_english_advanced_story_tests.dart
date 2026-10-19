import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:worldvoice/features/learn/data/academy_english_advanced_models.dart';
import 'package:worldvoice/features/learn/presentation/academy_english_advanced_screen.dart';

void main() {
  test('A2-C2 have two original graded stories and unique vocabulary', () {
    expect(EnglishAdvancedSyllabus.levels,
        <String>['A2', 'B1', 'B2', 'C1', 'C2']);
    expect(EnglishAdvancedSyllabus.lessons, hasLength(10));
    final storyTexts = <String>{};
    final taughtWords = <String>{};
    final previousListeningLength = <int>[0, 0];
    for (final level in EnglishAdvancedSyllabus.levels) {
      final lessons = EnglishAdvancedSyllabus.forLevel(level);
      expect(lessons, hasLength(2), reason: 'Published lessons $level');
      for (var index = 0; index < lessons.length; index++) {
        final lesson = lessons[index];
        expect(lesson.number, index + 1);
        expect(lesson.paragraphs,
            hasLength(EnglishAdvancedSyllabus.paragraphTargets[level]));
        final story = lesson.paragraphs.join(' ').toLowerCase();
        expect(storyTexts.add(story), isTrue);
        for (final paragraph in lesson.paragraphs) {
          expect(paragraph.trim().split(RegExp(r'\s+')).length,
              greaterThanOrEqualTo(20),
              reason: '$level lesson ${lesson.number}');
        }
        expect(lesson.vocabulary.length, greaterThanOrEqualTo(
            EnglishAdvancedSyllabus.vocabularyTargets[level]!));
        expect(lesson.vocabulary.map((w) => w.term.toLowerCase()).toSet().length,
            lesson.vocabulary.length);
        for (final word in lesson.storyWords) {
          expect(story.contains(word.term.toLowerCase()), isTrue,
              reason: '$level missing story word ${word.term}');
        }
        for (final word in lesson.vocabulary) {
          expect(word.arabic.trim(), isNotEmpty);
          expect(taughtWords.add(word.term.toLowerCase()), isTrue,
              reason: 'Repeated word: ${word.term}');
        }
        final listeningLength = lesson.listening.trim().split(RegExp(r'\s+')).length;
        expect(listeningLength, greaterThan(previousListeningLength[index]),
            reason: '$level listening must be more demanding');
        previousListeningLength[index] = listeningLength;
        expect(lesson.listeningOptions, hasLength(3));
        expect(lesson.readingOptions, hasLength(3));
        expect(lesson.listeningAnswer, inInclusiveRange(0, 2));
        expect(lesson.readingAnswer, inInclusiveRange(0, 2));
        expect(lesson.vocabulary.any((w) =>
            w.term.toLowerCase() == lesson.writingAnswer.toLowerCase()), isTrue);
      }
    }
    expect(EnglishAdvancedSyllabus.forLevel('A1'), isEmpty);
  });

  test('each level has three different story words to spell', () {
    for (final lesson in EnglishAdvancedSyllabus.lessons) {
      final challenge = lesson.spellingChallenge;
      expect(challenge, hasLength(3), reason: lesson.id);
      expect(challenge.first.term.toLowerCase(),
          lesson.writingAnswer.toLowerCase(), reason: lesson.id);
      expect(challenge.map((word) => word.term.toLowerCase()).toSet().length,
          3, reason: lesson.id);
      for (final word in challenge) {
        expect(lesson.storyWords.any((item) => item.term == word.term), isTrue);
        expect(word.arabic, isNotEmpty);
      }
    }
  });

  testWidgets('typing a correct story word unlocks the second word',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1450);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final lesson = EnglishAdvancedSyllabus.forLevel('A2').first;
    await tester.pumpWidget(MaterialApp(
      home: AcademyEnglishAdvancedLessonScreen(lesson: lesson),
    ));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('advanced-write-word')),
      550,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 100,
    );
    expect(find.text('1 / 3'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('advanced-write-word')),
        lesson.spellingChallenge.first.term);
    await tester.tap(find.byKey(const ValueKey('advanced-check-word')));
    await tester.pump();
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('Great! Now try the next story word.'), findsOneWidget);
  });

  test('advanced progress is account-scoped and cannot mark unwritten lessons', () async {
    SharedPreferences.setMockInitialValues({});
    final first = EnglishAdvancedSyllabus.forLevel('A2').first;
    final last = EnglishAdvancedSyllabus.forLevel('C2').first;
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
    final c2 = EnglishAdvancedSyllabus.forLevel('C2').first;
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
