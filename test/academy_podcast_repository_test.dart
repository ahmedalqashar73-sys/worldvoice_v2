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

  test('720 planned slots across 8 languages and 6 CEFR levels',
      () async {
    final list = await repo.allEpisodes();
    expect(list, hasLength(720));
    expect(list.map((e) => e.id).toSet(), hasLength(720));
    for (final language in await repo.allLanguages()) {
      for (final level in AcademyPodcastRepository.levels) {
        expect(list.where((e) =>
            e.language == language.code && e.level == level), hasLength(15));
      }
    }
    expect(list.where((e) => e.hasTranscript), hasLength(3));
    expect(list.where((e) => e.status == 'planned'), hasLength(717));
  });

  test('the Anna and Daniel draft stays unchanged and without recording', () async {
    final list = await repo.allEpisodes();
    final draft = list.singleWhere((e) => e.id == 'en-a1-pod-001');
    final episode = await repo.load(draft);
    expect(episode.dialogue, hasLength(62));
    expect(episode.dialogue.map((e) => e.speaker).toSet(),
        {'Anna', 'Daniel'});
    expect(episode.dialogue.every((e) =>
        e.text.isNotEmpty && e.translationAr.isNotEmpty), isTrue);
    expect(episode.questions, hasLength(5));
    expect(episode.isPlayable, isFalse);
  });

  test('Spanish A1 has 62 translated two-host turns without fake audio',
      () async {
    final entries = await repo.allEpisodes();
    final spanish = entries.singleWhere((e) => e.id == 'es-a1-pod-001');
    expect(spanish.language, 'es');
    expect(spanish.status, 'script_ready');
    final book = await repo.load(spanish);
    expect(book.language, 'es');
    expect(book.dialogue, hasLength(62));
    expect(book.dialogue.map((line) => line.speaker).toSet(),
        {'Anna', 'Daniel'});
    expect(book.dialogue.every((line) =>
        line.text.isNotEmpty && line.translationAr.isNotEmpty), isTrue);
    expect(book.questions, hasLength(5));
    expect(book.isPlayable, isFalse);
    expect(book.audioUrl, isNull);
  });

  test('VOA Lesson 20 has real source audio and exact credited speakers',
      () async {
    final entries = await repo.allEpisodes();
    final item = entries.singleWhere((e) => e.id == 'en-a1-voa-020');
    expect(item.status, 'published_audio');
    expect(item.language, 'en');
    final lesson = await repo.load(item);
    expect(lesson.title, 'What Can You Do?');
    expect(lesson.hosts, ['Anna', 'Pete']);
    expect(lesson.otherSpeakers, ['Marsha']);
    expect(lesson.dialogue, hasLength(44));
    expect(lesson.dialogue.map((line) => line.speaker).toSet(),
        {'Anna', 'Pete', 'Marsha'});
    expect(lesson.dialogue.every((line) =>
        line.text.trim().isNotEmpty && line.translationAr.trim().isNotEmpty),
        isTrue);
    expect(lesson.audioUrl, contains('voa-audio.voanews.eu'));
    expect(lesson.sourceUrl, contains('learningenglish.voanews.com'));
    expect(lesson.durationMs, 219311);
    expect(lesson.canStream, isTrue);
    expect(lesson.syncStatus, 'provisional');
    expect(lesson.isPlayable, isTrue,
        reason: 'Measured but provisional cues support trial read-along');
    expect(lesson.lineAt(const Duration(seconds: 50)), isNotNull);
    expect(lesson.dialogue.every((line) =>
        line.startMs != null && line.endMs != null), isTrue);
  });

  test('sync timestamps are required for playback', () {
    final episode = AcademyPodcastEpisode(
      id: 'test', level: 'A1', title: 'Test', titleAr: 'اختبار',
      status: 'published',
      recordingKind: 'human',
      rightsConfirmed: true,
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
    final noRights = AcademyPodcastEpisode(
      id: 'test', level: 'A1', title: 'Test', titleAr: 'اختبار',
      status: 'published', recordingKind: 'human',
      rightsConfirmed: false, audioUrl: 'https://example.org/voice.mp3',
      durationMs: 300000, dialogue: episode.dialogue,
      vocabulary: const [], questions: const [],
    );
    expect(noRights.isPlayable, isFalse);
    expect(episode.lineAt(const Duration(seconds: 1)), 0);
    expect(episode.lineAt(const Duration(seconds: 200)), 1);
  });
}
