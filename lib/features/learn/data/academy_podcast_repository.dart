import 'dart:convert';

import 'package:flutter/services.dart';

/// One of the initial eight podcast languages, with its own A1–C2 track.
/// A language appearing in the library does not imply it has recorded audio.
class PodcastLanguage {
  const PodcastLanguage({
    required this.code,
    required this.nativeName,
    required this.arabicName,
    required this.flag,
  });

  final String code;
  final String nativeName;
  final String arabicName;
  final String flag;

  factory PodcastLanguage.fromJson(Map<String, dynamic> json) =>
      PodcastLanguage(
        code: json['code'] as String,
        nativeName: json['native_name'] as String,
        arabicName: json['name_ar'] as String,
        flag: json['flag'] as String,
      );
}

/// Podcast metadata deliberately separates planning from published audio.
/// A text-only draft must never be represented as an audible episode.
class AcademyPodcastEntry {
  const AcademyPodcastEntry({
    required this.id,
    required this.level,
    required this.title,
    required this.status,
    this.language = 'en',
    this.titleAr,
    this.asset,
  });

  final String id;
  final String level;
  final String language;
  final String title;
  final String? titleAr;
  final String status;
  final String? asset;

  bool get hasTranscript => asset != null && asset!.isNotEmpty;
  bool get isPlanned => status == 'planned';

  factory AcademyPodcastEntry.fromJson(Map<String, dynamic> json) =>
      AcademyPodcastEntry(
        id: json['id'] as String,
        level: json['level'] as String,
        language: json['language'] as String? ?? 'en',
        title: json['title'] as String,
        titleAr: json['title_ar'] as String?,
        status: json['status'] as String,
        asset: json['asset'] as String?,
      );
}

class PodcastDialogueLine {
  const PodcastDialogueLine({
    required this.speaker,
    required this.text,
    required this.translationAr,
    this.startMs,
    this.endMs,
    this.translationEn,
  });

  final String speaker;
  final String text;
  final String translationAr;
  final String? translationEn;
  final int? startMs;
  final int? endMs;

  factory PodcastDialogueLine.fromJson(Map<String, dynamic> json) =>
      PodcastDialogueLine(
        speaker: json['speaker'] as String,
        text: json['text'] as String,
        translationAr: json['translation_ar'] as String,
        translationEn: json['translation_en'] as String?,
        startMs: json['start_ms'] as int?,
        endMs: json['end_ms'] as int?,
      );
}

class PodcastVocabulary {
  const PodcastVocabulary({required this.word, required this.meaningAr});
  final String word;
  final String meaningAr;

  factory PodcastVocabulary.fromJson(Map<String, dynamic> json) =>
      PodcastVocabulary(
        word: json['word'] as String,
        meaningAr: json['meaning_ar'] as String,
      );
}

class PodcastQuestion {
  const PodcastQuestion({
    required this.question,
    required this.options,
    required this.answer,
  });
  final String question;
  final List<String> options;
  final int answer;

  factory PodcastQuestion.fromJson(Map<String, dynamic> json) =>
      PodcastQuestion(
        question: json['question'] as String,
        options: List<String>.from(json['options'] as List<dynamic>),
        answer: json['answer'] as int,
      );
}

class AcademyPodcastEpisode {
  const AcademyPodcastEpisode({
    required this.id,
    required this.level,
    required this.title,
    required this.titleAr,
    required this.status,
    required this.dialogue,
    required this.vocabulary,
    required this.questions,
    this.audioUrl,
    this.backupAudioUrl,
    this.durationMs,
    this.language = 'en',
    this.recordingKind,
    this.rightsConfirmed = false,
    this.sourceUrl,
    this.sourceCredit,
    this.syncStatus,
    this.hosts = const ['Anna', 'Daniel'],
    this.otherSpeakers = const [],
  });

  final String id;
  final String level;
  final String title;
  final String titleAr;
  final String status;
  final String language;
  final String? recordingKind;
  final bool rightsConfirmed;
  final String? sourceUrl;
  final String? sourceCredit;
  final String? syncStatus;
  final List<String> hosts;
  final List<String> otherSpeakers;
  final String? audioUrl;
  final String? backupAudioUrl;
  final int? durationMs;
  final List<PodcastDialogueLine> dialogue;
  final List<PodcastVocabulary> vocabulary;
  final List<PodcastQuestion> questions;

  /// Real rights-cleared MP3 can stream while sentence-level alignment
  /// is still pending. Do not invent timings or show a false highlight.
  bool get canStream {
    if ((status != 'published' && status != 'published_audio') ||
        recordingKind != 'human' || !rightsConfirmed ||
        durationMs == null || durationMs! <= 0) {
      return false;
    }
    final uri = Uri.tryParse(audioUrl ?? '');
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty &&
        dialogue.isNotEmpty;
  }

  /// English A1 scripts without an audio recording can be read aloud by
  /// the user's device TTS engine. This never represents human audio.
  bool get canReadAloud =>
      language == 'en' &&
      level == 'A1' &&
      status == 'script_ready' &&
      !canStream &&
      dialogue.isNotEmpty;

  /// Line-by-line automatic highlighting requires *measured* cues.
  /// Older original WorldVoice scripts still use two fixed hosts; VOA
  /// licensed lessons may also include named incidental performers.
  bool get isPlayable {
    if (!canStream || durationMs! < 190000 || durationMs! > 315000) {
      return false;
    }
    final allowedSpeakers = <String>{...hosts, ...otherSpeakers};
    var previousEnd = 0;
    for (final line in dialogue) {
      final start = line.startMs;
      final end = line.endMs;
      if (!allowedSpeakers.contains(line.speaker) ||
          start == null || end == null ||
          start < previousEnd || end <= start || end > durationMs! ||
          line.text.trim().isEmpty ||
          (language == 'ar'
              ? (line.translationEn ?? '').trim().isEmpty
              : line.translationAr.trim().isEmpty)) {
        return false;
      }
      previousEnd = end;
    }
    return dialogue.first.startMs! <= 5000 &&
        durationMs! - previousEnd <= 10000;
  }

  /// Keep the last spoken sentence selected through natural pauses.
  /// The reader advances only when the NEXT sentence actually starts,
  /// rather than clearing its marker and jumping during a brief silence.
  int? lineAt(Duration position) {
    if (!isPlayable) return null;
    final ms = position.inMilliseconds;
    if (ms < dialogue.first.startMs! || ms >= durationMs!) return null;
    int? current;
    for (var i = 0; i < dialogue.length; i++) {
      if (ms < dialogue[i].startMs!) break;
      current = i;
    }
    return current;
  }

  factory AcademyPodcastEpisode.fromJson(Map<String, dynamic> json) =>
      AcademyPodcastEpisode(
        id: json['id'] as String,
        level: json['level'] as String,
        title: json['title'] as String,
        titleAr: json['title_ar'] as String,
        status: json['status'] as String,
        language: json['language'] as String? ?? 'en',
        recordingKind: json['recording_kind'] as String?,
        rightsConfirmed: json['voice_rights_verified'] as bool? ?? false,
        sourceUrl: json['source_url'] as String?,
        sourceCredit: json['source_credit'] as String?,
        syncStatus: json['sync_status'] as String?,
        hosts: json['hosts'] is List
            ? List<String>.from(json['hosts'] as List<dynamic>)
            : const ['Anna', 'Daniel'],
        otherSpeakers: json['other_speakers'] is List
            ? List<String>.from(json['other_speakers'] as List<dynamic>)
            : const <String>[],
        audioUrl: json['audio_url'] as String?,
        backupAudioUrl: json['backup_audio_url'] as String?,
        durationMs: json['duration_ms'] as int?,
        dialogue: (json['dialogue'] as List<dynamic>)
            .map((line) => PodcastDialogueLine.fromJson(
                line as Map<String, dynamic>)).toList(growable: false),
        vocabulary: (json['vocabulary'] as List<dynamic>)
            .map((word) => PodcastVocabulary.fromJson(
                word as Map<String, dynamic>)).toList(growable: false),
        questions: (json['questions'] as List<dynamic>)
            .map((q) => PodcastQuestion.fromJson(
                q as Map<String, dynamic>)).toList(growable: false),
      );
}

class AcademyPodcastRepository {
  const AcademyPodcastRepository();

  static const levels = <String>['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  static const episodesPerLevel = 15;

  /// The multilingual index exceeds Flutter's 50 KB loadString threshold.
  /// Decode its raw bytes directly so loading is deterministic in widget
  /// tests and does not spawn an isolate for every tab rebuild.
  Future<Map<String, dynamic>> _readIndex() async {
    final bytes = await rootBundle.load('assets/podcasts/index.json');
    final text = utf8.decode(bytes.buffer.asUint8List(
      bytes.offsetInBytes, bytes.lengthInBytes,
    ));
    return jsonDecode(text) as Map<String, dynamic>;
  }

  Future<List<PodcastLanguage>> allLanguages() async {
    final data = await _readIndex();
    return (data['languages'] as List<dynamic>)
        .map((item) => PodcastLanguage.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<AcademyPodcastEntry>> allEpisodes() async {
    final data = await _readIndex();
    return (data['episodes'] as List<dynamic>)
        .map((item) => AcademyPodcastEntry.fromJson(
            item as Map<String, dynamic>)).toList(growable: false);
  }

  Future<AcademyPodcastEpisode> load( AcademyPodcastEntry entry) async {
    final path = entry.asset;
    if (path == null || !path.startsWith('assets/podcasts/')) {
      throw StateError('No transcript is available for this episode.');
    }
    final raw = await rootBundle.loadString(path);
    final episode = AcademyPodcastEpisode.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
    if (episode.id != entry.id || episode.level != entry.level ||
        episode.language != entry.language) {
      throw const FormatException('Podcast catalog metadata mismatch.');
    }
    return episode;
  }
}
