import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/data/classic_gift_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('new gift pack exposes exactly 54 high-quality atlas-backed designs',
      () async {
    final gifts = await ClassicGiftCatalog.load();
    expect(gifts, hasLength(54));
    expect(gifts.map((gift) => gift.id).toSet(), hasLength(54));
    expect(gifts.first.id, 'wv_gift_001');
    expect(gifts.last.id, 'wv_gift_054');
  });
}
