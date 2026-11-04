import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/data/story_library_repository.dart';
import 'package:worldvoice/features/learn/domain/models/story_library_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads indexed English A1 story with all graded-reading content', () async {
    final repository = StoryLibraryRepository();
    final entries = await repository.storiesFor(language: 'EN', level: 'a1');
    expect(entries.length, greaterThanOrEqualTo(2));
    final legacy = entries.firstWhere((entry) => entry.id == 'the_small_green_bag');

    final book = await repository.loadStory(legacy);
    expect(book.language, 'en');
    expect(book.level, 'A1');
    expect(book.pages, hasLength(9));
    expect(book.vocabulary, hasLength(12));
    expect(book.questions, hasLength(5));
    expect(book.pages.first.script.first.speaker, StoryLibrarySpeaker.narrator);
    expect(
      book.pages.expand((page) => page.script).any(
        (line) => line.speaker == StoryLibrarySpeaker.male,
      ),
      isTrue,
    );
    expect(
      book.pages.expand((page) => page.script).any(
        (line) => line.speaker == StoryLibrarySpeaker.female,
      ),
      isTrue,
    );
    for (final question in book.questions) {
      expect(question.correctIndex, inInclusiveRange(0, question.options.length - 1));
    }
  });

  test('rejects invalid story page counts', () async {
    final repository = StoryLibraryRepository();
    final entry = (await repository.loadIndex())
        .firstWhere((item) => item.id == 'the_small_green_bag');
    final json = jsonDecode(await rootBundle.loadString(entry.asset))
        as Map<String, dynamic>;
    (json['pages'] as List).removeLast();
    (json['pages'] as List).removeLast();
    expect(
      () => StoryLibraryBook.fromJson(json, language: 'en', level: 'A1'),
      throwsFormatException,
    );
  });

  test('rejects unknown speaker labels', () {
    expect(
      () => StoryLibraryLine.fromJson({
        'speaker': 'ALIEN',
        'text': 'Hello!',
      }),
      throwsFormatException,
    );
  });
}
