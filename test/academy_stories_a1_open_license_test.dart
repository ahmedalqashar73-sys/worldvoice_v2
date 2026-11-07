import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/data/graded_story_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('A1 catalog has five complete attributed CC BY 3.0 stories', () async {
    final repository = GradedStoryRepository();
    final index = await repository.loadIndex();
    final a1 = index.where((entry) => entry.level == 'A1').toList();
    expect(a1, hasLength(5));
    expect(a1.map((entry) => entry.id).toSet(), hasLength(5));
    expect(a1.every((entry) => entry.rightsStatus == 'cc_by_3_0'), isTrue);
    for (final entry in a1) {
      final book = await repository.loadBook(entry);
      expect(book.level, 'A1');
      expect(book.language, 'en');
      expect(book.rightsStatus, 'cc_by_3_0');
      expect(book.licenseUrl, 'https://creativecommons.org/licenses/by/3.0/');
      expect(book.author.trim(), isNotEmpty);
      expect(book.illustrator?.trim(), isNotEmpty);
      expect(book.reader, 'Darshan Soni');
      expect(book.sourceTextUrl,
          'https://www.storybookscanada.ca/stories/en/${entry.id.substring(5)}/');
      expect(book.chapters, hasLength(1));
      final chapter = book.chapters.single;
      expect(chapter.number, 1);
      expect(chapter.paragraphs.length, inInclusiveRange(5, 8));
      expect(chapter.imageUrls, hasLength(chapter.paragraphs.length));
      expect(chapter.audioUrl,
          startsWith('https://www.storybookscanada.ca/audio/'));
      for (final line in chapter.paragraphs) {
        expect(line.trim(), isNotEmpty);
      }
      expect(chapter.durationSeconds, 0,
          reason: 'Do not fabricate audio duration before verifying the MP3.');
    }
  });

  test('rejects noncommercial or unknown publisher rights', () async {
    final rawIndex = jsonDecode(
        await rootBundle.loadString(GradedStoryRepository.indexAsset))
        as Map<String, dynamic>;
    final a1 = (rawIndex['entries'] as List).firstWhere(
      (item) => item['level'] == 'A1') as Map<String, dynamic>;
    final invalid = Map<String, dynamic>.from(a1);
    invalid['rights_status'] = 'cc_by_nc_3_0';
    expect(() => GradedStoryEntry.fromJson(invalid), throwsFormatException);
    invalid['rights_status'] = 'cc_by_3_0';
    invalid['asset'] = 'assets/stories/graded/en/B1/invalid.json';
    expect(() => GradedStoryEntry.fromJson(invalid), throwsFormatException);
  });

  test('rejects unlicensed sound and unexpected image hosts', () async {
    final repository = GradedStoryRepository();
    final item = (await repository.loadIndex()).firstWhere(
      (entry) => entry.id == 'ccby-0087');
    final raw = jsonDecode(await rootBundle.loadString(item.asset))
        as Map<String, dynamic>;
    final chapter = (raw['chapters'] as List).single as Map<String, dynamic>;
    final badAudio = Map<String, dynamic>.from(chapter);
    badAudio['audio_url'] = 'https://untrusted.example.com/audio.mp3';
    expect(() => GradedStoryChapter.fromJson(badAudio),
        throwsFormatException);
    final badImages = Map<String, dynamic>.from(chapter);
    badImages['image_urls'] = ['https://untrusted.example.com/image.jpg'];
    expect(() => GradedStoryChapter.fromJson(badImages),
        throwsFormatException);
  });

  test('does not change separate C1 classic preview', () async {
    final repo = GradedStoryRepository();
    final index = await repo.loadIndex();
    final c1 = index.where((entry) => entry.level == 'C1').toList();
    expect(c1, hasLength(1));
    expect(c1.single.id, 'pd-jekyll-hyde');
    expect(c1.single.rightsStatus,
        'us_public_domain_international_review_pending');
  });
}
