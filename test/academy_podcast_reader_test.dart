import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/data/academy_podcast_repository.dart';
import 'package:worldvoice/features/learn/presentation/podcast_library_section.dart';
import 'package:worldvoice/features/learn/presentation/voa_originals_section.dart';

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
    expect(find.byKey(const ValueKey('podcast-original-en-a1-voa-020')),
        findsOneWidget);
    expect(find.text('VOA human audio · provisional sync'), findsNWidgets(7));
    final practice = find.byKey(const ValueKey('podcast-a1-reading-practice'));
    await tester.ensureVisible(practice);
    await tester.tap(practice);
    await tester.pumpAndSettle();
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
    expect(find.byKey(const ValueKey('podcast-jump-to-transcript')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('podcast-text-larger')), findsOneWidget);
    expect(find.byKey(const ValueKey('podcast-text-smaller')), findsOneWidget);
    expect(find.byKey(const ValueKey('podcast-auto-follow-toggle')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('podcast-sticky-player')), findsNothing);
    expect(find.byKey(const ValueKey('podcast-device-tts-player')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('podcast-device-tts-play-pause')),
        findsOneWidget);
    await tester.tap(
        find.byKey(const ValueKey('podcast-translation-toggle')));
    await tester.pump();
    expect(find.text('مرحبًا! هل هذا المقعد فارغ؟ المقهى مزدحم اليوم.'),
        findsOneWidget);
  });
  testWidgets('English A2 presents all 30 official VOA source lessons',
      (tester) async {
    // Warm the official A2 catalog before rendering, then pump by a bounded
    // interval: an active FutureBuilder spinner prevents pumpAndSettle.
    final loaded = await tester.runAsync(
        () => const VoaOriginalCatalog(level: 'A2').load());
    expect(loaded, hasLength(30));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: PodcastLibrarySection(
          initialA2Lessons: loaded,
        )),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final a2 = find.byKey(const ValueKey('podcast-level-A2'));
    await tester.ensureVisible(a2);
    await tester.tap(a2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    // Verify actual A2 tab integration here; the independent VOA section
    // widget test checks all 30 rendered cards without navigation races.
    expect(tester.widget<ChoiceChip>(a2).selected, isTrue);
    final section = tester.widget<VoaOriginalsSection>(
        find.byType(VoaOriginalsSection));
    expect(section.level, 'A2');
    expect(section.initialLessons, hasLength(30));
    expect(section.initialLessons!.any((e) => e.number == 8), isTrue);
    final full = loaded!.where((e) => e.transcriptScope == 'full').length;
    final excerpts = loaded.where((e) => e.transcriptScope == 'excerpt').length;
    expect(section.initialLessons!.where((e) =>
        e.transcriptScope == 'full'), hasLength(full));
    expect(section.initialLessons!.where((e) =>
        e.transcriptScope == 'excerpt'), hasLength(excerpts));
    expect(full + excerpts, 30);
  });

  testWidgets('Spanish A1 shows its complete bilingual readable pilot',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: PodcastLibrarySection()),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final spanish = find.byKey(const ValueKey('podcast-language-es'));
    await tester.ensureVisible(spanish);
    await tester.tap(spanish);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final pilot = find.byKey(const ValueKey('podcast-episode-es-a1-pod-001'));
    expect(pilot, findsOneWidget);
    await tester.ensureVisible(pilot);
    await tester.tap(pilot);
    await tester.pumpAndSettle();

    expect(find.text('Hola, ¿está libre esta silla? Hay mucha gente en la cafetería hoy.'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('podcast-play-pause')), findsNothing);
    expect(find.byKey(const ValueKey('podcast-device-tts-player')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('podcast-translation-toggle')));
    await tester.pump();
    expect(find.text('مرحبًا، هل هذا الكرسي فارغ؟ هناك أشخاص كثيرون في المقهى اليوم.'),
        findsOneWidget);
  });

  testWidgets('dark-mode conversation text stays readable on its surface',
      (tester) async {
    const entry = AcademyPodcastEntry(
      id: 'en-a1-static-review', level: 'A1',
      title: 'Reader contrast test', status: 'script_ready',
      asset: 'assets/podcasts/en/A1/en-a1-pod-001.json',
    );
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: const PodcastReaderScreen(
        entry: entry, repository: _StaticTranscriptRepository()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final sentence = find.text(
        'Everyone has a skill. You need to find yours.');
    expect(sentence, findsOneWidget);
    final text = tester.widget<Text>(sentence);
    final onSurface = Theme.of(tester.element(sentence)).colorScheme.onSurface;
    expect(text.style?.color, const Color(0xFFF5F8F5));
    expect(onSurface, isNot(Colors.transparent));
    final row = find.byKey(const ValueKey('podcast-dialogue-line-0'));
    expect(row, findsOneWidget);
    expect(tester.widget<Material>(row).color, const Color(0xFF22302A));
    expect(find.byKey(const ValueKey('podcast-line-text-0')), findsOneWidget);
    expect(find.text('Anna'), findsWidgets);
    // A paint exception here used to produce blank transcript cards.
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('podcast-sticky-player')), findsNothing);
    expect(find.text('Device voice'), findsOneWidget);
    expect(find.text(
        'Play the device voice to follow each line · No human recording.'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('podcast-device-tts-player')),
        findsOneWidget);
    final jump = find.byKey(const ValueKey('podcast-jump-to-transcript'));
    expect(jump, findsOneWidget);
    await tester.tap(jump);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('podcast-line-text-0')), findsOneWidget);
    final follow = find.byKey(const ValueKey('podcast-auto-follow-toggle'));
    expect(tester.widget<IconButton>(follow).tooltip, 'Disable auto-follow');
    await tester.tap(follow);
    await tester.pump();
    expect(tester.widget<IconButton>(follow).tooltip, 'Enable auto-follow');
  });

}

class _StaticTranscriptRepository extends AcademyPodcastRepository {
  const _StaticTranscriptRepository();

  @override
  Future<AcademyPodcastEpisode> load(AcademyPodcastEntry entry) async =>
      const AcademyPodcastEpisode(
        id: 'en-a1-static-review', level: 'A1',
        title: 'Reader contrast test', titleAr: 'اختبار قراءة النص',
        status: 'script_ready',
        dialogue: [
          PodcastDialogueLine(
            speaker: 'Anna',
            text: 'Everyone has a skill. You need to find yours.',
            translationAr: 'كل شخص لديه مهارة، وعليك أن تكتشف مهارتك.',
          ),
        ],
        vocabulary: [], questions: [],
      );
}
