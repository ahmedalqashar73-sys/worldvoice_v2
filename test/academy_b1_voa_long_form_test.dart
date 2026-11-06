import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/presentation/b1_voa_long_form_section.dart';
import 'package:worldvoice/features/learn/presentation/b1_voa_transcript_section.dart';
import 'package:worldvoice/features/learn/presentation/podcast_library_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('exactly 30 real VOA B1 sources, no duplicates or fake transcripts',
      () async {
    final recordings = await const B1VoaLongCatalog().load();
    expect(recordings, hasLength(30));
    expect(recordings.map((e) => e.order).toList(),
        List<int>.generate(30, (i) => i + 1));
    expect(recordings.map((e) => e.id).toSet(), hasLength(30));
    expect(recordings.map((e) => e.audioUrl).toSet(), hasLength(30));
    expect(recordings.map((e) => e.sourceUrl).toSet(), hasLength(30));
    expect(recordings.every((e) => e.isVerifiedVoaSource), isTrue);
    expect(recordings.every((e) => e.approximateDurationMinutes >= 10),
        isTrue);
    expect(recordings.every((e) =>
        e.transcriptStatus == 'pending_full_audio_transcription_review' &&
        e.translationStatus == 'pending_english_transcript'), isTrue);
    expect(recordings.first.publishedDate, '2025-03-02');
    expect(recordings.last.publishedDate, '2025-03-31');
  });

  test('reject misleading hosts even if the recorded length is plausible',
      () async {
    final first = (await const B1VoaLongCatalog().load()).first;
    final fake = B1VoaLongEpisode(
      id: first.id,
      order: first.order,
      title: first.title,
      titleAr: first.titleAr,
      publishedDate: first.publishedDate,
      audioUrl: 'https://voa-audio.voanews.eu.evil.com/vle/fake.mp3',
      sourceUrl: first.sourceUrl,
      approximateDurationMinutes: 30,
      transcriptStatus: first.transcriptStatus,
      translationStatus: first.translationStatus,
    );
    expect(fake.isVerifiedVoaSource, isFalse);
  });

  testWidgets('B1 catalog lists 30 original audio recordings',
      (tester) async {
    final recordings = await tester.runAsync(
        () => const B1VoaLongCatalog().load());
    expect(recordings, hasLength(30));
    // Read the real bundled bilingual asset before asserting the async
    // readiness UI. A fixed pump duration does not settle rootBundle IO.
    final available = await tester.runAsync(
        () => const B1VoaTranscriptRepository().availableIds());
    expect(available, hasLength(30));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: B1VoaLongSection(initialEpisodes: recordings!),
        ),
      ),
    ));
    await tester.pump();
    expect(find.byKey(const ValueKey('b1-voa-long-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('b1-voa-long-30')), findsOneWidget);
    // Both the original recordings and all thirty bilingual assets must
    // exist. The visible readiness labels depend on an async FutureBuilder,
    // so assert the model's verified availability, not frame scheduling.
    expect(available.toSet(), hasLength(30));
    expect(recordings.every((recording) =>
        available.contains(recording.id)), isTrue);
  });

  testWidgets('English B1 tab exposes the official long podcast catalog',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: PodcastLibrarySection()),
      ),
    ));
    await tester.pumpAndSettle();
    final b1 = find.byKey(const ValueKey('podcast-level-B1'));
    await tester.ensureVisible(b1);
    await tester.tap(b1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(B1VoaLongSection), findsOneWidget);
  });
}
