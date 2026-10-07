import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/worldvoice_avatar_frame.dart';
import '../data/room_shop_models.dart';
import '../data/room_feature_models.dart';
import '../services/room_feature_service.dart';
import '../services/room_shop_service.dart';
import 'room_background_atlas.dart';
import 'room_coin_store_sheet.dart';
import '../services/room_coin_purchase_service.dart';

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
    RoomBackgroundCatalogItem(id:'background__wv_bg_06',themeId:'wv_bg_06',name:'Golden Coast',nameAr:'الساحل الذهبي',priceCoins:0,isFree:true),
    RoomBackgroundCatalogItem(id:'background__wv_bg_09',themeId:'wv_bg_09',name:'Garden Escape',nameAr:'ملاذ الحديقة',priceCoins:0,isFree:true),
    RoomBackgroundCatalogItem(id:'background__wv_bg_18',themeId:'wv_bg_18',name:'Sunset Terrace',nameAr:'شرفة الغروب',priceCoins:0,isFree:true),
    RoomBackgroundCatalogItem(id:'background__wv_bg_20',themeId:'wv_bg_20',name:'Alpine Serenity',nameAr:'هدوء الألب',priceCoins:0,isFree:true),
    RoomBackgroundCatalogItem(id:'background__wv_bg_33',themeId:'wv_bg_33',name:'Crystal Lagoon',nameAr:'البحيرة الكريستالية',priceCoins:0,isFree:true),
    RoomBackgroundCatalogItem(id:'background__wv_bg_01',themeId:'wv_bg_01',name:'Aurora Wolf',nameAr:'ذئب الشفق القطبي',priceCoins:260,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_02',themeId:'wv_bg_02',name:'Moonlit Castle',nameAr:'قلعة ضوء القمر',priceCoins:320,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_03',themeId:'wv_bg_03',name:'Celestial Falls',nameAr:'شلالات الفردوس',priceCoins:280,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_04',themeId:'wv_bg_04',name:'Sapphire Palace',nameAr:'قصر الياقوت',priceCoins:350,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_05',themeId:'wv_bg_05',name:'Golden Royal Hall',nameAr:'القاعة الملكية الذهبية',priceCoins:380,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_07',themeId:'wv_bg_07',name:'Midnight Venice',nameAr:'فينيسيا منتصف الليل',priceCoins:160,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_08',themeId:'wv_bg_08',name:'Neon Royal Drive',nameAr:'جولة النيون الملكية',priceCoins:260,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_10',themeId:'wv_bg_10',name:'Frozen Crystal Palace',nameAr:'قصر الكريستال المتجمد',priceCoins:360,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_11',themeId:'wv_bg_11',name:'Panda Paradise',nameAr:'جنة الباندا',priceCoins:220,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_12',themeId:'wv_bg_12',name:'Desert Oasis',nameAr:'واحة الغروب',priceCoins:180,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_13',themeId:'wv_bg_13',name:'Misty Dynasty',nameAr:'مملكة الضباب',priceCoins:200,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_14',themeId:'wv_bg_14',name:'Violet Moon Kingdom',nameAr:'مملكة القمر البنفسجي',priceCoins:300,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_15',themeId:'wv_bg_15',name:'Sakura Imperial',nameAr:'ساكورا الإمبراطورية',priceCoins:280,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_16',themeId:'wv_bg_16',name:'Royal Peacock Garden',nameAr:'حديقة الطاووس الملكية',priceCoins:320,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_17',themeId:'wv_bg_17',name:'Rose Cat Palace',nameAr:'قصر القطة والورود',priceCoins:240,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_19',themeId:'wv_bg_19',name:'Pharaoh Sunset',nameAr:'غروب الفراعنة',priceCoins:300,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_21',themeId:'wv_bg_21',name:'Tropical Royal Lounge',nameAr:'الواحة الملكية الاستوائية',priceCoins:240,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_22',themeId:'wv_bg_22',name:'Emerald Cave',nameAr:'كهف الزمرد',priceCoins:320,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_23',themeId:'wv_bg_23',name:'Parisian Twilight',nameAr:'شفق باريس',priceCoins:220,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_24',themeId:'wv_bg_24',name:'Starlight Palace',nameAr:'قصر ضوء النجوم',priceCoins:380,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_25',themeId:'wv_bg_25',name:'Alpine Royal Retreat',nameAr:'منتجع الألب الملكي',priceCoins:220,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_26',themeId:'wv_bg_26',name:'Panther Moon',nameAr:'فهد القمر',priceCoins:420,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_27',themeId:'wv_bg_27',name:'Atlantis Luxury Suite',nameAr:'جناح أتلانتس الفاخر',priceCoins:450,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_28',themeId:'wv_bg_28',name:'Stadium Glory',nameAr:'مجد الملعب',priceCoins:300,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_29',themeId:'wv_bg_29',name:'Number 10 Legend',nameAr:'أسطورة الرقم 10',priceCoins:340,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_30',themeId:'wv_bg_30',name:'Panda Falls',nameAr:'شلالات الباندا',priceCoins:280,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_31',themeId:'wv_bg_31',name:'Royal Lion Sunset',nameAr:'أسد الغروب الملكي',priceCoins:450,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_32',themeId:'wv_bg_32',name:'Tiger Falls',nameAr:'شلالات النمر',priceCoins:480,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_34',themeId:'wv_bg_34',name:'Mountain Mirror Retreat',nameAr:'ملاذ مرآة الجبل',priceCoins:240,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_35',themeId:'wv_bg_35',name:'Santorini Gold',nameAr:'سانتوريني الذهبية',priceCoins:260,isFree:false),
    RoomBackgroundCatalogItem(id:'background__wv_bg_36',themeId:'wv_bg_36',name:'Castle of Dawn',nameAr:'قلعة الفجر',priceCoins:340,isFree:false),
  ];
}

class RoomBackgroundShopSheet extends StatelessWidget {
  RoomBackgroundShopSheet({
    required this.roomFeatures,
    required this.isHost,
    this.onOpenWriting,
    super.key,
  });

  final RoomFeatureService roomFeatures;
  final bool isHost;
  final VoidCallback? onOpenWriting;
  final RoomShopService _shop = RoomShopService();

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .82,
        child: Column(
          children: [
            ListTile(
              title: Text(
                isArabic ? 'تصميم الغرفة: الخلفيات والإطارات' : 'Room look: backgrounds and frames',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: user == null
                  ? null
                  : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: RoomCoinPurchaseService.instance.watchMyWallet(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError || snapshot.data?.exists != true) {
                          return Text(isArabic
                              ? 'المحفظة غير جاهزة'
                              : 'Wallet unavailable');
                        }
                        final coins =
                            (snapshot.data?.data()?['coins'] as num?)
                                    ?.toInt() ??
                                0;
                        return Text(
                          isArabic
                              ? 'رصيدك: $coins عملة'
                              : 'Balance: $coins coins',
                        );
                      },
                    ),
              trailing: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            // Visual styling stays separate from the gift catalog.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 5,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.crop_free_rounded, size: 17),
                    label: Text(isArabic ? 'الإطارات' : 'Frames'),
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => _OtherStoreTab(
                        type: 'frame',
                        shop: _shop,
                        isArabic: isArabic,
                      ),
                    ),
                  ),
                  if (onOpenWriting != null)
                    ActionChip(
                      avatar: const Icon(Icons.text_fields_rounded, size: 17),
                      label: Text(isArabic ? 'الكتابة والألوان' : 'Writing and colors'),
                      onPressed: () {
                        Navigator.pop(context);
                        onOpenWriting!();
                      },
                    ),
                ],
              ),
            ),
            if (!_shop.isConfigured)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Material(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      isArabic
                          ? 'الكتالوج يظهر الآن، لكن الشراء يحتاج ربط WorldVoice Store Backend.'
                          : 'The catalog is visible, but purchases require the WorldVoice store backend.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: StreamBuilder<List<RoomBackgroundEntitlement>>(
                stream: _shop.watchOwnedBackgrounds(),
                builder: (context, ownedSnapshot) {
                  final owned = ownedSnapshot.data ??
                      const <RoomBackgroundEntitlement>[];
                  final ownedByTheme = <String, RoomBackgroundEntitlement>{
                    for (final item in owned) item.themeId: item,
                  };

                  return StreamBuilder<List<RoomBackgroundReward>>(
                    stream: _shop.watchBackgroundRewards(),
                    builder: (context, rewardSnapshot) {
                      final rewards = rewardSnapshot.data ??
                          const <RoomBackgroundReward>[];
                      final reward = rewards.isEmpty ? null : rewards.first;

                      return StreamBuilder<RoomFeatureState>(
                        stream: roomFeatures.watchState(),
                        builder: (context, roomSnapshot) {
                          final selectedTheme =
                              roomSnapshot.data?.themeId ?? 'wv_bg_06';
                          final backgrounds = RoomBackgroundCatalog.items;

                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                            itemCount: backgrounds.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: .62,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 10,
                            ),
                            itemBuilder: (context, index) {
                              final item = backgrounds[index];
                              final entitlement = ownedByTheme[item.themeId];
                              final ownedBackground =
                                  item.isFree || entitlement != null;

                              return _BackgroundCatalogCard(
                                item: item,
                                owned: ownedBackground,
                                selected: selectedTheme == item.themeId,
                                rewardAvailable:
                                    !item.isFree && reward != null,
                                isHost: isHost,
                                isArabic: isArabic,
                                onApply: ownedBackground && isHost
                                    ? () => roomFeatures.setPurchasedBackground(
                                          themeId: item.themeId,
                                          backgroundUrl: null,
                                        )
                                    : null,
                                onBuy: !item.isFree &&
                                        !ownedBackground &&
                                        _shop.isConfigured
                                    ? () => _purchase(
                                          context,
                                          item,
                                          isArabic,
                                        )
                                    : null,
                                onClaim: !item.isFree &&
                                        !ownedBackground &&
                                        reward != null &&
                                        _shop.isConfigured
                                    ? () => _claim(
                                          context,
                                          reward,
                                          item,
                                          isArabic,
                                        )
                                    : null,
                                onGift: !item.isFree && _shop.isConfigured
                                    ? () => _giftBackground(
                                          context,
                                          item,
                                          isArabic,
                                        )
                                    : null,
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _giftBackground(
    BuildContext context,
    RoomBackgroundCatalogItem item,
    bool isArabic,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final contacts = await FirebaseFirestore.instance
          .collection('users').doc(user.uid)
          .collection('following').get();
      if (!context.mounted) return;
      final recipient = await showDialog<String>(
        context: context,
        builder: (dialog) => SimpleDialog(
          title: Text(isArabic ? 'إهداء الخلفية لصديق' : 'Send background to a friend'),
          children: [
            if (contacts.docs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(isArabic ? 'لا يوجد أصدقاء بعد'
                    : 'No followed friends yet'),
              ),
            for (final contact in contacts.docs)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialog, contact.id),
                child: Text(contact.data()['displayName']?.toString()
                    ?? contact.id),
              ),
          ],
        ),
      );
      if (recipient == null || !context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(isArabic ? 'تأكيد الإهداء' : 'Confirm send'),
          content: Text('${item.localizedName(isArabic)} • ${item.priceCoins} coins'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialog, false),
              child: Text(isArabic ? 'إلغاء' : 'Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialog, true),
              child: Text(isArabic ? 'إرسال' : 'Send')),
          ],
        ),
      );
      if (confirmed != true) return;
      await _shop.giftItem(itemId: item.id, recipientId: recipient);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isArabic ? 'تم إرسال الخلفية'
              : 'Background sent')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  Future<void> _purchase(
    BuildContext context,
    RoomBackgroundCatalogItem item,
    bool isArabic,
  ) async {
    try {
      await _shop.purchaseBackground(item.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'تم شراء الخلفية.' : 'Background purchased.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      final message = error.toString();
      if (message.contains('NOT_ENOUGH_COINS')) {
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => const RoomCoinStoreSheet(),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _claim(
    BuildContext context,
    RoomBackgroundReward reward,
    RoomBackgroundCatalogItem item,
    bool isArabic,
  ) async {
    try {
      await _shop.claimReward(
        rewardId: reward.id,
        itemId: item.id,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تم استخدام مكافأة الخلفية المجانية لمدة شهر.'
                : 'Your one-month free background reward was claimed.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }
}

class _BackgroundCatalogCard extends StatelessWidget {
  const _BackgroundCatalogCard({
    required this.item,
    required this.owned,
    required this.selected,
    required this.rewardAvailable,
    required this.isHost,
    required this.isArabic,
    required this.onApply,
    required this.onBuy,
    required this.onClaim,
    required this.onGift,
  });

  final RoomBackgroundCatalogItem item;
  final bool owned;
  final bool selected;
  final bool rewardAvailable;
  final bool isHost;
  final bool isArabic;
  final VoidCallback? onApply;
  final VoidCallback? onBuy;
  final VoidCallback? onClaim;
  final VoidCallback? onGift;

  @override
  Widget build(BuildContext context) {
    final name = item.localizedName(isArabic);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                RoomBackgroundAtlas(
                  themeId: item.themeId,
                  filterQuality: FilterQuality.medium,
                ),
                PositionedDirectional(
                  top: 7,
                  start: 7,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: item.isFree
                          ? const Color(0xFF137D59)
                          : Colors.black.withValues(alpha: .68),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        item.isFree
                            ? (isArabic ? 'هدية مجانية' : 'Free gift')
                            : '${item.priceCoins} 🪙',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                if (selected)
                  PositionedDirectional(
                    top: 7,
                    end: 7,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1F9B6A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            selected
                ? (isArabic ? 'مستخدمة الآن' : 'In use')
                : item.isFree
                    ? (isArabic ? 'هدية البداية' : 'Starter gift')
                    : owned
                        ? (isArabic ? 'مملوكة' : 'Owned')
                        : (isArabic ? 'دائمة' : 'Permanent'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: owned
                      ? FilledButton.tonal(
                          onPressed: selected || !isHost ? null : onApply,
                          child: Text(
                            selected
                                ? (isArabic ? 'مستخدمة' : 'Applied')
                                : (isArabic ? 'استخدام' : 'Apply'),
                          ),
                        )
                      : FilledButton(
                          onPressed: onBuy,
                          child: Text(
                            isArabic
                                ? 'شراء ${item.priceCoins}'
                                : 'Buy ${item.priceCoins}',
                          ),
                        ),
                ),
                if (!owned && rewardAvailable) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onClaim,
                      child: Text(
                        isArabic ? 'استخدام مكافأة مجانية' : 'Use free reward',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ] else if (!item.isFree && !owned) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: onGift,
                      child: Text(isArabic ? 'إهداء لصديق' : 'Gift to friend'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FrameStoreCard extends StatelessWidget {
  const _FrameStoreCard({
    required this.frameId,
    required this.name,
    required this.isArabic,
    required this.isFree,
    required this.owned,
    required this.selected,
    required this.priceCoins,
    required this.durationDays,
    required this.onApply,
    this.onBuy,
    this.onGift,
  });

  final String frameId;
  final String name;
  final bool isArabic;
  final bool isFree;
  final bool owned;
  final bool selected;
  final int priceCoins;
  final int? durationDays;
  final VoidCallback? onApply;
  final VoidCallback? onBuy;
  final VoidCallback? onGift;

  @override
  Widget build(BuildContext context) {
    final subtitle = isFree
        ? (isArabic ? 'مجاني' : 'Free')
        : owned
            ? (isArabic ? 'مملوك' : 'Owned')
            : '$priceCoins coins • '
                '${durationDays == null ? (isArabic ? 'دائم' : 'Permanent') : '$durationDays ${isArabic ? 'يوم' : 'days'}'}';

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: WorldVoiceAvatarFrame(
                frameId: frameId,
                size: 92,
                child: const ColoredBox(
                  color: Color(0xFF183A32),
                  child: Center(
                    child: Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            selected
                ? (isArabic ? 'مستخدم الآن' : 'Equipped')
                : subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 7, 6, 9),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 5,
              runSpacing: 4,
              children: [
                if (owned)
                  FilledButton.tonal(
                    onPressed: selected ? null : onApply,
                    child: Text(
                      selected
                          ? (isArabic ? 'مستخدم' : 'Equipped')
                          : (isArabic ? 'استخدام' : 'Apply'),
                    ),
                  )
                else
                  FilledButton(
                    onPressed: onBuy,
                    child: Text(isArabic ? 'شراء' : 'Buy'),
                  ),
                if (!isFree && !owned)
                  OutlinedButton(
                    onPressed: onGift,
                    child: Text(isArabic ? 'إهداء' : 'Gift'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OtherStoreTab extends StatelessWidget {
  const _OtherStoreTab({
    required this.type, required this.shop, required this.isArabic,
  });
  final String type;
  final RoomShopService shop;
  final bool isArabic;

  Future<void> _pay(BuildContext context, RoomStoreItem item) async {
    try {
      await shop.purchaseItem(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isArabic ? 'تم الشراء' : 'Purchase complete'),
        ));
      }
    } catch (error) {
      if (!context.mounted) return;
      if (error.toString().contains('NOT_ENOUGH_COINS')) {
        await showModalBottomSheet<void>(
          context: context, isScrollControlled: true,
          builder: (_) => const RoomCoinStoreSheet(),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString()),
        ));
      }
    }
  }

  Future<void> _gift(BuildContext context, RoomStoreItem item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final contacts = await FirebaseFirestore.instance.collection('users')
        .doc(user.uid).collection('following').get();
    if (!context.mounted) return;
    final toId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(isArabic ? 'اختر صديقًا' : 'Choose a friend'),
        children: contacts.docs.isEmpty
          ? [Padding(padding: const EdgeInsets.all(18),
              child: Text(isArabic ? 'لا يوجد أصدقاء' : 'No friends found'))]
          : contacts.docs.map((contact) => SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, contact.id),
              child: Text(contact.data()['displayName']?.toString()
                  ?? contact.id),
            )).toList(),
      ),
    );
    if (toId == null || !context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isArabic ? 'تأكيد الإهداء' : 'Confirm gift'),
        content: Text('${item.name} • ${item.priceCoins} Coins'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isArabic ? 'إهداء' : 'Gift')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await shop.giftItem(itemId: item.id, recipientId: toId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isArabic ? 'تم إرسال الإهداء' : 'Gift delivered')),
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      if (error.toString().contains('NOT_ENOUGH_COINS')) {
        await showModalBottomSheet<void>(
          context: context, isScrollControlled: true,
          builder: (_) => const RoomCoinStoreSheet(),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .72,
      child: Column(children: [
        ListTile(title: Text(switch (type) {
          'frame' => isArabic ? 'الإطارات' : 'Frames',
          'entrance' => isArabic ? 'تأثيرات الدخول' : 'Entrance effects',
          _ => 'VIP',
        }), trailing: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        )),
        Expanded(child: StreamBuilder<List<RoomStoreItem>>(
          stream: shop.watchStoreItems(type),
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <RoomStoreItem>[];
            if (snapshot.hasError) {
              return Center(child: Text(
                isArabic ? 'تعذر تحميل المتجر' : 'Store unavailable',
              ));
            }
            if (type == 'frame') {
              return StreamBuilder<Set<String>>(
                stream: shop.watchOwnedItemIds('frame'),
                builder: (context, ownedSnapshot) {
                  final owned = ownedSnapshot.data ?? <String>{};
                  return StreamBuilder<String?>(
                    stream: shop.watchSelectedProfileFrame(),
                    builder: (context, selectedSnapshot) {
                      final selected = selectedSnapshot.data;
                      final freeFrames = WorldVoiceAvatarFrame.freeFrameIds;
                      return GridView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: freeFrames.length + items.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: .68,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 10,
                        ),
                        itemBuilder: (context, index) {
                          if (index < freeFrames.length) {
                            final frameId = freeFrames[index];
                            return _FrameStoreCard(
                              frameId: frameId,
                              name: WorldVoiceAvatarFrame.label(
                                frameId,
                                ar: isArabic,
                              ),
                              isArabic: isArabic,
                              isFree: true,
                              owned: true,
                              selected: selected == frameId,
                              priceCoins: 0,
                              durationDays: null,
                              onApply: () async {
                                try {
                                  await shop.setProfileFrame(frameId);
                                } catch (error) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(error.toString())),
                                  );
                                }
                              },
                            );
                          }

                          final item = items[index - freeFrames.length];
                          final isOwned = owned.contains(item.id);
                          return _FrameStoreCard(
                            frameId: item.id,
                            name: item.name,
                            isArabic: isArabic,
                            isFree: false,
                            owned: isOwned,
                            selected: selected == item.id,
                            priceCoins: item.priceCoins,
                            durationDays: item.durationDays,
                            onApply: !isOwned
                                ? null
                                : () async {
                                    try {
                                      await shop.setProfileFrame(item.id);
                                    } catch (error) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(error.toString()),
                                        ),
                                      );
                                    }
                                  },
                            onBuy: isOwned || !shop.isConfigured
                                ? null
                                : () => _pay(context, item),
                            onGift: !shop.isConfigured
                                ? null
                                : () => _gift(context, item),
                          );
                        },
                      );
                    },
                  );
                },
              );
            }
            if (items.isEmpty) {
              return Center(child: Text(
                isArabic ? 'لا توجد عناصر مفعلة' : 'No active items',
              ));
            }
            return GridView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: .68,
                mainAxisSpacing: 12,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                final imageUrl = item.animationUrl?.trim() ?? '';
                final isImage = RegExp(r'\.(png|jpe?g|gif|webp)(\?|$)',
                  caseSensitive: false).hasMatch(imageUrl);
                return Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: isImage ? Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.crop_free_rounded, size: 65),
                        ) : const Icon(Icons.crop_free_rounded, size: 65),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(item.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('${item.priceCoins} coins • '
                            '${item.durationDays == null ? (isArabic ? 'دائم' : 'Permanent') : "${item.durationDays} days"}',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 3, 6, 8),
                        child: Wrap(
                          alignment: WrapAlignment.spaceEvenly,
                          spacing: 4,
                          children: [
                            FilledButton(
                              onPressed: shop.isConfigured ?
                                  () => _pay(context, item) : null,
                              child: Text(isArabic ? 'شراء' : 'Buy'),
                            ),
                            OutlinedButton(
                              onPressed: shop.isConfigured ?
                                  () => _gift(context, item) : null,
                              child: Text(isArabic ? 'إرسال' : 'Send'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        )),
      ]),
    ));
  }
}