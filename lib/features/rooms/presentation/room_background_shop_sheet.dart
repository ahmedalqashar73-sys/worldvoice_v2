import '../../profile/presentation/member_badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/worldvoice_avatar_frame.dart';
import '../data/room_background_catalog.dart';
import '../data/room_shop_models.dart';
import '../data/room_feature_models.dart';
import '../services/room_feature_service.dart';
import '../services/room_shop_service.dart';
import 'room_background_atlas.dart';
import 'room_coin_store_sheet.dart';
import 'store_gift_options.dart';
import 'owner_direct_gift_sheet.dart';
import 'chat_bubble_shop_sheet.dart';
import '../services/room_coin_purchase_service.dart';

class RoomBackgroundShopSheet extends StatelessWidget {
  RoomBackgroundShopSheet({
    this.roomFeatures,
    this.isHost = false,
    this.onOpenWriting,
    super.key,
  });

  final RoomFeatureService? roomFeatures;
  final bool isHost;
  final VoidCallback? onOpenWriting;
  final RoomShopService _shop = RoomShopService();

  Future<void> _applyBackground(
    BuildContext context,
    RoomBackgroundCatalogItem item,
    bool isArabic, {
    bool adminGrant = false,
  }) async {
    if (roomFeatures == null) return;
    try {
      if (adminGrant && !item.isFree) await _shop.grantItem(item.id);
      await roomFeatures!.setPurchasedBackground(
        themeId: item.themeId,
        backgroundUrl: null,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'تم تطبيق الخلفية.' : 'Background applied.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تعذر تطبيق الخلفية: $error'
                : 'Could not apply background: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _shop.adminAccess,
    builder: (context, access) => _buildShop(context, access.data == true),
  );

  Future<void> _checkOwnerMonthlyCoins(
    BuildContext context, bool isArabic,
  ) async {
    try {
      final outcome = await _shop.refreshOwnerMonthlyCoins();
      if (!context.mounted) return;
      final credited = (outcome['creditedCoins'] as num?)?.toInt() ?? 0;
      final month = (outcome['ownerCoinMonth'] ?? '').toString();
      final message = credited > 0
          ? (isArabic
              ? 'أُضيف $credited كوينز إدارية إلى محفظتك لهذا الشهر ($month).'
              : 'Credited $credited admin coins for $month.')
          : (isArabic
              ? 'مكافأة $month مسجلة مسبقًا؛ لن تتكرر.'
              : 'Grant for $month was already credited.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))),
      );
    }
  }

  Future<void> _showReceivedGifts(BuildContext context, bool isArabic) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(isArabic ? 'الهدايا المستلمة' : 'Received gifts'),
        content: SizedBox(
          width: 360,
          height: 320,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users').doc(uid)
                .collection('gift_notifications')
                .orderBy('createdAt', descending: true)
                .limit(30).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text(isArabic
                    ? 'تعذر تحميل سجل الهدايا'
                    : 'Could not load gifts'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final gifts = snapshot.data!.docs;
              if (gifts.isEmpty) {
                return Center(child: Text(isArabic
                    ? 'لم تستلم أي هدايا حتى الآن'
                    : 'No received gifts yet'));
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: gifts.length,
                itemBuilder: (context, index) {
                  final data = gifts[index].data();
                  final isVisualGift = data['type'] == 'gift';
                  final days = data['durationDays'];
                  final durationLabel = days == null
                      ? (isArabic ? 'دائم' : 'Permanent')
                      : '$days ${isArabic ? 'أيام' : 'days'}';
                  final expires = data['expiresAt'];
                  final expired = expires is Timestamp &&
                      !expires.toDate().isAfter(DateTime.now());
                  final subtitle = isVisualGift
                      ? '${data['quantity'] ?? 1} × • ${data['priceCoins'] ?? 0} 🪙'
                      : '$durationLabel • ${expired
                          ? (isArabic ? 'انتهت الصلاحية' : 'Expired')
                          : (isArabic ? 'في مقتنياتك' : 'In your inventory')}';
                  final giftId = (data['itemId'] ?? '').toString();
                  final hasGiftArtwork = isVisualGift &&
                      RegExp(r'^wv_gift_[0-9]{3}$').hasMatch(giftId);
                  return ListTile(
                    leading: hasGiftArtwork
                        ? SizedBox(
                            width: 48,
                            height: 48,
                            child: Image.asset(
                              'assets/gifts/hd/$giftId.webp',
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.card_giftcard_rounded),
                            ),
                          )
                        : const Icon(Icons.card_giftcard_rounded),
                    title: Text((isArabic
                        ? (data['nameAr'] ?? data['name'] ?? data['itemId'] ?? '')
                        : (data['name'] ?? data['nameAr'] ?? data['itemId'] ?? '')
                      ).toString()),
                    subtitle: Text(subtitle),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog),
              child: Text(isArabic ? 'إغلاق' : 'Close')),
        ],
      ),
    );
  }

  Widget _buildShop(BuildContext context, bool isAdmin) {
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
                isArabic ? 'متجر المظهر' : 'Appearance Shop',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: user == null
                  ? null
                  : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: RoomCoinPurchaseService.instance.watchMyWallet(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError ||
                            snapshot.data?.exists != true) {
                          return Text(
                            isArabic
                                ? 'المحفظة غير جاهزة'
                                : 'Wallet unavailable',
                          );
                        }
                        final coins =
                            (snapshot.data?.data()?['coins'] as num?)
                                ?.toInt() ??
                            0;
                        final adminCoins =
                            (snapshot.data?.data()?['adminCoins'] as num?)
                                ?.toInt() ?? 0;
                        final purchasedCoins =
                            (coins - adminCoins).clamp(0, coins);
                        return Text(
                          adminCoins > 0
                              ? (isArabic
                                  ? 'الرصيد: $coins 🪙 • إدارية: $adminCoins • أخرى: $purchasedCoins'
                                  : 'Coins: $coins • Admin: $adminCoins • Other: $purchasedCoins')
                              : (isArabic
                                  ? 'رصيدك: $coins عملة'
                                  : 'Balance: $coins coins'),
                        );
                      },
                    ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: isArabic ? 'الهدايا المستلمة' : 'Received gifts',
                    onPressed: () => _showReceivedGifts(context, isArabic),
                    icon: const Icon(Icons.card_giftcard_rounded),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            if (isAdmin)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () => _checkOwnerMonthlyCoins(context, isArabic),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(isArabic
                        ? 'التحقق من مكافأة المالك 10,000 كوينز'
                        : 'Check 10,000 monthly owner coins'),
                  ),
                ),
              ),
            if (isAdmin)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const OwnerDirectGiftSheet(),
                    ),
                    icon: const Icon(Icons.card_giftcard_rounded),
                    label: Text(isArabic
                        ? 'إهداء هدية من الكتالوج لأي مستخدم'
                        : 'Send catalog gift to any user'),
                  ),
                ),
              ),
            // Three permanently visible cosmetic tabs in the existing shop.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: null,
                      icon: const Icon(Icons.wallpaper_rounded, size: 17),
                      label: Text(
                        isArabic ? 'الخلفيات' : 'Backgrounds',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (_) => _OtherStoreTab(
                          type: 'frame',
                          shop: _shop,
                          isArabic: isArabic,
                        ),
                      ),
                      icon: const Icon(Icons.crop_free_rounded, size: 17),
                      label: Text(
                        isArabic ? 'الإطارات' : 'Frames',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (_) => const WorldVoiceChatBubbleShopSheet(),
                      ),
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 17,
                      ),
                      label: Text(
                        isArabic ? 'الفقاعات' : 'Bubbles',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MemberBadgeShop()),
                ),
                icon: const Icon(Icons.workspace_premium),
                label: Text(
                  isArabic
                      ? 'شارات VIP ومستوى الهدايا'
                      : 'VIP badges & Gift level',
                ),
              ),
            ),
            if (onOpenWriting != null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onOpenWriting!();
                  },
                  icon: const Icon(Icons.text_fields_rounded, size: 16),
                  label: Text(
                    isArabic ? 'الكتابة والألوان' : 'Writing and colors',
                  ),
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
                  final owned =
                      ownedSnapshot.data ?? const <RoomBackgroundEntitlement>[];
                  final ownedByTheme = <String, RoomBackgroundEntitlement>{
                    for (final item in owned) item.themeId: item,
                  };

                  return StreamBuilder<RoomFeatureState>(
                    stream:
                        roomFeatures?.watchState() ??
                        const Stream<RoomFeatureState>.empty(),
                    builder: (context, roomSnapshot) {
                      final selectedTheme =
                          roomSnapshot.data?.themeId ?? 'softGreenFlow';
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
                              item.isFree || entitlement != null || isAdmin;

                          return _BackgroundCatalogCard(
                            item: item,
                            owned: ownedBackground,
                            selected: selectedTheme == item.themeId,
                            rewardAvailable: false,
                            isHost: isHost,
                            isArabic: isArabic,
                            onApply:
                                ownedBackground &&
                                    isHost &&
                                    roomFeatures != null
                                ? () => _applyBackground(
                                    context,
                                    item,
                                    isArabic,
                                    adminGrant: isAdmin,
                                  )
                                : null,
                            onBuy:
                                !item.isFree &&
                                    !ownedBackground &&
                                    _shop.isConfigured
                                ? () => _purchase(context, item, isArabic)
                                : null,
                            onClaim: null,
                            onGift: !item.isFree && _shop.isConfigured
                                ? () => _giftBackground(context, item, isArabic)
                                : null,
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
    BuildContext context, RoomBackgroundCatalogItem item, bool isArabic,
  ) async {
    try {
      final person = await pickStoreGiftRecipient(context, _shop, isArabic);
      if (person == null || !context.mounted) return;
      final days = await pickCosmeticGiftDuration(
        context, isArabic, item.priceCoins);
      if (days == null || !context.mounted) return;
      const percentages = <int, int>{3: 15, 7: 25, 10: 35,
        15: 45, 30: 60, 0: 100};
      final cost = ((item.priceCoins * percentages[days]! + 499) ~/ 500) * 5;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(isArabic ? 'تأكيد الإهداء' : 'Confirm gift'),
          content: Text('${item.localizedName(isArabic)}\n'
            '${person.displayName} • ${person.username.isEmpty ? person.uid : '@${person.username}'}\n'
            '${days == 0 ? (isArabic ? 'دائم' : 'Permanent') : '$days days'} • $cost 🪙\n'
            '${isArabic ? 'تصل مباشرة وتبدأ المدة عند التسليم.' : 'Delivered immediately. Time starts on delivery.'}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialog, false),
              child: Text(isArabic ? 'إلغاء' : 'Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialog, true),
              child: Text(isArabic ? 'إرسال' : 'Send')),
          ],
        ),
      );
      if (confirmed != true) return;
      await _shop.giftItem(
        itemId: item.id, recipientId: person.uid,
        durationDays: days == 0 ? null : days);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isArabic ? 'تم تسليم الخلفية' : 'Background delivered')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString())));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
                RepaintBoundary(
                  child: item.themeId == 'softGreenFlow'
                      ? const ColoredBox(color: Color(0xFF0D4A38))
                      : RoomBackgroundAtlas(
                          themeId: item.themeId,
                          filterQuality: FilterQuality.high,
                          fit: BoxFit.cover,
                        ),
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
                            ? (isArabic ? 'مجانية' : 'Free')
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
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
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
    this.photoUrl,
    this.onBuy,
    this.onGift,
  });

  final String? photoUrl;
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
              child: LayoutBuilder(
                builder: (context, constraints) => WorldVoiceAvatarFrame(
                  frameId: frameId,
                  size: (constraints.maxWidth * .86).clamp(
                    0.0,
                    constraints.maxHeight.clamp(0.0, 150.0),
                  ),
                  animate: false,
                  child: photoUrl?.isNotEmpty == true
                      ? Image.network(
                          photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.person_rounded, size: 54),
                        )
                      : const ColoredBox(
                          color: Color(0xFF183A32),
                          child: Center(
                            child: Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 54,
                            ),
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
            selected ? (isArabic ? 'مستخدم الآن' : 'Equipped') : subtitle,
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
                if (!isFree)
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
    required this.type,
    required this.shop,
    required this.isArabic,
  });
  final String type;
  final RoomShopService shop;
  final bool isArabic;

  Future<void> _pay(BuildContext context, RoomStoreItem item) async {
    try {
      await shop.purchaseItem(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isArabic ? 'تم الشراء' : 'Purchase complete')),
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      if (error.toString().contains('NOT_ENOUGH_COINS')) {
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => const RoomCoinStoreSheet(),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _gift(BuildContext context, RoomStoreItem item) async {
    try {
      final person = await pickStoreGiftRecipient(context, shop, isArabic);
      if (person == null || !context.mounted) return;
      int? duration;
      if (type == 'frame' || type == 'background') {
        duration = await pickCosmeticGiftDuration(
          context, isArabic, item.priceCoins);
        if (duration == null || !context.mounted) return;
      }
      const rates = <int, int>{3: 15, 7: 25, 10: 35,
        15: 45, 30: 60, 0: 100};
      final price = duration == null ? item.priceCoins :
          ((item.priceCoins * rates[duration]! + 499) ~/ 500) * 5;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(isArabic ? 'تأكيد الإهداء' : 'Confirm gift'),
          content: Text('${item.name}\n${person.displayName} '
              '(${person.username.isEmpty ? person.uid : '@${person.username}'})\n'
              '${duration == 0 ? (isArabic ? 'دائم' : 'Permanent') : duration == null ? '' : '$duration days'} • $price 🪙'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialog, false),
              child: Text(isArabic ? 'إلغاء' : 'Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialog, true),
              child: Text(isArabic ? 'إهداء' : 'Gift')),
          ],
        ),
      );
      if (confirmed != true) return;
      await shop.giftItem(itemId: item.id, recipientId: person.uid,
        durationDays: duration == 0 ? null : duration);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isArabic ? 'تم تسليم الإهداء' : 'Gift delivered')));
      }
    } catch (error) {
      if (!context.mounted) return;
      if (error.toString().contains('NOT_ENOUGH_COINS')) {
        await showModalBottomSheet<void>(
          context: context, isScrollControlled: true,
          builder: (_) => const RoomCoinStoreSheet());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: shop.adminAccess,
    builder: (context, access) =>
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseAuth.instance.currentUser == null
              ? null
              : FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .snapshots(),
          builder: (context, profile) => _buildStore(
            context,
            access.data == true,
            profile.data?.data()?['photoUrl'] as String? ??
                FirebaseAuth.instance.currentUser?.photoURL,
          ),
        ),
  );

  Widget _buildStore(BuildContext context, bool isAdmin, String? photoUrl) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: Column(
          children: [
            ListTile(
              title: Text(switch (type) {
                'frame' => isArabic ? 'الإطارات' : 'Frames',
                'entrance' => isArabic ? 'تأثيرات الدخول' : 'Entrance effects',
                _ => 'VIP',
              }),
              trailing: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<RoomStoreItem>>(
                stream: shop.watchStoreItems(type),
                builder: (context, snapshot) {
                  final items = snapshot.data ?? const <RoomStoreItem>[];
                  // Four free artwork frames plus 29 purchasable frames. Use live
                  // catalog metadata when available, and bundled previews otherwise.
                  final artFrames = WorldVoiceAvatarFrame.premiumArtworkFrameIds
                      .map(
                        (frameId) => items.firstWhere(
                          (item) => item.id == frameId,
                          orElse: () => RoomStoreItem(
                            id: frameId,
                            type: 'frame',
                            name: WorldVoiceAvatarFrame.label(
                              frameId,
                              ar: isArabic,
                            ),
                            priceCoins: WorldVoiceAvatarFrame.artworkPrice(
                              frameId,
                            ),
                            requiredGiftLevel: 0,
                            active: true,
                          ),
                        ),
                      )
                      .toList(growable: false);
                  // Preserve already-published legacy premium frames in addition
                  // to the 33 artwork choices; never hide a purchased frame.
                  final displayedFrames = <RoomStoreItem>[
                    ...artFrames,
                    ...items.where(
                      (item) => !WorldVoiceAvatarFrame.isArtworkFrame(item.id),
                    ),
                  ];
                  if (snapshot.hasError && type != 'frame') {
                    return Center(
                      child: Text(
                        isArabic ? 'تعذر تحميل المتجر' : 'Store unavailable',
                      ),
                    );
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
                            final freeFrames =
                                WorldVoiceAvatarFrame.freeFrameIds;
                            return GridView.builder(
                              padding: const EdgeInsets.all(10),
                              itemCount:
                                  freeFrames.length + displayedFrames.length,
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
                                    photoUrl: photoUrl,
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
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(error.toString()),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                }

                                final item =
                                    displayedFrames[index - freeFrames.length];
                                final isOwned =
                                    owned.contains(item.id) || isAdmin;
                                return _FrameStoreCard(
                                  photoUrl: photoUrl,
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
                                            if (isAdmin) {
                                              await shop.grantItem(item.id);
                                            }
                                            await shop.setProfileFrame(item.id);
                                          } catch (error) {
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
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
                    return Center(
                      child: Text(
                        isArabic ? 'لا توجد عناصر مفعلة' : 'No active items',
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: items.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: .68,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 10,
                        ),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final imageUrl = item.animationUrl?.trim() ?? '';
                      final isImage = RegExp(
                        r'\.(png|jpe?g|gif|webp)(\?|$)',
                        caseSensitive: false,
                      ).hasMatch(imageUrl);
                      return Card(
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: isImage
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.crop_free_rounded,
                                        size: 65,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.crop_free_rounded,
                                      size: 65,
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                '${item.priceCoins} coins • '
                                '${item.durationDays == null ? (isArabic ? 'دائم' : 'Permanent') : "${item.durationDays} days"}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(6, 3, 6, 8),
                              child: Wrap(
                                alignment: WrapAlignment.spaceEvenly,
                                spacing: 4,
                                children: [
                                  FilledButton(
                                    onPressed: shop.isConfigured
                                        ? () => _pay(context, item)
                                        : null,
                                    child: Text(isArabic ? 'شراء' : 'Buy'),
                                  ),
                                  OutlinedButton(
                                    onPressed: shop.isConfigured
                                        ? () => _gift(context, item)
                                        : null,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
