import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/data/academy_podcast_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const repo = AcademyPodcastRepository();

  test('eight initial languages each have an A1-C2 learning track', () async {
    final languages = await repo.allLanguages();
    expect(languages, hasLength(8));
    expect(languages.map((e) => e.code).toSet(),
        {'en', 'es', 'fr', 'ko', 'ja', 'zh', 'de', 'ar'});
    expect(AcademyPodcastRepository.levels,
        ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']);
    expect(AcademyPodcastRepository.episodesPerLevel, 15);
  });

  test('ninety English podcast slots, fifteen per level', () async {
    final list = await repo.allEpisodes();
    expect(list, hasLength(90));
    expect(list.map((e) => e.id).toSet(), hasLength(90));
    expect(list.every((e) => e.language == 'en'), isTrue);
    for (final level in AcademyPodcastRepository.levels) {
      expect(list.where((e) => e.level == level), hasLength(15));
    }
    expect(list.where((e) => e.hasTranscript), hasLength(1));
  });

  test('the A1 Anna and Daniel transcript is complete but not audio-ready', () async {
    final list = await repo.allEpisodes();
    final episode = await repo.load(list.first);
    expect(episode.dialogue, hasLength(62));
    expect(episode.dialogue.map((e) => e.speaker).toSet(),
        {'Anna', 'Daniel'});
    expect(episode.dialogue.every((e) =>
        e.text.isNotEmpty && e.translationAr.isNotEmpty), isTrue);
    expect(episode.questions, hasLength(5));
    expect(episode.isPlayable, isFalse);
  });

  test('sync timestamps are required for playback', () {
    final episode = AcademyPodcastEpisode(
      id: 'test', level: 'A1', title: 'Test', titleAr: 'اختبار',
      status: 'published',
      audioUrl: 'https://example.org/voice.mp3',
      durationMs: 300000,
      dialogue: const [
        PodcastDialogueLine(speaker: 'Anna', text: 'Hello',
            translationAr: 'مرحبًا', startMs: 0, endMs: 150000),
        PodcastDialogueLine(speaker: 'Daniel', text: 'Hi',
            translationAr: 'أهلًا', startMs: 150000, endMs: 300000),
      ],
      vocabulary: const [], questions: const [],
    );
    expect(episode.isPlayable, isTrue);
    expect(episode.lineAt(const Duration(seconds: 1)), 0);
    expect(episode.lineAt(const Duration(seconds: 200)), 1);
  });
}
