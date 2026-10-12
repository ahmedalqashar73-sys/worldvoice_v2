import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/data/room_background_catalog.dart';

void main() {
  test('original green is the only free room background', () {
    final items = RoomBackgroundCatalog.items;
    expect(items.length, 9);
    expect(items.first.themeId, 'softGreenFlow');
    expect(items.first.isFree, isTrue);
    expect(items.first.priceCoins, 0);

    final paid = items.skip(1).toList(growable: false);
    expect(paid.length, 8);
    expect(paid.every((background) => !background.isFree), isTrue);
    expect(paid.every((background) => background.priceCoins > 0), isTrue);
    expect(
      paid.map((background) => background.themeId).toSet().length,
      paid.length,
    );
    for (var index = 1; index <= 8; index++) {
      final themeId = 'wv_premium_${index.toString().padLeft(2, '0')}';
      expect(RoomBackgroundCatalog.itemForTheme(themeId), isNotNull);
      expect(
        RoomBackgroundCatalog.assetPathForTheme(themeId),
        'assets/backgrounds/$themeId.webp',
      );
    }
  });

  test('legacy backgrounds cannot be selected in the new catalog', () {
    expect(RoomBackgroundCatalog.itemForTheme('wv_bg_18'), isNull);
    expect(RoomBackgroundCatalog.assetPathForTheme('wv_bg_18'), isNull);
    expect(RoomBackgroundCatalog.assetPathForTheme('softGreenFlow'), isNull);
  });
}
