import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/presentation/story_novel_pdf_reader_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const titles = <String>[
    'the_blue_envelope',
    'the_empty_house',
    'the_last_train',
    'the_red_umbrella',
    'daniel_carter',
  ];

  test('every original A1 novel has a stable PDF asset location', () {
    for (final title in titles) {
      expect(
        novelPdfAssetPath(title),
        'assets/stories/en/A1/books/' + title + '.pdf',
      );
    }
    expect(() => novelPdfAssetPath('../dangerous'), throwsArgumentError);
  });

  test('all five original PDF books are bundled and have valid headers',
      () async {
    for (final title in titles) {
      final data = await rootBundle.load(novelPdfAssetPath(title));
      expect(data.lengthInBytes, greaterThan(100000), reason: title);
      final prefix = data.buffer.asUint8List(data.offsetInBytes, 5);
      expect(String.fromCharCodes(prefix), '%PDF-', reason: title);
    }
  });
}
