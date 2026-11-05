import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/data/story_library_repository.dart';
import 'package:worldvoice/features/learn/presentation/story_textbook_reader_screen.dart';

void main() {
  testWidgets('textbook is one vertical scroll with vocabulary and chapters',
      (tester) async {
    final repository = StoryLibraryRepository();
    final entry = (await repository.loadIndex())
        .firstWhere((e) => e.id == 'en-a1-001');
    await tester.pumpWidget(MaterialApp(
      home: StoryTextbookReaderScreen(
        entry: entry, repository: repository),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('textbook-story-scroll')),
        findsOneWidget);
    expect(find.byType(PageView), findsNothing);
    expect(find.text('The Saturday Garden'), findsOneWidget);
    expect(find.byKey(const ValueKey('textbook-chapter-1')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('textbook-image-0')),
        findsOneWidget);
    final scroll = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const ValueKey('textbook-story-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scroll.position.pixels, 0);
    await tester.drag(
      find.byKey(const ValueKey('textbook-image-0')),
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();
    expect(scroll.position.pixels, greaterThan(0));
    final keyword = find.text('morning');
    await tester.ensureVisible(keyword);
    await tester.tap(keyword);
    await tester.pumpAndSettle();
    expect(find.text('صباح'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    final paragraphTranslation =
        find.byKey(const ValueKey('textbook-translation-0:0:0'));
    await tester.ensureVisible(paragraphTranslation);
    await tester.tap(paragraphTranslation);
    await tester.pumpAndSettle();
    expect(find.textContaining('في صباح السبت'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('textbook-chapter-2')),
      350,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('textbook-story-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.byKey(const ValueKey('textbook-chapter-2')),
        findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('textbook-story-scroll')),
      const Offset(0, 420),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsNothing);
    expect(find.byKey(const ValueKey('textbook-play')), findsOneWidget);
    expect(find.byKey(const ValueKey('textbook-speed')), findsOneWidget);
  });
}
