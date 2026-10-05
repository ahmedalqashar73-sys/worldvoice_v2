import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/data/classic_gift_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all 30 classic gifts have individually bundled gradient SVG art', () async {
    final gifts = await ClassicGiftCatalog.load();
    expect(gifts, hasLength(30));
    for (final gift in gifts) {
      final image = await rootBundle.loadString(
          'assets/gifts/art/${gift.id}.svg');
      expect(image.contains('<svg '), isTrue, reason: gift.id);
      expect(image.contains('</svg>'), isTrue, reason: gift.id);
      expect(image.contains('Gradient'), isTrue, reason: gift.id);
    }
  });
}
