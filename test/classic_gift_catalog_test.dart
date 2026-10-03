import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/data/classic_gift_catalog.dart';
import 'package:worldvoice/features/rooms/data/room_feature_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('approved first tier has exactly 30 unique preview-only gifts', () async {
    final gifts = await ClassicGiftCatalog.load();
    expect(gifts, hasLength(30));
    expect(gifts.map((gift) => gift.id).toSet(), hasLength(30));
    expect(gifts.every((gift) =>
      !gift.active && gift.priceCoins >= 1 && gift.priceCoins <= 50 &&
      gift.nameAr?.isNotEmpty == true && gift.emoji?.isNotEmpty == true), isTrue);
    expect(gifts.first.priceCoins, 1);
    expect(gifts.last.id, 'classic_golden_phoenix');
    expect(gifts.last.priceCoins, 50);
    expect(gifts.singleWhere(
        (gift) => gift.id == 'classic_luminous_butterfly').priceCoins, 20);
  });

  test('local preview can never activate sending; server price wins', () async {
    final gifts = await ClassicGiftCatalog.load();
    final remote = RoomGiftCatalogItem(
      id: 'classic_luminous_butterfly',
      name: 'Published Butterfly',
      priceCoins: 21,
      active: true,
      previewUrl: 'https://example.com/approved-butterfly.png',
    );
    final merged = ClassicGiftCatalog.merge(
      previews: gifts, published: [remote]);
    expect(merged, hasLength(30));
    expect(merged.where((gift) => gift.active), hasLength(1));
    final published = merged.firstWhere(
      (gift) => gift.id == remote.id);
    expect(published.priceCoins, 21);
    expect(published.previewUrl, remote.previewUrl);
    expect(published.emoji, '🦋');
    expect(merged.first.active, isFalse);
  });

  test('published legacy gifts are retained while classics are added', () async {
    final gifts = await ClassicGiftCatalog.load();
    final extra = RoomGiftCatalogItem(
      id: 'legacy_gift',
      name: 'Legacy gift',
      priceCoins: 35,
      active: true,
    );
    final merged = ClassicGiftCatalog.merge(
      previews: gifts, published: [extra]);
    expect(merged, hasLength(31));
    expect(merged.last.id, extra.id);
  });
}
