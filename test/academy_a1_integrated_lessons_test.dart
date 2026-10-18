import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/data/academy_english_a1_catalog.dart';
import 'package:worldvoice/features/learn/data/academy_english_a1_vocabulary.dart';
import 'package:worldvoice/features/learn/data/academy_english_a1_long_stories.dart';
import 'package:worldvoice/features/learn/data/academy_english_a1_teaching.dart';
import 'package:worldvoice/features/learn/presentation/academy_english_a1_full_lesson.dart';

void main() {
  test('every lesson has its own dialogue, grammar rule and listening', () {
    expect(EnglishA1TeachingCatalog.lessons.length, 3);
    for (var unit = 1; unit <= 3; unit++) {
      final material = EnglishA1TeachingCatalog.lessons[unit - 1];
      expect(material.length, 12);
      expect(material.map((m) => m.dialogue).toSet().length, 12);
      expect(material.map((m) => m.listening).toSet().length, 12);
      for (var lesson = 1; lesson <= 12; lesson++) {
        final study = EnglishA1TeachingCatalog.forLesson(unit, lesson);
        expect(study.dialogue.contains(': '), true);
        expect(study.dialogue.contains('\n'), true);
        expect(study.grammar.trim().length, greaterThan(30));
        expect(study.grammarArabic.trim().length, greaterThan(15));
        expect(study.listening.trim().split(RegExp(r'\s+')).length,
            greaterThanOrEqualTo(10));
      }
    }
  });

  test('A1 contains 36 distinct full lessons with 20 vocabulary items each', () {
    expect(EnglishA1Catalog.units.length, 3);
    expect(EnglishA1Catalog.lessonCount, 36);
    expect(EnglishA1Vocabulary.wordSlots, 720);
    final ids = <String>{};
    for (final unit in EnglishA1Catalog.units) {
      expect(unit.lessons.length, 12);
      for (var index = 0; index < unit.lessons.length; index++) {
        final lesson = unit.lessons[index];
        expect(ids.add(lesson.id), isTrue);
        final terms = EnglishA1Vocabulary.forLesson(unit.id, index + 1);
        expect(terms, hasLength(20), reason: lesson.id);
        for (final term in terms) {
          expect(term.english.trim(), isNotEmpty);
          expect(term.arabic.trim(), isNotEmpty);
        }
        expect(terms.map((term) => term.english.toLowerCase()).toSet().length,
          20, reason: lesson.id);
      }
    }
    expect(ids.length, 36);
  });

  test('each unit has three substantial four-paragraph original storybooks', () {
    expect(EnglishA1LongStories.stories, hasLength(9));
    final ids = <String>{};
    for (var unit = 1; unit <= 3; unit++) {
      final stories = EnglishA1LongStories.forUnit(unit);
      expect(stories, hasLength(3));
      for (var index = 1; index <= 12; index++) {
        final story = EnglishA1LongStories.forLesson(unit, index);
        expect(stories.contains(story), isTrue);
      }
      for (final story in stories) {
        expect(ids.add(story.id), isTrue);
        expect(story.pages, hasLength(4));
        expect(story.scene, inInclusiveRange(0, 8));
        expect(story.question, isNotEmpty);
        expect(story.options.length, 3);
        expect(story.answer, inInclusiveRange(0, 2));
        for (final page in story.pages) {
          expect(page.text.trim().split(RegExp(r'\s+')).length,
            greaterThanOrEqualTo(20), reason: story.id);
          expect(page.arabic.trim(), isNotEmpty);
        }
      }
    }
    expect(ids.length, 9);
  });

  testWidgets('full lesson opens with eight stages and correct title',
      (tester) async {
    final unit = EnglishA1Catalog.units.first;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AcademyEnglishA1FullLesson(
        unit: unit, lesson: unit.lessons.first, index: 0),
    ));
    expect(find.textContaining('الدرس 1'), findsOneWidget);
    expect(find.text('مرحلة 1 من 8'), findsOneWidget);
    expect(find.textContaining('التمهيد'), findsWidgets);
    expect(find.byKey(const ValueKey('academy-full-lesson-next')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('academy-full-lesson-next')));
    await tester.pumpAndSettle();
    expect(find.text('20 مفردة في هذا الدرس'), findsOneWidget);
    expect(find.byKey(const ValueKey('academy-word-0')), findsOneWidget);
  });
}
