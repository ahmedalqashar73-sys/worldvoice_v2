import 'dart:convert';
import 'package:flutter/services.dart';

/// Separate public-domain graded reading catalog; old teaching stories stay
/// out of the published library and are not touched by this repository.
class GradedStoryRepository {
  GradedStoryRepository({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;
  static const indexAsset = 'assets/stories/graded/index.json';
  static const levels = <String>['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  final AssetBundle _bundle;

  Future<List<GradedStoryEntry>> loadIndex() async {
    final json = jsonDecode(await _bundle.loadString(indexAsset));
    if (json is! Map<String, dynamic> ||
        json['version'] != 2 || json['entries'] is! List) {
      throw const FormatException('Invalid graded-stories catalog.');
    }
    final entries = <GradedStoryEntry>[];
    final ids = <String>{};
    for (final value in json['entries'] as List) {
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Invalid graded-stories entry.');
      }
      final item = GradedStoryEntry.fromJson(value);
      if (!ids.add(item.id)) throw const FormatException('Duplicate graded story.');
      entries.add(item);
    }
    return List<GradedStoryEntry>.unmodifiable(entries);
  }

  Future<GradedStoryBook> loadBook(GradedStoryEntry entry) async {
    final raw = jsonDecode(await _bundle.loadString(entry.asset));
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Invalid graded story book.');
    }
    final book = GradedStoryBook.fromJson(raw);
    if (entry.id != book.id || entry.title != book.title ||
        entry.titleAr != book.titleAr || entry.level != book.level ||
        entry.language != book.language ||
        entry.rightsStatus != book.rightsStatus) {
      throw const FormatException('Graded story index and book do not match.');
    }
    return book;
  }
}

String _required(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing graded story field: $key');
  }
  return value.trim();
}

void _trustedUrl(String url, Set<String> hosts) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https' ||
      !hosts.contains(uri.host) || uri.userInfo.isNotEmpty) {
    throw FormatException('Unapproved story source: $url');
  }
}

class GradedStoryEntry {
  const GradedStoryEntry({
    required this.id, required this.language, required this.level,
    required this.title, required this.titleAr, required this.asset,
    required this.status, required this.rightsStatus,
  });
  final String id, language, level, title, titleAr, asset, status, rightsStatus;

  factory GradedStoryEntry.fromJson(Map<String, dynamic> json) {
    final id = _required(json, 'id');
    final level = _required(json, 'level');
    final language = _required(json, 'language');
    final asset = _required(json, 'asset');
    final status = _required(json, 'status');
    if (!GradedStoryRepository.levels.contains(level) ||
        language != 'en' ||
        (status != 'preview' && status != 'published') ||
        json['format'] != 'public_domain_original' ||
        !asset.startsWith('assets/stories/graded/en/$level/') ||
        !asset.endsWith('.json') ||
        !RegExp(r'^[a-z0-9-]+$').hasMatch(id)) {
      throw const FormatException('Unapproved graded story index entry.');
    }
    return GradedStoryEntry(
      id: id, language: language, level: level,
      title: _required(json, 'title'),
      titleAr: _required(json, 'title_ar'), asset: asset,
      status: status, rightsStatus: _required(json, 'rights_status'));
  }
}

class GradedStoryChapter {
  const GradedStoryChapter({
    required this.number, required this.title, required this.durationSeconds,
    required this.audioUrl, required this.paragraphs,
  });
  final int number, durationSeconds;
  final String title, audioUrl;
  final List<String> paragraphs;

  factory GradedStoryChapter.fromJson(Map<String, dynamic> json) {
    final number = json['number'];
    final duration = json['duration_seconds'];
    final audio = _required(json, 'audio_url');
    _trustedUrl(audio, const {'archive.org', 'www.archive.org'});
    final raw = json['paragraphs'];
    if (number is! int || number < 1 ||
        duration is! int || duration < 30 ||
        raw is! List || raw.isEmpty ||
        raw.any((paragraph) => paragraph is! String ||
            (paragraph as String).trim().isEmpty)) {
      throw const FormatException('Incomplete graded story chapter.');
    }
    return GradedStoryChapter(
      number: number, title: _required(json, 'title'),
      durationSeconds: duration, audioUrl: audio,
      paragraphs: List<String>.unmodifiable(raw.cast<String>()));
  }
}

class GradedStoryBook {
  const GradedStoryBook({
    required this.id, required this.level, required this.language,
    required this.title, required this.titleAr, required this.author,
    required this.reader, required this.rightsStatus,
    required this.sourceTextUrl, required this.sourceAudioUrl,
    required this.chapters,
  });
  final String id, level, language, title, titleAr, author, reader;
  final String rightsStatus, sourceTextUrl, sourceAudioUrl;
  final List<GradedStoryChapter> chapters;

  factory GradedStoryBook.fromJson(Map<String, dynamic> json) {
    if (json['translation_status'] != 'on_demand_only' ||
        json['audio_sync_status'] != 'not_verified' ||
        json['cefr_status'] != 'worldvoice_editorial_provisional' ||
        json['rights_status'] !=
          'us_public_domain_international_review_pending') {
      throw const FormatException('Unverified graded story claims.');
    }
    final level = _required(json, 'level');
    if (!GradedStoryRepository.levels.contains(level) ||
        json['language'] != 'en') {
      throw const FormatException('Invalid graded story level.');
    }
    final textUrl = _required(json, 'source_text_url');
    final audioUrl = _required(json, 'source_audio_url');
    _trustedUrl(textUrl, const {'www.gutenberg.org', 'gutenberg.org'});
    _trustedUrl(audioUrl, const {'librivox.org', 'www.librivox.org'});
    final rawChapters = json['chapters'];
    if (rawChapters is! List || rawChapters.isEmpty) {
      throw const FormatException('Graded story needs chapters.');
    }
    final chapters = <GradedStoryChapter>[];
    for (final raw in rawChapters) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('Invalid chapter in graded story.');
      }
      final chapter = GradedStoryChapter.fromJson(raw);
      if (chapter.number != chapters.length + 1) {
        throw const FormatException('Invalid chapter numbering.');
      }
      chapters.add(chapter);
    }
    return GradedStoryBook(
      id: _required(json, 'id'), level: level,
      language: _required(json, 'language'),
      title: _required(json, 'title'), titleAr: _required(json, 'title_ar'),
      author: _required(json, 'author'), reader: _required(json, 'reader'),
      rightsStatus: _required(json, 'rights_status'),
      sourceTextUrl: textUrl, sourceAudioUrl: audioUrl,
      chapters: List<GradedStoryChapter>.unmodifiable(chapters));
  }
}
