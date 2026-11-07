import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/presentation/story_library_section.dart';
import 'package:worldvoice/features/learn/presentation/graded_story_reader_screen.dart';
import 'package:worldvoice/features/learn/data/graded_story_repository.dart';

void main() {
  testWidgets('English A1 shows only five licensed graded storybooks',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: StoryLibrarySection()),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stories-language-en')), findsOneWidget);
    expect(find.byKey(const ValueKey('stories-level-A1')), findsOneWidget);
    for (final id in ['0087', '0327', '0008', '0156', '0302']) {
      expect(find.byKey(ValueKey('stories-a1-open-ccby-$id')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('stories-book-en-a1-001')), findsNothing);
    expect(find.byKey(const ValueKey('stories-book-en-a1-005')), findsNothing);
    expect(find.textContaining('A1'), findsWidgets);
  });

  testWidgets('A1 opens original human-narrated reader, without old textbook',
      (tester) async {
    // Load assets outside fake-async before creating FutureBuilder readers.
    final repository = GradedStoryRepository();
    final entries = await tester.runAsync(() => repository.loadIndex());
    final first = entries!.firstWhere((entry) => entry.id == 'ccby-0087');
    await tester.runAsync(() => repository.loadBook(first));
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: StoryLibrarySection()),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final entry = find.byKey(const ValueKey('stories-a1-open-ccby-0087'));
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(GradedStoryReaderScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('textbook-story-scroll')), findsNothing);
    expect(find.byKey(const ValueKey('graded-original-audio-toggle')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('graded-a1-attribution')), findsOneWidget);
    expect(find.text('I Like to Read!'), findsWidgets);
  });
}
