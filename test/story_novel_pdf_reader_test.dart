import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/presentation/story_novel_pdf_reader_screen.dart';

void main() {
  test('every original A1 novel has a stable PDF asset location', () {
    const titles = <String>[
      'the_blue_envelope',
      'the_empty_house',
      'the_last_train',
      'the_red_umbrella',
      'daniel_carter',
    ];
    for (final title in titles) {
      expect(
        novelPdfAssetPath(title),
        'assets/stories/en/A1/books/' + title + '.pdf',
      );
    }
    expect(() => novelPdfAssetPath('../dangerous'), throwsArgumentError);
  });
}
