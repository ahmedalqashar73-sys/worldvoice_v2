import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/data/story_library_repository.dart';
import 'package:worldvoice/features/learn/presentation/story_textbook_reader_screen.dart';

void main() {
  testWidgets('textbook shows chapter, definition, and chapter transition',
      (tester) async {
    final repository = StoryLibraryRepository();
    final entry = (await repository.loadIndex())
        .firstWhere((e) => e.id == 'en-a1-001');

    await tester.pumpWidget(MaterialApp(
      home: StoryTextbookReaderScreen(
        entry: entry,
        repository: repository,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('The Saturday Garden'), findsOneWidget);
    expect(find.text('Chapter 1: The Dry Garden'), findsOneWidget);
    expect(find.byKey(const ValueKey('textbook-image-0')), findsOneWidget);

    final keyword = find.text('morning');
    await tester.ensureVisible(keyword);
    await tester.pumpAndSettle();
    await tester.tap(keyword);
    await tester.pumpAndSettle();
    expect(find.text('صباح'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(const ValueKey('textbook-next')));
      await tester.pumpAndSettle();
    }
    expect(find.text('Chapter 2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('textbook-next-chapter')));
    await tester.pumpAndSettle();
    expect(find.text('Chapter 2: The Garden Team'), findsOneWidget);
  });
}
