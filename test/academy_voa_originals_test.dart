import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/presentation/voa_originals_section.dart';
import 'package:worldvoice/features/learn/data/academy_podcast_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('15 real VOA originals, one source and Anna as recurring voice',
      () async {
    final list = await const VoaOriginalCatalog().load();
    expect(list, hasLength(15));
    expect(list.map((e) => e.id).toSet(), hasLength(15));
    expect(list.every((e) => e.isOfficialSource), isTrue);
    expect(list.where((e) => e.petePresent), hasLength(7));
    expect(list.every((e) => e.existingEpisodeId == e.id), isTrue);
    expect(list.map((e) => e.number).toList(),
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 20, 30, 47]);
  });

  test('VOA 01–12 have authentic source audio and readable bilingual dialogue',
      () async {
    const repository = AcademyPodcastRepository();
    final originals = await const VoaOriginalCatalog().load();
    for (final lesson in originals.where((e) => e.number <= 12)) {
      final entry = AcademyPodcastEntry(
        id: lesson.id, level: 'A1', language: 'en',
        title: lesson.title, titleAr: lesson.titleAr,
        status: 'published_audio',
        asset: 'assets/podcasts/en/A1/${lesson.id}.json',
      );
      final episode = await repository.load(entry);
      expect(episode.canStream, isTrue, reason: lesson.id);
      expect(episode.canReadAloud, isFalse, reason: lesson.id);
      expect(episode.isPlayable, isFalse,
          reason: 'No invented word timings for ${lesson.id}');
      expect(episode.audioUrl, lesson.audioUrl, reason: lesson.id);
      if ({2, 4, 5, 6, 7, 8, 9, 10, 11, 12}
          .contains(lesson.number)) {
        expect(episode.backupAudioUrl, isNotNull,
            reason: 'Alternative original VOA bitrate for ${lesson.id}');
        expect(episode.backupAudioUrl, endsWith('.mp3?download=1'));
        expect(episode.backupAudioUrl, isNot(episode.audioUrl));
      }
      expect(episode.sourceUrl, lesson.sourceUrl, reason: lesson.id);
      expect(episode.durationMs, lesson.durationSec * 1000,
          reason: lesson.id);
      expect(episode.dialogue, isNotEmpty, reason: lesson.id);
      expect(episode.dialogue.every((line) =>
          line.text.trim().isNotEmpty &&
          line.translationAr.trim().isNotEmpty), isTrue,
          reason: lesson.id);
      expect(episode.dialogue.every((line) =>
          line.startMs == null && line.endMs == null), isTrue,
          reason: lesson.id);
    }
  });

  testWidgets('VOA originals section presents native audio list',
      (tester) async {
    // Asset-bundle I/O is real asynchronous work; warm it outside the
    // fake-async frame pump before checking the FutureBuilder list.
    final loaded = await tester.runAsync(() =>
        const VoaOriginalCatalog().load());
    expect(loaded, hasLength(15));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SingleChildScrollView(
        child: VoaOriginalsSection(onOpen: (_) {}))),
    ));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('VOA index unavailable.'), findsNothing);
    expect(find.byKey(const ValueKey('podcast-original-en-a1-voa-001')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('podcast-original-en-a1-voa-020')),
        findsOneWidget);
    expect(find.text('VOA human audio · provisional sync'), findsOneWidget);
  });
}
