import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/presentation/story_library_section.dart';

void main() {
  testWidgets('independent A1 story catalog opens pages and Arabic translation',
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
    expect(
      find.byKey(const ValueKey('stories-book-the_small_green_bag')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('stories-book-the_small_green_bag')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Page 1 of 9'), findsOneWidget);
    expect(find.text('Maya is at the library.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('story-translation-1')));
    await tester.pumpAndSettle();
    expect(find.textContaining('مايا في المكتبة'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('stories-next-page')));
    await tester.pumpAndSettle();
    expect(find.text('Page 2 of 9'), findsOneWidget);
  });
}
