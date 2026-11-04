import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/models/story_library_models.dart';

/// Asset-only repository in phase 1. No Firebase or third-party requests.
///
/// Add story metadata to assets/stories/index.json and the matching JSON file
/// to the registered assets directory; no Dart source changes are needed.
class StoryLibraryRepository {
  StoryLibraryRepository({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  static const indexPath = 'assets/stories/index.json';

  Future<List<StoryLibraryEntry>> loadIndex() async {
    final raw = jsonDecode(await _bundle.loadString(indexPath));
    if (raw is! Map<String, dynamic> || raw['stories'] is! List) {
      throw const FormatException('Invalid stories index.');
    }
    final stories = <StoryLibraryEntry>[];
    final keys = <String>{};
    for (final value in raw['stories'] as List) {
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Story index entries must be objects.');
      }
      final entry = StoryLibraryEntry.fromJson(value);
      final key = entry.language + '/' + entry.level + '/' + entry.id;
      if (!keys.add(key)) {
        throw FormatException('Duplicate story: ' + key);
      }
      stories.add(entry);
    }
    return List<StoryLibraryEntry>.unmodifiable(stories);
  }

  Future<List<StoryLibraryEntry>> storiesFor({
    required String language,
    required String level,
  }) async {
    final all = await loadIndex();
    final code = language.trim().toLowerCase();
    final grade = level.trim().toUpperCase();
    return List<StoryLibraryEntry>.unmodifiable(
      all.where((entry) => entry.language == code && entry.level == grade),
    );
  }

  Future<StoryLibraryBook> loadStory(StoryLibraryEntry entry) async {
    final raw = jsonDecode(await _bundle.loadString(entry.asset));
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Story content must be an object.');
    }
    final story = StoryLibraryBook.fromJson(
      raw,
      language: entry.language,
      level: entry.level,
    );
    if (story.id != entry.id ||
        story.title != entry.title ||
        story.titleAr != entry.titleAr) {
      throw FormatException('Index and story metadata differ: ' + entry.id);
    }
    return story;
  }
}
