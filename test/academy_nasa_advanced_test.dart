import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/presentation/nasa_advanced_podcast_section.dart';
import 'package:worldvoice/features/learn/presentation/podcast_library_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('exactly 90 unique original NASA recordings, 30 per B2 C1 C2',
      () async {
    final episodes = await const NasaLongCatalog().load();
    expect(episodes, hasLength(90));
    expect(episodes.map((e) => e.sourceUrl).toSet(), hasLength(90));
    expect(episodes.map((e) => e.audioUrl).toSet(), hasLength(90));
    for (final level in nasaAdvancedLevels) {
      final atLevel = episodes.where((e) => e.level == level).toList();
      expect(atLevel, hasLength(30));
      expect(atLevel.every((e) => e.isOfficialSource), isTrue);
      expect(atLevel.every((e) => e.durationSeconds >= 600), isTrue);
      expect(atLevel.map((e) => e.order),
          List<int>.generate(30, (index) => index + 1));
    }
  });

  test('Nasa transcript must retain source labels and nonempty Arabic',
      () {
    Map<String, dynamic> record() => {
      'id': 'en-c2-nasa-001',
      'audio_url': 'https://traffic.megaphone.fm/NATIONALAERONAUTICSANDSPACEADMINISTRATION8141278983.mp3',
      'content_source': 'NASA_official_podcast_transcript',
      'translation_status': 'machine_draft_review_required',
      'sync_status': 'unverified',
      'approved_for_publication': false,
      'dialogue': List.generate(12, (i) =>
          {'text': 'English $i', 'translation_ar': 'عربي $i'}),
    };
    expect(NasaBilingualTranscript.fromJson(record()).paragraphs, hasLength(12));
    final falseApproval = record();
    falseApproval['approved_for_publication'] = true;
    expect(() => NasaBilingualTranscript.fromJson(falseApproval),
        throwsFormatException);
    final emptyTranslation = record();
    (emptyTranslation['dialogue'] as List<dynamic>)[0]['translation_ar'] = '';
    expect(() => NasaBilingualTranscript.fromJson(emptyTranslation),
        throwsFormatException);
  });

  testWidgets('30 B2 originals show as normal podcast rows', (tester) async {
    final all = await tester.runAsync(() => const NasaLongCatalog().load());
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SingleChildScrollView(
        child: NasaLongPodcastSection(level: 'B2',
          initialEpisodes: all!),
      )),
    ));
    await tester.pump();
    expect(find.byKey(const ValueKey('nasa-B2-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('nasa-B2-30')), findsOneWidget);
  });

  testWidgets('B2 and C2 tabs show the new NASA long player catalog',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: SingleChildScrollView(child: PodcastLibrarySection()),
    )));
    await tester.pumpAndSettle();
    for (final level in ['B2', 'C2']) {
      final levelChip = find.byKey(ValueKey('podcast-level-$level'));
      await tester.ensureVisible(levelChip);
      await tester.tap(levelChip);
      // Podcasts contain an asynchronous asset catalog and may show a
      // loading indicator; pumpAndSettle would wait forever for its animation.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(NasaLongPodcastSection), findsOneWidget);
    }
  });
}
