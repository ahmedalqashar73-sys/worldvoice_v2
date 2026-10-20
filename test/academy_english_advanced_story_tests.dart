import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:worldvoice/features/learn/data/academy_english_advanced_models.dart';
import 'package:worldvoice/features/learn/data/academy_advanced_grammar_workshops.dart';
import 'package:worldvoice/features/learn/presentation/academy_english_advanced_screen.dart';

Future<void> openAdvancedSection(WidgetTester tester, int index) async {
  final target = find.byKey(ValueKey('advanced-section-$index'));
  await tester.scrollUntilVisible(target, 220,
      scrollable: find.byType(Scrollable).first, maxScrolls: 15);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> finishAdvancedSection(WidgetTester tester) async {
  final next = find.byKey(const ValueKey('advanced-section-next'));
  await tester.scrollUntilVisible(next, 260,
      scrollable: find.byType(Scrollable).first, maxScrolls: 80);
  await tester.ensureVisible(next);
  await tester.pumpAndSettle();
  final button = tester.widget<FilledButton>(next);
  expect(button.onPressed, isNotNull);
  await tester.tap(next);
  await tester.pumpAndSettle();
}

Future<void> reachAdvancedWriting(
    WidgetTester tester, EnglishAdvancedLesson lesson) async {
  // Same eight-section flow as A1: grammar, vocabulary, illustrated
  // story, word quiz, conversation, pronunciation, listening, completion.
  for (var index = 0; index < 3; index++) {
    await openAdvancedSection(tester, index);
    if (index == 0) {
      final workshop = AdvancedGrammarWorkshops.forLesson(
          lesson.level, lesson.number)!;
      final answer = find.byKey(
          ValueKey('advanced-grammar-option-${workshop.answer}'));
      await tester.ensureVisible(answer);
      await tester.pumpAndSettle();
      await tester.tap(answer);
      await tester.pump();
      final check = find.byKey(const ValueKey('advanced-grammar-check'));
      await tester.ensureVisible(check);
      await tester.pumpAndSettle();
      await tester.tap(check);
      await tester.pumpAndSettle();
    }
    await finishAdvancedSection(tester);
  }
  await openAdvancedSection(tester, 3);
}

void main() {
  test('A2-C2 published lessons have original graded stories and unique vocabulary', () {
    expect(EnglishAdvancedSyllabus.levels,
        <String>['A2', 'B1', 'B2', 'C1', 'C2']);
    expect(EnglishAdvancedSyllabus.lessons, hasLength(29));
    final storyTexts = <String>{};
    final taughtWords = <String>{};
    final previousListeningLength = <int>[0, 0];
    for (final level in EnglishAdvancedSyllabus.levels) {
      final lessons = EnglishAdvancedSyllabus.forLevel(level);
      expect(lessons, hasLength(level == 'A2' ? 10 : level == 'B1' ? 10 : 3),
          reason: 'Published lessons $level');
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
        if (index < previousListeningLength.length) {
          expect(listeningLength, greaterThan(previousListeningLength[index]),
              reason: '$level listening must be more demanding');
          previousListeningLength[index] = listeningLength;
        }
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

  test('B1 first unit lessons 4–6 have full unique authored content', () {
    final earlier = EnglishAdvancedSyllabus.lessons.where((lesson) =>
        !(lesson.level == 'B1' && lesson.unitNumber == 1 &&
            lesson.number >= 4 && lesson.number <= 6));
    final previousWords = earlier.expand((lesson) =>
        lesson.vocabulary.map((word) => word.term.toLowerCase())).toSet();
    final newWords = <String>{};
    for (var number = 4; number <= 6; number++) {
      final lesson = EnglishAdvancedSyllabus.findLesson('B1', 1, number);
      expect(lesson, isNotNull, reason: 'B1 Unit 1 Lesson $number');
      expect(lesson!.paragraphs, hasLength(4));
      expect(lesson.vocabulary, hasLength(30));
      expect(lesson.storyWords, hasLength(12));
      expect(lesson.extraWords, hasLength(18));
      final story = lesson.paragraphs.join(' ').toLowerCase();
      for (final word in lesson.storyWords) {
        expect(story.contains(word.term.toLowerCase()), isTrue,
            reason: '${lesson.id} story missing ${word.term}');
      }
      for (final word in lesson.vocabulary) {
        expect(previousWords.contains(word.term.toLowerCase()), isFalse,
            reason: 'Reused established vocabulary: ${word.term}');
        expect(newWords.add(word.term.toLowerCase()), isTrue,
            reason: 'Reused new vocabulary: ${word.term}');
      }
      expect(lesson.listening.trim().split(RegExp(r'\s+')).length,
          greaterThanOrEqualTo(65));
      final grammar = AdvancedGrammarWorkshops.forLesson('B1', number);
      expect(grammar, isNotNull);
      expect(grammar!.examples, hasLength(3));
      expect(grammar.options, hasLength(3));
      final dialogue = EnglishAdvancedDialogues.forLesson(lesson);
      expect(dialogue.lines, hasLength(5));
      expect(dialogue.pronunciation, hasLength(3));
      expect(lesson.spellingChallenge, hasLength(3));
    }
    expect(newWords, hasLength(90));
  });

  test('B1 unit one is fully authored, with four new unique graded lessons', () {
    final all = EnglishAdvancedSyllabus.lessons;
    final earlier = all.where((lesson) => !(lesson.level == 'B1' &&
        lesson.unitNumber == 1 && lesson.number >= 7 && lesson.number <= 10));
    final earlierWords = earlier.expand(
        (lesson) => lesson.vocabulary.map((term) => term.term.toLowerCase())).toSet();
    final newWords = <String>{};
    expect(EnglishAdvancedSyllabus.forUnit('B1', 1), hasLength(10));
    for (var i = 7; i <= 10; i++) {
      final lesson = EnglishAdvancedSyllabus.findLesson('B1', 1, i);
      expect(lesson, isNotNull, reason: 'B1 Unit 1 Lesson $i');
      expect(lesson!.paragraphs, hasLength(4));
      expect(lesson.storyWords, hasLength(12));
      expect(lesson.extraWords, hasLength(18));
      expect(lesson.vocabulary, hasLength(30));
      for (final paragraph in lesson.paragraphs) {
        expect(paragraph.trim().split(RegExp(r'\s+')).length,
            greaterThanOrEqualTo(20), reason: lesson.id);
      }
      final story = lesson.paragraphs.join(' ').toLowerCase();
      for (final word in lesson.storyWords) {
        expect(story.contains(word.term.toLowerCase()), isTrue,
            reason: '${lesson.id}: missing ${word.term}');
      }
      for (final word in lesson.vocabulary) {
        final term = word.term.toLowerCase();
        expect(earlierWords.contains(term), isFalse, reason: term);
        expect(newWords.add(term), isTrue, reason: term);
        expect(word.arabic.trim(), isNotEmpty);
      }
      expect(lesson.listening.trim().split(RegExp(r'\s+')).length,
          greaterThanOrEqualTo(65));
      expect(lesson.spellingChallenge, hasLength(3));
      final workshop = AdvancedGrammarWorkshops.forLesson('B1', i);
      expect(workshop, isNotNull);
      expect(workshop!.examples, hasLength(3));
      expect(workshop.options, hasLength(3));
      final dialogue = EnglishAdvancedDialogues.forLesson(lesson);
      expect(dialogue.lines, hasLength(5));
      expect(dialogue.pronunciation, hasLength(3));
    }
    expect(newWords, hasLength(120));
  });

  test('Every higher level has three A1-style units with ten lesson slots', () {
    expect(EnglishAdvancedCurriculum.plannedSlotCount, 150);
    for (final level in EnglishAdvancedSyllabus.levels) {
      final units = EnglishAdvancedSyllabus.unitsForLevel(level);
      expect(units, hasLength(3), reason: level);
      for (var unitIndex = 0; unitIndex < 3; unitIndex++) {
        final unit = units[unitIndex];
        expect(unit.number, unitIndex + 1);
        expect(unit.level, level);
        expect(unit.title.trim(), isNotEmpty);
        expect(unit.titleArabic.trim(), isNotEmpty);
        expect(unit.plannedTopics, hasLength(10));
        expect(unit.plannedTopics.toSet().length, 10);
        for (var number = 1; number <= 10; number++) {
          final lesson = unit.lessonAt(number);
          if (unit.number == 1 && number <= (level == 'A2' ? 10 : level == 'B1' ? 10 : 3)) {
            expect(lesson, isNotNull);
            expect(lesson!.number, number);
            expect(lesson.unitNumber, unit.number);
            expect(lesson.id, 'worldvoice.en.${level.toLowerCase()}.u1.l${number.toString().padLeft(2, '0')}');
          } else {
            expect(lesson, isNull,
                reason: 'Do not falsely publish an unwritten $level unit ${unit.number} lesson $number');
          }
        }
      }
    }
  });

  test('the newly-authored A2 fifth and B1 third lessons are real full sessions', () {
    for (final (level, number) in [('A2', 5), ('B1', 3)]) {
      final lesson = EnglishAdvancedSyllabus.findLesson(level, 1, number)!;
      expect(lesson.paragraphs, hasLength(
          EnglishAdvancedSyllabus.paragraphTargets[level]));
      expect(lesson.vocabulary, hasLength(
          EnglishAdvancedSyllabus.vocabularyTargets[level]));
      expect(lesson.storyWords.length, greaterThanOrEqualTo(12));
      expect(lesson.spellingChallenge, hasLength(3));
      expect(AdvancedGrammarWorkshops.forLesson(level, number), isNotNull);
      final dialogue = EnglishAdvancedDialogues.forLesson(lesson);
      expect(dialogue.lines, hasLength(5));
      expect(dialogue.pronunciation, hasLength(3));
      expect(lesson.listening.split(RegExp(r'\s+')).length,
          greaterThanOrEqualTo(65));
    }
  });

  test('B2, C1 and C2 third lessons are complete, original and graded', () {
    for (final level in ['B2', 'C1', 'C2']) {
      final lesson = EnglishAdvancedSyllabus.findLesson(level, 1, 3)!;
      expect(lesson.paragraphs,
          hasLength(EnglishAdvancedSyllabus.paragraphTargets[level]));
      expect(lesson.vocabulary,
          hasLength(EnglishAdvancedSyllabus.vocabularyTargets[level]));
      expect(lesson.storyWords.length, greaterThanOrEqualTo(12));
      expect(lesson.spellingChallenge, hasLength(3));
      expect(lesson.listening.trim().split(RegExp(r'\s+')).length,
          greaterThanOrEqualTo(80));
      final workshop = AdvancedGrammarWorkshops.forLesson(level, 3);
      expect(workshop, isNotNull);
      expect(workshop!.examples, hasLength(3));
      final dialogue = EnglishAdvancedDialogues.forLesson(lesson);
      expect(dialogue.lines, hasLength(5));
      expect(dialogue.pronunciation, hasLength(3));
    }
  });

  test('A2 lessons three and four have full instruction and non-repeating story words', () {
    final a2 = EnglishAdvancedSyllabus.forUnit('A2', 1);
    expect(a2, hasLength(10));
    final third = EnglishAdvancedSyllabus.findLesson('A2', 1, 3)!;
    final fourth = EnglishAdvancedSyllabus.findLesson('A2', 1, 4)!;
    expect(third.title, 'Finding an Apartment');
    expect(fourth.title, 'At the Pharmacy');
    for (final lesson in [third, fourth]) {
      expect(lesson.paragraphs, hasLength(3));
      expect(lesson.vocabulary, hasLength(24));
      expect(lesson.storyWords, hasLength(10));
      expect(lesson.extraWords, hasLength(14));
      expect(lesson.listening.trim().split(RegExp(r'\s+')).length,
          greaterThanOrEqualTo(45));
      expect(lesson.grammarExamples, hasLength(3));
      expect(lesson.spellingChallenge, hasLength(3));
      expect(EnglishAdvancedDialogues.forLesson(lesson).lines, hasLength(5));
    }
  });

  test('A2 first unit has ten distinct complete lessons with no placeholder', () {
    final published = EnglishAdvancedSyllabus.forUnit('A2', 1);
    expect(published, hasLength(10));
    final titles = <String>{};
    for (var number = 1; number <= 10; number++) {
      final lesson = EnglishAdvancedSyllabus.findLesson('A2', 1, number);
      expect(lesson, isNotNull, reason: 'A2 lesson $number must be authored');
      expect(titles.add(lesson!.title), isTrue);
      expect(lesson.storyWords.length, greaterThanOrEqualTo(10));
      expect(lesson.paragraphs, hasLength(3));
      expect(lesson.vocabulary.length, greaterThanOrEqualTo(24));
      expect(lesson.listening.trim().split(RegExp(r'\s+')).length,
          greaterThanOrEqualTo(35));
      expect(AdvancedGrammarWorkshops.forLesson('A2', number), isNotNull);
      final dialogue = EnglishAdvancedDialogues.forLesson(lesson);
      expect(dialogue.lines, hasLength(5));
      expect(dialogue.pronunciation, hasLength(3));
      expect(lesson.spellingChallenge, hasLength(3));
    }
    expect(EnglishAdvancedSyllabus.forUnit('A2', 2), isEmpty);
    expect(EnglishAdvancedSyllabus.forUnit('A2', 3), isEmpty);
  });

  test('Every published advanced lesson has a distinct guided dialogue and IPA practice', () {
    for (final lesson in EnglishAdvancedSyllabus.lessons) {
      final dialogue = EnglishAdvancedDialogues.forLesson(lesson);
      expect(dialogue.lines.length, greaterThanOrEqualTo(4));
      expect(dialogue.tipArabic.trim(), isNotEmpty);
      expect(dialogue.pronunciation, hasLength(3));
      expect(dialogue.pronunciation.every((cue) =>
          cue.contains(' /') && cue.endsWith('/')), isTrue);
    }
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

  testWidgets('A2 lesson menu matches the eight A1 sections in order',
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
    const expected = [
      'Grammar', 'Vocabulary', 'Illustrated story', 'Word quiz',
      'Conversation', 'Pronunciation', 'Listening', 'Complete',
    ];
    for (var i = 0; i < expected.length; i++) {
      final key = find.byKey(ValueKey('advanced-section-$i'));
      await tester.scrollUntilVisible(key, 220,
          scrollable: find.byType(Scrollable).first, maxScrolls: 15);
      await tester.pumpAndSettle();
      expect(find.descendant(of: key, matching: find.text(expected[i])),
          findsOneWidget);
      expect(tester.widget<InkWell>(key).onTap,
          i == 0 ? isNotNull : isNull);
    }
  });

  testWidgets('an A2 student reaches written recall through all lesson sections',
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
    expect(find.byKey(const ValueKey('advanced-section-menu')), findsOneWidget);
    final locked = tester.widget<InkWell>(
      find.byKey(const ValueKey('advanced-section-4'), skipOffstage: false));
    expect(locked.onTap, isNull);
    await reachAdvancedWriting(tester, lesson);
    final input = find.byKey(const ValueKey('advanced-write-word'));
    await tester.scrollUntilVisible(input, 500,
        scrollable: find.byType(Scrollable).first, maxScrolls: 80);
    expect(find.text('1 / 3'), findsOneWidget);
    await tester.enterText(input, lesson.spellingChallenge.first.term);
    final check = find.byKey(const ValueKey('advanced-check-word'));
    await tester.ensureVisible(check);
    await tester.tap(check);
    await tester.pump();
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('Great! Now try the next story word.'), findsOneWidget);
    final next = find.byKey(const ValueKey('advanced-section-next'));
    await tester.scrollUntilVisible(next, 550,
        scrollable: find.byType(Scrollable).first, maxScrolls: 80);
    expect(tester.widget<FilledButton>(next).onPressed, isNull,
        reason: 'An unfinished spelling/writing task must lock completion.');
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

  testWidgets('advanced C2 level opens Unit 1 before the lesson cards',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1450);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const MaterialApp(
      home: AcademyEnglishAdvancedLevelScreen(level: 'C2'),
    ));
    for (var i = 1; i <= 3; i++) {
      expect(find.byKey(ValueKey('advanced-unit-$i')), findsOneWidget);
    }
    await tester.tap(find.byKey(const ValueKey('advanced-unit-1')));
    await tester.pumpAndSettle();
    expect(find.text('Lesson 1'), findsOneWidget);
    expect(find.text('Lesson 2'), findsOneWidget);
    // All ten lesson slots are visible but unpublished content is locked.
    expect(find.byKey(const ValueKey('advanced-lesson-C2-1-10'),
        skipOffstage: false), findsOneWidget);
    final locked = tester.widget<InkWell>(
      find.byKey(const ValueKey('advanced-lesson-C2-1-10'),
          skipOffstage: false));
    expect(locked.onTap, isNull);
  });

  testWidgets('C2 story remains six paragraphs inside its own lesson section',
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
    expect(find.byKey(const ValueKey('advanced-section-menu')),
        findsOneWidget);
    for (var index = 0; index < 2; index++) {
      await openAdvancedSection(tester, index);
      if (index == 0) {
        final workshop = AdvancedGrammarWorkshops.forLesson(
            c2.level, c2.number)!;
        final choice = find.byKey(
            ValueKey('advanced-grammar-option-${workshop.answer}'));
        await tester.ensureVisible(choice);
        await tester.pumpAndSettle();
        await tester.tap(choice);
        await tester.pump();
        final check = find.byKey(const ValueKey('advanced-grammar-check'));
        await tester.ensureVisible(check);
        await tester.pumpAndSettle();
        await tester.tap(check);
        await tester.pumpAndSettle();
      }
      await finishAdvancedSection(tester);
    }
    await openAdvancedSection(tester, 2);
    expect(find.byKey(const ValueKey('advanced-story-cover')), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      expect(find.byKey(ValueKey('advanced-paragraph-$i'), skipOffstage: false),
          findsOneWidget);
    }
    expect(find.byKey(const ValueKey('advanced-finish')), findsNothing);
  });

}
