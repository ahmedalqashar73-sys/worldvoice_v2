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

    for (final code in ['en', 'es', 'fr', 'ko', 'ja', 'zh', 'de', 'ar']) {
      expect(find.byKey(ValueKey('podcast-language-$code')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('podcast-hero')), findsOneWidget);
    for (final level in ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']) {
      expect(find.byKey(ValueKey('podcast-level-$level')), findsOneWidget);
    }
    final french = find.byKey(const ValueKey('podcast-language-fr'));
    await tester.ensureVisible(french);
    await tester.tap(french);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byKey(const ValueKey('podcast-pending-fr')), findsOneWidget);
    expect(find.byKey(const ValueKey('podcast-episode-en-a1-pod-001')),
        findsNothing);

    final english = find.byKey(const ValueKey('podcast-language-en'));
    await tester.ensureVisible(english);
    await tester.tap(english);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byKey(const ValueKey('podcast-episode-en-a1-pod-001')),
        findsOneWidget);
    await tester.ensureVisible(
        find.byKey(const ValueKey('podcast-episode-en-a1-pod-001')));
    await tester.pumpAndSettle();
    await tester.tap(
        find.byKey(const ValueKey('podcast-episode-en-a1-pod-001')));
    await tester.pumpAndSettle();
    expect(find.text('Anna'), findsWidgets);
    expect(find.text('Daniel'), findsWidgets);
    expect(find.text('Hi! Is this seat free? The café is very busy today.'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('podcast-play-pause')), findsNothing);
    expect(find.byKey(const ValueKey('podcast-reader-header')), findsOneWidget);
    expect(find.byKey(const ValueKey('podcast-text-larger')), findsOneWidget);
    expect(find.byKey(const ValueKey('podcast-text-smaller')), findsOneWidget);
    expect(find.byKey(const ValueKey('podcast-sticky-player')), findsNothing);
    await tester.tap(
        find.byKey(const ValueKey('podcast-translation-toggle')));
    await tester.pump();
    expect(find.text('مرحبًا! هل هذا المقعد فارغ؟ المقهى مزدحم اليوم.'),
        findsOneWidget);
  });
}
