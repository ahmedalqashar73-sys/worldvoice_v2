import 'room_feature_models.dart';

/// Local TEST catalog for user-owned GLB models. These previews never authorize
/// a paid send; production prices remain backend-owned.
abstract final class LuxuryGiftCatalog {
  static const items = <RoomGiftCatalogItem>[
    RoomGiftCatalogItem(
      id: 'luxury_golden_muse',
      name: 'Golden Muse',
      nameAr: 'الملهمة الذهبية',
      priceCoins: 1000,
      active: false,
      category: 'luxury',
      emoji: '✨',
      effectType: 'royal_3d',
    ),
    RoomGiftCatalogItem(
      id: 'luxury_royal_clockwork_owl',
      name: 'Royal Clockwork Owl',
      nameAr: 'بومة الزمن الملكية',
      priceCoins: 1500,
      active: false,
      category: 'luxury',
      emoji: '🦉',
      effectType: 'royal_3d',
    ),
  ];

  static String? assetFor(String giftId) => switch (giftId) {
    'luxury_golden_muse' => 'assets/gifts/models/golden_muse.glb',
    'luxury_royal_clockwork_owl' =>
      'assets/gifts/models/royal_clockwork_owl.glb',
    _ => null,
  };
}
