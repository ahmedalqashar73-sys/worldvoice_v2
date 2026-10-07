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

class RoomBackgroundCatalog {
  const RoomBackgroundCatalog._();

  static const items = <RoomBackgroundCatalogItem>[
    // Five starter gifts: immediately available to every WorldVoice user.
    RoomBackgroundCatalogItem(
      id: 'background__wv_bg_06',
      themeId: 'wv_bg_06',
      name: 'Golden Coast',
      nameAr: 'الساحل الذهبي',
      priceCoins: 0,
      isFree: true,
    ),
    RoomBackgroundCatalogItem(
      id: 'background__wv_bg_09',
      themeId: 'wv_bg_09',
      name: 'Garden Escape',
      nameAr: 'ملاذ الحديقة',
      priceCoins: 0,
      isFree: true,
    ),
    RoomBackgroundCatalogItem(
      id: 'background__wv_bg_18',
      themeId: 'wv_bg_18',
      name: 'Sunset Terrace',
      nameAr: 'شرفة الغروب',
      priceCoins: 0,
      isFree: true,
    ),
    RoomBackgroundCatalogItem(
      id: 'background__wv_bg_20',
      themeId: 'wv_bg_20',
      name: 'Alpine Serenity',
      nameAr: 'هدوء الألب',
      priceCoins: 0,
      isFree: true,
    ),
    RoomBackgroundCatalogItem(
      id: 'background__wv_bg_33',
      themeId: 'wv_bg_33',
      name: 'Crystal Lagoon',
      nameAr: 'البحيرة الكريستالية',
      priceCoins: 0,
      isFree: true,
    ),

    RoomBackgroundCatalogItem(id: 'background__wv_bg_01', themeId: 'wv_bg_01', name: 'Aurora Wolf', nameAr: 'ذئب الشفق القطبي', priceCoins: 260, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_02', themeId: 'wv_bg_02', name: 'Moonlit Castle', nameAr: 'قلعة ضوء القمر', priceCoins: 320, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_03', themeId: 'wv_bg_03', name: 'Celestial Falls', nameAr: 'شلالات الفردوس', priceCoins: 280, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_04', themeId: 'wv_bg_04', name: 'Sapphire Palace', nameAr: 'قصر الياقوت', priceCoins: 350, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_05', themeId: 'wv_bg_05', name: 'Golden Royal Hall', nameAr: 'القاعة الملكية الذهبية', priceCoins: 380, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_07', themeId: 'wv_bg_07', name: 'Midnight Venice', nameAr: 'فينيسيا منتصف الليل', priceCoins: 160, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_08', themeId: 'wv_bg_08', name: 'Neon Royal Drive', nameAr: 'جولة النيون الملكية', priceCoins: 260, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_10', themeId: 'wv_bg_10', name: 'Frozen Crystal Palace', nameAr: 'قصر الكريستال المتجمد', priceCoins: 360, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_11', themeId: 'wv_bg_11', name: 'Panda Paradise', nameAr: 'جنة الباندا', priceCoins: 220, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_12', themeId: 'wv_bg_12', name: 'Desert Oasis', nameAr: 'واحة الغروب', priceCoins: 180, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_13', themeId: 'wv_bg_13', name: 'Misty Dynasty', nameAr: 'مملكة الضباب', priceCoins: 200, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_14', themeId: 'wv_bg_14', name: 'Violet Moon Kingdom', nameAr: 'مملكة القمر البنفسجي', priceCoins: 300, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_15', themeId: 'wv_bg_15', name: 'Sakura Imperial', nameAr: 'ساكورا الإمبراطورية', priceCoins: 280, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_16', themeId: 'wv_bg_16', name: 'Royal Peacock Garden', nameAr: 'حديقة الطاووس الملكية', priceCoins: 320, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_17', themeId: 'wv_bg_17', name: 'Rose Cat Palace', nameAr: 'قصر القطة والورود', priceCoins: 240, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_19', themeId: 'wv_bg_19', name: 'Pharaoh Sunset', nameAr: 'غروب الفراعنة', priceCoins: 300, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_21', themeId: 'wv_bg_21', name: 'Tropical Royal Lounge', nameAr: 'الواحة الملكية الاستوائية', priceCoins: 240, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_22', themeId: 'wv_bg_22', name: 'Emerald Cave', nameAr: 'كهف الزمرد', priceCoins: 320, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_23', themeId: 'wv_bg_23', name: 'Parisian Twilight', nameAr: 'شفق باريس', priceCoins: 220, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_24', themeId: 'wv_bg_24', name: 'Starlight Palace', nameAr: 'قصر ضوء النجوم', priceCoins: 380, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_25', themeId: 'wv_bg_25', name: 'Alpine Royal Retreat', nameAr: 'منتجع الألب الملكي', priceCoins: 220, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_26', themeId: 'wv_bg_26', name: 'Panther Moon', nameAr: 'فهد القمر', priceCoins: 420, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_27', themeId: 'wv_bg_27', name: 'Atlantis Luxury Suite', nameAr: 'جناح أتلانتس الفاخر', priceCoins: 450, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_28', themeId: 'wv_bg_28', name: 'Stadium Glory', nameAr: 'مجد الملعب', priceCoins: 300, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_29', themeId: 'wv_bg_29', name: 'Number 10 Legend', nameAr: 'أسطورة الرقم 10', priceCoins: 340, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_30', themeId: 'wv_bg_30', name: 'Panda Falls', nameAr: 'شلالات الباندا', priceCoins: 280, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_31', themeId: 'wv_bg_31', name: 'Royal Lion Sunset', nameAr: 'أسد الغروب الملكي', priceCoins: 450, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_32', themeId: 'wv_bg_32', name: 'Tiger Falls', nameAr: 'شلالات النمر', priceCoins: 480, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_34', themeId: 'wv_bg_34', name: 'Mountain Mirror Retreat', nameAr: 'ملاذ مرآة الجبل', priceCoins: 240, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_35', themeId: 'wv_bg_35', name: 'Santorini Gold', nameAr: 'سانتوريني الذهبية', priceCoins: 260, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_36', themeId: 'wv_bg_36', name: 'Castle of Dawn', nameAr: 'قلعة الفجر', priceCoins: 340, isFree: false),
  ];

  static const int atlasColumns = 6;
  static const int atlasRows = 6;

  static int? atlasIndexForTheme(String themeId) {
    final match = RegExp(r'^wv_bg_(\d{2})$').firstMatch(themeId);
    if (match == null) return null;
    final value = int.tryParse(match.group(1) ?? '');
    if (value == null || value < 1 || value > 36) return null;
    return value - 1;
  }
  static RoomBackgroundCatalogItem? itemForTheme(String themeId) {
    for (final item in items) {
      if (item.themeId == themeId) return item;
    }
    return null;
  }
}
