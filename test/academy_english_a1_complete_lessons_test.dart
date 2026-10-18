import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:worldvoice/features/learn/data/academy_english_a1_catalog.dart';
import 'package:worldvoice/features/learn/data/academy_english_a1_long_stories.dart';
import 'package:worldvoice/features/learn/data/academy_english_a1_vocabulary.dart';
import 'package:worldvoice/features/learn/presentation/academy_english_a1_full_lesson.dart';
import 'package:worldvoice/features/learn/presentation/academy_english_a1_book_reader.dart';
import 'package:worldvoice/features/learn/presentation/academy_illustrated_story_art.dart';

void main() {
  test('36 complete English A1 lessons each introduce exactly 20 real terms', () {
    expect(EnglishA1Catalog.units.length, 3);
    expect(EnglishA1Catalog.lessonCount, 36);
    expect(EnglishA1Vocabulary.wordSlots, 720);
    for (final unit in EnglishA1Catalog.units) {
      expect(unit.lessons.length, 12);
      for (var n = 1; n <= unit.lessons.length; n++) {
        final words = EnglishA1Vocabulary.forLesson(unit.id, n);
        expect(words.length, 20, reason: 'Unit ${unit.id}, lesson $n');
        expect(words.map((word) => word.english).toSet().length, 20,
          reason: 'Duplicate terms within unit ${unit.id}, lesson $n');
        for (final word in words) {
          expect(word.english.trim(), isNotEmpty);
          expect(word.arabic.trim(), isNotEmpty);
          expect(word.english.contains('='), false);
          expect(word.arabic.contains('|'), false);
        }
        final story = EnglishA1LongStories.forLesson(unit.id, n);
        expect(story.pages.length, 4);
      }
    }
  });

  test('nine authored readers: three per unit, four substantive paragraphs each', () {
    expect(EnglishA1LongStories.stories.length, 9);
    for (var unit = 1; unit <= 3; unit++) {
      final stories = EnglishA1LongStories.forUnit(unit);
      expect(stories.length, 3);
      expect(stories.map((story) => story.id).toSet().length, 3);
      for (var index = 0; index < 3; index++) {
        final story = stories[index];
        for (var lesson = index * 4 + 1; lesson <= index * 4 + 4; lesson++) {
          expect(EnglishA1LongStories.forLesson(unit, lesson).id, story.id);
        }
        expect(story.scene, inInclusiveRange(0, 8));
        expect(story.titleAr.trim(), isNotEmpty);
        expect(story.options.length, 3);
        expect(story.answer, inInclusiveRange(0, 2));
        expect(story.pages.length, 4);
        for (final paragraph in story.pages) {
          expect(paragraph.text.trim().split(RegExp(r'\s+')).length,
            greaterThanOrEqualTo(25), reason: story.id);
          expect(paragraph.arabic.trim().split(RegExp(r'\s+')).length,
            greaterThanOrEqualTo(15), reason: story.id);
        }
      }
    }
  });

  testWidgets('one complete lesson starts with eight stages, not one quiz',
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
        unit: unit,
        lesson: unit.lessons.first,
        index: 0,
      ),
    ));
    expect(find.textContaining('مرحلة 1 من 8'), findsOneWidget);
    expect(find.text('رحلة اليوم'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('academy-full-lesson-next')));
    await tester.pumpAndSettle();
    expect(find.text('20 مفردة في هذا الدرس'), findsOneWidget);
    expect(find.byKey(const ValueKey('academy-word-0')), findsOneWidget);
  });

  testWidgets('storybook displays a cover and four paragraph page transitions',
      (tester) async {
    final story = EnglishA1LongStories.forUnit(1).first;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AcademyEnglishA1BookReader(story: story),
    ));
    expect(find.byKey(const ValueKey('storybook-cover')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('english-story-next')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('storybook-chapter-0')), findsOneWidget);
    expect(find.byType(AcademyIllustratedStoryArt), findsOneWidget);
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
  });

  testWidgets('all nine original scene compositions render', (tester) async {
    for (var i = 0; i < 9; i++) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SizedBox(width: 360,
          child: AcademyIllustratedStoryArt(scene: i, page: i % 4))),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CustomPaint), findsWidgets);
    }
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
  });
}
