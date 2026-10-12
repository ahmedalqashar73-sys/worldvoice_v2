class RoomBackgroundCatalogItem {
  const RoomBackgroundCatalogItem({
    required this.id,
    required this.themeId,
    required this.name,
    required this.nameAr,
    required this.priceCoins,
    required this.isFree,
  });

  final String id;
  final String themeId;
  final String name;
  final String nameAr;
  final int priceCoins;
  final bool isFree;

  String localizedName(bool isArabic) => isArabic ? nameAr : name;
}

/// Only the original green canvas is free. All other room scenes require
/// verified ownership; the backend enforces the exact same eight theme IDs.
class RoomBackgroundCatalog {
  const RoomBackgroundCatalog._();

  static const items = <RoomBackgroundCatalogItem>[
    RoomBackgroundCatalogItem(
      id: 'background__softGreenFlow',
      themeId: 'softGreenFlow',
      name: 'WorldVoice Green',
      nameAr: 'الخلفية الخضراء الأصلية',
      priceCoins: 0,
      isFree: true,
    ),
    RoomBackgroundCatalogItem(
      id: 'background__wv_premium_01',
      themeId: 'wv_premium_01',
      name: 'Enchanted Forest',
      nameAr: 'الغابة الساحرة',
      priceCoins: 150,
      isFree: false,
    ),
    RoomBackgroundCatalogItem(
      id: 'background__wv_premium_02',
      themeId: 'wv_premium_02',
      name: 'Crystal Sound',
      nameAr: 'أمواج الصوت الكريستالية',
      priceCoins: 200,
      isFree: false,
    ),
    RoomBackgroundCatalogItem(
      id: 'background__wv_premium_03',
      themeId: 'wv_premium_03',
      name: 'Starlight Circle',
      nameAr: 'الدائرة النجمية',
      priceCoins: 250,
      isFree: false,
    ),
    RoomBackgroundCatalogItem(
      id: 'background__wv_premium_04',
      themeId: 'wv_premium_04',
      name: 'Riverside Mill',
      nameAr: 'طاحونة النهر',
      priceCoins: 180,
      isFree: false,
    ),
    RoomBackgroundCatalogItem(
      id: 'background__wv_premium_05',
      themeId: 'wv_premium_05',
      name: 'Waterfall Cottage',
      nameAr: 'كوخ الشلال',
      priceCoins: 220,
      isFree: false,
    ),
    RoomBackgroundCatalogItem(
      id: 'background__wv_premium_06',
      themeId: 'wv_premium_06',
      name: 'Moonlit Falls',
      nameAr: 'شلال ضوء القمر',
      priceCoins: 230,
      isFree: false,
    ),
    RoomBackgroundCatalogItem(
      id: 'background__wv_premium_07',
      themeId: 'wv_premium_07',
      name: 'Dream Clouds',
      nameAr: 'سحاب الأحلام',
      priceCoins: 120,
      isFree: false,
    ),
    RoomBackgroundCatalogItem(
      id: 'background__wv_premium_08',
      themeId: 'wv_premium_08',
      name: 'WorldVoice Music',
      nameAr: 'موسيقى وورلد فويس',
      priceCoins: 300,
      isFree: false,
    ),
  ];

  static RoomBackgroundCatalogItem? itemForTheme(String themeId) {
    for (final item in items) {
      if (item.themeId == themeId) return item;
    }
    return null;
  }

  /// Null for retired backgrounds: never display an old preview as a fallback.
  static String? assetPathForTheme(String themeId) {
    final item = itemForTheme(themeId);
    if (item == null || item.isFree) return null;
    return 'assets/backgrounds/$themeId.webp';
  }
}
