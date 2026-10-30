import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/live/presentation/live_audience_sheet.dart';

void main() {
  test('Live participant card uses the actual native and multiple learning languages', () {
    final languages = LiveAudienceLanguages.fromProfile({
      'nativeLanguageCode': 'ar',
      'learningLanguageCodes': ['en', 'es', 'fr', 'ko'],
    }, 'ar');

    expect(languages.native, 'العربية');
    expect(languages.learning, hasLength(4));
    expect(languages.learning, contains('الإنجليزية'));
    expect(languages.learning, contains('الإسبانية'));
  });

  test('Legacy profile language names are localized and duplicates collapsed', () {
    final languages = LiveAudienceLanguages.fromProfile({
      'nativeLanguage': 'Arabic',
      'learningLanguages': ['English', 'en', 'Spanish'],
    }, 'en');

    expect(languages.native, 'Arabic');
    expect(languages.learning, ['English', 'Spanish']);
  });

  test('Empty profile never invents native or learning languages', () {
    final languages = LiveAudienceLanguages.fromProfile({}, 'ar');
    expect(languages.native, isEmpty);
    expect(languages.learning, isEmpty);
  });

  test('Canonical learning-language codes take precedence over old names', () {
    final languages = LiveAudienceLanguages.fromProfile({
      'nativeLanguageCode': 'en',
      'learningLanguageCodes': ['ko', 'fr'],
      'learningLanguages': ['es'],
    }, 'en');
    expect(languages.native, 'English');
    expect(languages.learning, ['Korean', 'French']);
  });
}
