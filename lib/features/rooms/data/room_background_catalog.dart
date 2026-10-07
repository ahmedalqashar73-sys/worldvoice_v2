class RoomBackgroundCatalogItem {
  const RoomBackgroundCatalogItem({
    required this.id,
    required this.themeId,
    required this.name,
    required this.nameAr,
    required this.assetPath,
    required this.priceCoins,
    required this.isFree,
  });

  final String id;
  final String themeId;
  final String name;
  final String nameAr;
  final String assetPath;
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
      assetPath: 'assets/backgrounds/wv_bg_06.webp',
      priceCoins: 0,
      isFree: true,
    ),
    RoomBackgroundCatalogItem(
      id: 'background__wv_bg_09',
      themeId: 'wv_bg_09',
      name: 'Garden Escape',
      nameAr: 'ملاذ الحديقة',
      assetPath: 'assets/backgrounds/wv_bg_09.webp',
      priceCoins: 0,
      isFree: true,
    ),
    RoomBackgroundCatalogItem(
      id: 'background__wv_bg_18',
      themeId: 'wv_bg_18',
      name: 'Sunset Terrace',
      nameAr: 'شرفة الغروب',
      assetPath: 'assets/backgrounds/wv_bg_18.webp',
      priceCoins: 0,
      isFree: true,
    ),
    RoomBackgroundCatalogItem(
      id: 'background__wv_bg_20',
      themeId: 'wv_bg_20',
      name: 'Alpine Serenity',
      nameAr: 'هدوء الألب',
      assetPath: 'assets/backgrounds/wv_bg_20.webp',
      priceCoins: 0,
      isFree: true,
    ),
    RoomBackgroundCatalogItem(
      id: 'background__wv_bg_33',
      themeId: 'wv_bg_33',
      name: 'Crystal Lagoon',
      nameAr: 'البحيرة الكريستالية',
      assetPath: 'assets/backgrounds/wv_bg_33.webp',
      priceCoins: 0,
      isFree: true,
    ),

    RoomBackgroundCatalogItem(id: 'background__wv_bg_01', themeId: 'wv_bg_01', name: 'Aurora Wolf', nameAr: 'ذئب الشفق القطبي', assetPath: 'assets/backgrounds/wv_bg_01.webp', priceCoins: 260, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_02', themeId: 'wv_bg_02', name: 'Moonlit Castle', nameAr: 'قلعة ضوء القمر', assetPath: 'assets/backgrounds/wv_bg_02.webp', priceCoins: 320, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_03', themeId: 'wv_bg_03', name: 'Celestial Falls', nameAr: 'شلالات الفردوس', assetPath: 'assets/backgrounds/wv_bg_03.webp', priceCoins: 280, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_04', themeId: 'wv_bg_04', name: 'Sapphire Palace', nameAr: 'قصر الياقوت', assetPath: 'assets/backgrounds/wv_bg_04.webp', priceCoins: 350, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_05', themeId: 'wv_bg_05', name: 'Golden Royal Hall', nameAr: 'القاعة الملكية الذهبية', assetPath: 'assets/backgrounds/wv_bg_05.webp', priceCoins: 380, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_07', themeId: 'wv_bg_07', name: 'Midnight Venice', nameAr: 'فينيسيا منتصف الليل', assetPath: 'assets/backgrounds/wv_bg_07.webp', priceCoins: 160, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_08', themeId: 'wv_bg_08', name: 'Neon Royal Drive', nameAr: 'جولة النيون الملكية', assetPath: 'assets/backgrounds/wv_bg_08.webp', priceCoins: 260, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_10', themeId: 'wv_bg_10', name: 'Frozen Crystal Palace', nameAr: 'قصر الكريستال المتجمد', assetPath: 'assets/backgrounds/wv_bg_10.webp', priceCoins: 360, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_11', themeId: 'wv_bg_11', name: 'Panda Paradise', nameAr: 'جنة الباندا', assetPath: 'assets/backgrounds/wv_bg_11.webp', priceCoins: 220, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_12', themeId: 'wv_bg_12', name: 'Desert Oasis', nameAr: 'واحة الغروب', assetPath: 'assets/backgrounds/wv_bg_12.webp', priceCoins: 180, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_13', themeId: 'wv_bg_13', name: 'Misty Dynasty', nameAr: 'مملكة الضباب', assetPath: 'assets/backgrounds/wv_bg_13.webp', priceCoins: 200, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_14', themeId: 'wv_bg_14', name: 'Violet Moon Kingdom', nameAr: 'مملكة القمر البنفسجي', assetPath: 'assets/backgrounds/wv_bg_14.webp', priceCoins: 300, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_15', themeId: 'wv_bg_15', name: 'Sakura Imperial', nameAr: 'ساكورا الإمبراطورية', assetPath: 'assets/backgrounds/wv_bg_15.webp', priceCoins: 280, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_16', themeId: 'wv_bg_16', name: 'Royal Peacock Garden', nameAr: 'حديقة الطاووس الملكية', assetPath: 'assets/backgrounds/wv_bg_16.webp', priceCoins: 320, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_17', themeId: 'wv_bg_17', name: 'Rose Cat Palace', nameAr: 'قصر القطة والورود', assetPath: 'assets/backgrounds/wv_bg_17.webp', priceCoins: 240, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_19', themeId: 'wv_bg_19', name: 'Pharaoh Sunset', nameAr: 'غروب الفراعنة', assetPath: 'assets/backgrounds/wv_bg_19.webp', priceCoins: 300, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_21', themeId: 'wv_bg_21', name: 'Tropical Royal Lounge', nameAr: 'الواحة الملكية الاستوائية', assetPath: 'assets/backgrounds/wv_bg_21.webp', priceCoins: 240, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_22', themeId: 'wv_bg_22', name: 'Emerald Cave', nameAr: 'كهف الزمرد', assetPath: 'assets/backgrounds/wv_bg_22.webp', priceCoins: 320, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_23', themeId: 'wv_bg_23', name: 'Parisian Twilight', nameAr: 'شفق باريس', assetPath: 'assets/backgrounds/wv_bg_23.webp', priceCoins: 220, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_24', themeId: 'wv_bg_24', name: 'Starlight Palace', nameAr: 'قصر ضوء النجوم', assetPath: 'assets/backgrounds/wv_bg_24.webp', priceCoins: 380, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_25', themeId: 'wv_bg_25', name: 'Alpine Royal Retreat', nameAr: 'منتجع الألب الملكي', assetPath: 'assets/backgrounds/wv_bg_25.webp', priceCoins: 220, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_26', themeId: 'wv_bg_26', name: 'Panther Moon', nameAr: 'فهد القمر', assetPath: 'assets/backgrounds/wv_bg_26.webp', priceCoins: 420, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_27', themeId: 'wv_bg_27', name: 'Atlantis Luxury Suite', nameAr: 'جناح أتلانتس الفاخر', assetPath: 'assets/backgrounds/wv_bg_27.webp', priceCoins: 450, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_28', themeId: 'wv_bg_28', name: 'Stadium Glory', nameAr: 'مجد الملعب', assetPath: 'assets/backgrounds/wv_bg_28.webp', priceCoins: 300, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_29', themeId: 'wv_bg_29', name: 'Number 10 Legend', nameAr: 'أسطورة الرقم 10', assetPath: 'assets/backgrounds/wv_bg_29.webp', priceCoins: 340, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_30', themeId: 'wv_bg_30', name: 'Panda Falls', nameAr: 'شلالات الباندا', assetPath: 'assets/backgrounds/wv_bg_30.webp', priceCoins: 280, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_31', themeId: 'wv_bg_31', name: 'Royal Lion Sunset', nameAr: 'أسد الغروب الملكي', assetPath: 'assets/backgrounds/wv_bg_31.webp', priceCoins: 450, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_32', themeId: 'wv_bg_32', name: 'Tiger Falls', nameAr: 'شلالات النمر', assetPath: 'assets/backgrounds/wv_bg_32.webp', priceCoins: 480, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_34', themeId: 'wv_bg_34', name: 'Mountain Mirror Retreat', nameAr: 'ملاذ مرآة الجبل', assetPath: 'assets/backgrounds/wv_bg_34.webp', priceCoins: 240, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_35', themeId: 'wv_bg_35', name: 'Santorini Gold', nameAr: 'سانتوريني الذهبية', assetPath: 'assets/backgrounds/wv_bg_35.webp', priceCoins: 260, isFree: false),
    RoomBackgroundCatalogItem(id: 'background__wv_bg_36', themeId: 'wv_bg_36', name: 'Castle of Dawn', nameAr: 'قلعة الفجر', assetPath: 'assets/backgrounds/wv_bg_36.webp', priceCoins: 340, isFree: false),
  ];

  static String? assetForTheme(String themeId) {
    for (final item in items) {
      if (item.themeId == themeId) return item.assetPath;
    }
    return null;
  }
}
