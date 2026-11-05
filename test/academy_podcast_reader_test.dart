import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/presentation/podcast_library_section.dart';

void main() {
  testWidgets('Podcast tab shows CEFR levels and script-ready pilot',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: PodcastLibrarySection()),
      ),
    ));
    await tester.pumpAndSettle();

    for (final level in ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']) {
      expect(find.byKey(ValueKey('podcast-level-$level')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('podcast-episode-en-a1-pod-001')),
        findsOneWidget);
    await tester.tap(
        find.byKey(const ValueKey('podcast-episode-en-a1-pod-001')));
    await tester.pumpAndSettle();
    expect(find.text('Anna'), findsWidgets);
    expect(find.text('Daniel'), findsWidgets);
    expect(find.text('Hi! Is this seat free? The café is very busy today.'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('podcast-play-pause')), findsNothing);
    await tester.tap(
        find.byKey(const ValueKey('podcast-translation-toggle')));
    await tester.pump();
    expect(find.text('مرحبًا! هل هذا المقعد فارغ؟ المقهى مزدحم اليوم.'),
        findsOneWidget);
  });
}
