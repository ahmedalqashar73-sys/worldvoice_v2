import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/profile/data/profile_language_catalog.dart';

void main() {
  test('Live filters start with native, then All, then saved learning languages', () {
    final codes = ProfileLanguageCatalog.liveDiscoveryCodes({
      'nativeLanguageCode': 'ar',
      'learningLanguageCodes': ['en', 'es', 'fr', 'de'],
    });
    expect(codes, ['ar', 'all', 'en', 'es', 'fr', 'de']);
  });

  test('Live discovery does not cap a profile with twenty learning languages', () {
    const learning = [
      'en', 'es', 'fr', 'de', 'pt', 'zh', 'ja', 'ko', 'ru', 'tr',
      'ur', 'fa', 'id', 'th', 'it', 'hi', 'nl', 'sv', 'fi', 'pl',
    ];
    final codes = ProfileLanguageCatalog.liveDiscoveryCodes({
      'nativeLanguageCode': 'ar',
      'learningLanguageCodes': learning,
    });
    expect(codes.length, 22);
    expect(codes.first, 'ar');
    expect(codes[1], 'all');
    expect(codes.sublist(2), learning);
  });

  test('Live language discovery converts older stored names and removes duplicates', () {
    final codes = ProfileLanguageCatalog.liveDiscoveryCodes({
      'nativeLanguage': 'Arabic',
      'learningLanguages': ['English', 'Spanish', 'en', 'Arabic'],
    });
    expect(codes, ['ar', 'all', 'en', 'es']);
  });

  test('All stays available when no language profile exists', () {
    expect(ProfileLanguageCatalog.liveDiscoveryCodes({}), ['all']);
  });
}
