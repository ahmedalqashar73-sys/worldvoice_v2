import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/data/classic_gift_catalog.dart';
import 'package:worldvoice/features/rooms/data/room_feature_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('WorldVoice catalog has exactly 104 unique preview-only gifts', () async {
    final gifts = await ClassicGiftCatalog.load();
    expect(gifts, hasLength(104));
    expect(gifts.map((gift) => gift.id).toSet(), hasLength(104));
    expect(
      gifts.every((gift) =>
          !gift.active &&
          gift.priceCoins >= 1 &&
          gift.priceCoins <= 5000 &&
          gift.nameAr?.isNotEmpty == true &&
          gift.emoji?.isNotEmpty == true),
      isTrue,
    );

    expect(gifts.where((g) => g.priceCoins <= 150), hasLength(50));
    expect(
      gifts.where((g) => g.priceCoins >= 151 && g.priceCoins <= 1000),
      hasLength(35),
    );
    expect(gifts.where((g) => g.priceCoins >= 1001), hasLength(19));
    expect(gifts.first.id, 'wv_gift_001');
    expect(gifts.first.priceCoins, 1);
    expect(gifts.last.id, 'wv_gift_104');
    expect(gifts.last.priceCoins, 5000);
  });

  test('server activation requires the exact approved price', () async {
    final gifts = await ClassicGiftCatalog.load();
    final preview = gifts.firstWhere((gift) => gift.id == 'wv_gift_010');

    final exactRemote = RoomGiftCatalogItem(
      id: preview.id,
      name: 'Published',
      priceCoins: preview.priceCoins,
      active: true,
      previewUrl: 'https://example.com/ignored.png',
    );
    final wrongPriceRemote = RoomGiftCatalogItem(
      id: 'wv_gift_011',
      name: 'Wrong price',
      priceCoins: 999,
      active: true,
    );

    final merged = ClassicGiftCatalog.merge(
      previews: gifts,
      published: [exactRemote, wrongPriceRemote, exactRemote],
    );

    expect(merged, hasLength(104));
    expect(merged.map((gift) => gift.id).toSet(), hasLength(104));
    expect(merged.where((gift) => gift.id == 'wv_gift_002'), hasLength(1));
    expect(merged.where((gift) => gift.id == 'wv_gift_026'), hasLength(1));
    expect(
      merged.firstWhere((gift) => gift.id == exactRemote.id).active,
      isTrue,
    );
    expect(
      merged.firstWhere((gift) => gift.id == wrongPriceRemote.id).active,
      isFalse,
    );
    expect(
      merged.firstWhere((gift) => gift.id == exactRemote.id).previewUrl,
      isNull,
    );
  });

  test('legacy Firestore gifts cannot reappear in the new store', () async {
    final gifts = await ClassicGiftCatalog.load();
    final legacy = RoomGiftCatalogItem(
      id: 'classic_old_gift',
      name: 'Old gift',
      priceCoins: 35,
      active: true,
    );

    final merged = ClassicGiftCatalog.merge(
      previews: gifts,
      published: [legacy],
    );

    expect(merged, hasLength(104));
    expect(merged.any((gift) => gift.id == legacy.id), isFalse);
  });
}
