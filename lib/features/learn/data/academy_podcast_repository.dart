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
  });

  final String speaker;
  final String text;
  final String translationAr;
  final int? startMs;
  final int? endMs;

  factory PodcastDialogueLine.fromJson(Map<String, dynamic> json) =>
      PodcastDialogueLine(
        speaker: json['speaker'] as String,
        text: json['text'] as String,
        translationAr: json['translation_ar'] as String,
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
    this.durationMs,
  });

  final String id;
  final String level;
  final String title;
  final String titleAr;
  final String status;
  final String? audioUrl;
  final int? durationMs;
  final List<PodcastDialogueLine> dialogue;
  final List<PodcastVocabulary> vocabulary;
  final List<PodcastQuestion> questions;

  /// "Published" requires a real five-minute audio URL and *measured* cues
  /// for every dialogue turn. Never synthesize timestamps from word counts.
  bool get isPlayable {
    if (status != 'published' || durationMs == null ||
        durationMs! < 285000 || durationMs! > 315000) {
      return false;
    }
    final uri = Uri.tryParse(audioUrl ?? '');
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty ||
        dialogue.isEmpty) {
      return false;
    }
    var previousEnd = 0;
    for (final line in dialogue) {
      final start = line.startMs;
      final end = line.endMs;
      if ((line.speaker != 'Anna' && line.speaker != 'Daniel') ||
          start == null || end == null ||
          start < previousEnd || end <= start || end > durationMs! ||
          line.text.trim().isEmpty || line.translationAr.trim().isEmpty) {
        return false;
      }
      previousEnd = end;
    }
    return dialogue.first.startMs! <= 5000 &&
        durationMs! - previousEnd <= 10000;
  }

  int? lineAt(Duration position) {
    if (!isPlayable) return null;
    final ms = position.inMilliseconds;
    for (var i = 0; i < dialogue.length; i++) {
      if (ms >= dialogue[i].startMs! && ms < dialogue[i].endMs!) return i;
    }
    return null;
  }

  factory AcademyPodcastEpisode.fromJson(Map<String, dynamic> json) =>
      AcademyPodcastEpisode(
        id: json['id'] as String,
        level: json['level'] as String,
        title: json['title'] as String,
        titleAr: json['title_ar'] as String,
        status: json['status'] as String,
        audioUrl: json['audio_url'] as String?,
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

  Future<List<PodcastLanguage>> allLanguages() async {
    final raw = await rootBundle.loadString('assets/podcasts/index.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return (data['languages'] as List<dynamic>)
        .map((item) => PodcastLanguage.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<AcademyPodcastEntry>> allEpisodes() async {
    final raw = await rootBundle.loadString('assets/podcasts/index.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
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
    if (episode.id != entry.id || episode.level != entry.level) {
      throw const FormatException('Podcast catalog metadata mismatch.');
    }
    return episode;
  }
}
