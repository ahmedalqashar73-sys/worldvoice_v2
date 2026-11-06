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
    expect(list.where((e) => e.syncStatus == 'provisional'), isEmpty);
    expect(list.where((e) => e.syncStatus == 'unverified'), hasLength(15));
    expect(list.every((e) => e.durationSec >= 240 && e.durationSec <= 360),
        isTrue);
    expect(list.every((e) => e.transcriptScope == 'excerpt'), isTrue);
    expect(list.every((e) => e.audioUrl.contains('.mp4')), isTrue);
    expect(list.every((e) => e.existingEpisodeId == e.id), isTrue);
    expect(list.map((e) => e.number).toList(),
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 20, 30, 47]);
  });

  test('VOA Level 2 catalog includes all 30 original lesson recordings', () async {
    final list = await const VoaOriginalCatalog(level: 'A2').load();
    expect(list, hasLength(30));
    expect(list.every((e) => e.isOfficialSource && e.level == 'A2'), isTrue);
    expect(list.map((e) => e.number).toList(),
        List<int>.generate(30, (i) => i + 1));
    expect(list.singleWhere((e) => e.number == 8).audioUrl,
        contains('voa-video-ns.akamaized.net'));
    expect(list.every((e) => e.syncStatus == 'unverified'), isTrue);
    final full = list.where((e) => e.transcriptScope == 'full').toList();
    final excerpts = list.where((e) => e.transcriptScope == 'excerpt').toList();
    expect(full.map((e) => e.number),
        containsAll([1, 2, 3, 4, 5, 6, 9, 11, 12, 14, 15, 16]));
    expect(excerpts.map((e) => e.number),
        containsAll([7, 8, 10, 13, 17]));
    expect(full.length + excerpts.length, 30);
    expect(list.where((e) => e.translationStatus == 'machine_draft')
        .every((e) => e.transcriptScope == 'full'), isTrue);
    expect(list.every((e) => e.existingEpisodeId == e.id), isTrue);
    expect(list.every((e) => e.durationSec >= 240),
        isTrue, reason: 'VOA A2 uses real full lessons where clips were short');
  });

  test('A2 authentic audio refers to its translated VOA dialogue',
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
      expect(episode.isExcerpt, item.transcriptScope == 'excerpt',
          reason: item.id);
      expect(episode.sourceUrl, item.sourceUrl, reason: item.id);
      expect(episode.audioUrl, item.audioUrl, reason: item.id);
      // Availability of an alternative bitrate is independent of whether
      // the dialogue is complete. Lesson 17+ may have only one VOA MP3.
      if (episode.backupAudioUrl != null) {
        expect(episode.backupAudioUrl, isNot(equals(episode.audioUrl)),
            reason: item.id);
        expect(episode.backupAudioUrl, startsWith('https://'),
            reason: item.id);
      }
      expect(episode.durationMs, item.durationSec * 1000, reason: item.id);
      expect(episode.dialogue.length,
          greaterThanOrEqualTo(item.transcriptScope == 'full' ? 20 : 5),
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
      expect(episode.isPlayable, isFalse,
          reason: 'The earlier short MP3 cues must not be used for full lessons');
      expect(episode.syncStatus, 'unverified');
      expect(episode.isExcerpt, isTrue);
      expect(episode.durationMs, greaterThanOrEqualTo(240000));
      expect(episode.audioUrl, lesson.audioUrl, reason: lesson.id);
      expect(episode.backupAudioUrl, isNull,
          reason: 'No fallback to sub-four-minute clips');
      expect(episode.sourceUrl, lesson.sourceUrl, reason: lesson.id);
      // The index reports the VOA site's full-lesson duration.
      expect((episode.durationMs! - lesson.durationSec * 1000).abs(),
          lessThan(1000), reason: lesson.id);
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
    expect(find.text('VOA · full ~5-minute lesson · translated conversation'),
        findsNWidgets(15));
  });
  testWidgets('A2 VOA audio library distinguishes full bilingual texts from excerpts',
      (tester) async {
    final originals = await tester.runAsync(
        () => const VoaOriginalCatalog(level: 'A2').load());
    expect(originals, hasLength(30));
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
    final complete = originals.where((e) => e.transcriptScope == 'full').length;
    final partial = originals.where((e) => e.transcriptScope == 'excerpt').length;
    expect(find.descendant(
        of: find.byType(ListTile),
        matching: find.textContaining('full bilingual text')),
        findsNWidgets(complete));
    expect(find.descendant(
        of: find.byType(ListTile),
        matching: find.textContaining('translated excerpt')),
        findsNWidgets(partial));
    expect(find.byKey(const ValueKey('podcast-original-en-a2-voa-001')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('podcast-original-en-a2-voa-030')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('podcast-original-en-a2-voa-008')),
        findsOneWidget);
  });

}
