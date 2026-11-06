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
    expect(list.where((e) => e.syncStatus == 'provisional'), hasLength(7));
    expect(list.where((e) => e.syncStatus == 'unverified'), hasLength(8));
    expect(list.every((e) => e.existingEpisodeId == e.id), isTrue);
    expect(list.map((e) => e.number).toList(),
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 20, 30, 47]);
  });

  test('VOA Level 2 has fifteen source-verified audio episodes', () async {
    final list = await const VoaOriginalCatalog(level: 'A2').load();
    expect(list, hasLength(15));
    expect(list.every((e) => e.isOfficialSource && e.level == 'A2'), isTrue);
    expect(list.map((e) => e.number).toList(),
        [1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15, 16]);
    expect(list.every((e) => e.syncStatus == 'unverified'), isTrue);
    expect(list.where((e) => e.transcriptScope == 'full').map((e) => e.number),
        [1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15, 16]);
    expect(list.where((e) => e.transcriptScope == 'excerpt'), isEmpty);
    expect(list.every((e) => e.existingEpisodeId == e.id), isTrue);
  });

  test('A2 audio and all full bilingual transcripts refer to the same VOA lesson',
      () async {
    const repository = AcademyPodcastRepository();
    final originals = await const VoaOriginalCatalog(level: 'A2').load();
    for (final item in originals) {
      final entry = AcademyPodcastEntry(
        id: item.id, level: 'A2', language: 'en',
        title: item.title, titleAr: item.titleAr,
        status: 'published_audio',
        asset: 'assets/podcasts/en/A2/${item.id}.json',
      );
      final episode = await repository.load(entry);
      expect(episode.canStream, isTrue, reason: item.id);
      expect(episode.canReadAloud, isFalse, reason: item.id);
      expect(episode.isPlayable, isFalse,
          reason: 'No invented word timings: ${item.id}');
      expect(episode.isExcerpt, isFalse, reason: item.id);
      expect(episode.sourceUrl, item.sourceUrl, reason: item.id);
      expect(episode.audioUrl, item.audioUrl, reason: item.id);
      expect(episode.backupAudioUrl, isNotNull, reason: item.id);
      expect(episode.durationMs, item.durationSec * 1000, reason: item.id);
      expect(episode.dialogue.length, greaterThanOrEqualTo(20),
          reason: item.id);
      expect(episode.dialogue.every((line) =>
          line.text.trim().isNotEmpty &&
          line.translationAr.trim().isNotEmpty &&
          line.startMs == null &&
          line.endMs == null), isTrue, reason: item.id);
      final speakers = {...episode.hosts, ...episode.otherSpeakers};
      expect(episode.dialogue.every((line) =>
          speakers.contains(line.speaker)), isTrue, reason: item.id);
    }
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
      const provisionalLessons = {1, 3, 8, 9, 11};
      final hasMeasuredCues = provisionalLessons.contains(lesson.number);
      expect(episode.isPlayable, hasMeasuredCues,
          reason: 'Provisional original-audio alignment for ${lesson.id}');
      if (hasMeasuredCues) {
        expect(episode.syncStatus, 'provisional');
      } else {
        expect(episode.syncStatus, 'unverified');
      }
      expect(episode.audioUrl, lesson.audioUrl, reason: lesson.id);
      if ({2, 4, 5, 6, 7, 8, 9, 10, 11, 12}
          .contains(lesson.number)) {
        expect(episode.backupAudioUrl, isNotNull,
            reason: 'Alternative original VOA bitrate for ${lesson.id}');
        expect(episode.backupAudioUrl, endsWith('.mp3?download=1'));
        expect(episode.backupAudioUrl, isNot(episode.audioUrl));
      }
      expect(episode.sourceUrl, lesson.sourceUrl, reason: lesson.id);
      // The player uses actual ffprobe duration with sub-second precision.
      expect((episode.durationMs! - lesson.durationSec * 1000).abs(),
          lessThan(1000), reason: lesson.id);
      expect(episode.dialogue, isNotEmpty, reason: lesson.id);
      expect(episode.dialogue.every((line) =>
          line.text.trim().isNotEmpty &&
          line.translationAr.trim().isNotEmpty), isTrue,
          reason: lesson.id);
      expect(episode.dialogue.every((line) =>
          hasMeasuredCues
              ? line.startMs != null && line.endMs != null
              : line.startMs == null && line.endMs == null), isTrue,
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
        child: VoaOriginalsSection(
          initialLessons: loaded!,
          onOpen: (_) {},
        ))),
    ));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('VOA index unavailable.'), findsNothing);
    expect(find.byKey(const ValueKey('podcast-original-en-a1-voa-001')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('podcast-original-en-a1-voa-020')),
        findsOneWidget);
    expect(find.text('VOA human audio · provisional sync'),
        findsNWidgets(7));
  });
  testWidgets('A2 VOA audio library distinguishes full bilingual texts from excerpts',
      (tester) async {
    final originals = await tester.runAsync(
        () => const VoaOriginalCatalog(level: 'A2').load());
    expect(originals, hasLength(15));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: VoaOriginalsSection(
            level: 'A2',
            initialLessons: originals!,
            onOpen: (_) {},
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('VOA index unavailable.'), findsNothing);
    expect(find.textContaining('full bilingual text'), findsNWidgets(15));
    expect(find.textContaining('translated excerpt'), findsNothing);
    expect(find.byKey(const ValueKey('podcast-original-en-a2-voa-001')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('podcast-original-en-a2-voa-016')),
        findsOneWidget);
  });

}
