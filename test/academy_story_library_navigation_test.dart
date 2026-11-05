import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/presentation/story_library_section.dart';

void main() {
  testWidgets('A1 shows exactly five textbook stories and opens vertical reader',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StoryLibrarySection(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stories-language-en')), findsOneWidget);
    expect(find.byKey(const ValueKey('stories-level-A1')), findsOneWidget);
    expect(find.byKey(const ValueKey('stories-book-en-a1-001')), findsOneWidget);
    expect(find.byKey(const ValueKey('stories-book-en-a1-002')), findsOneWidget);
    expect(find.byKey(const ValueKey('stories-book-en-a1-003')), findsOneWidget);
    expect(find.byKey(const ValueKey('stories-book-en-a1-004')), findsOneWidget);
    expect(find.byKey(const ValueKey('stories-book-en-a1-005')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('stories-book-the_small_green_bag')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('stories-book-en-a1-001')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('textbook-story-scroll')), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
    expect(find.text('The Saturday Garden'), findsOneWidget);
    expect(find.byKey(const ValueKey('textbook-chapter-1')), findsOneWidget);
  });
}
