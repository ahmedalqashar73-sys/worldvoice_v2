import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/room_shop_models.dart';
import '../data/room_feature_models.dart';
import '../services/room_feature_service.dart';
import '../services/room_shop_service.dart';
import 'room_coin_store_sheet.dart';
import '../services/room_coin_purchase_service.dart';

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
            StreamBuilder<RoomFeatureState>(
              stream: roomFeatures.watchState(),
              builder: (context, snapshot) {
                final selected = snapshot.data?.themeId ?? 'emerald';
                const palette = <(String, String, Color)>[
                  ('emerald', 'Emerald', Color(0xFF197A58)),
                  ('forestGold', 'Green & Gold', Color(0xFFA78C36)),
                  ('skyBlue', 'Sky Blue', Color(0xFF3295C0)),
                  ('midnight', 'Midnight', Color(0xFF273957)),
                ];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isArabic ? 'لون الغرفة (الهوست)' : 'Room color (host)',
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 7),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          for (final color in palette)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 7),
                              child: ChoiceChip(
                                avatar: CircleAvatar(
                                  radius: 9, backgroundColor: color.$3),
                                label: Text(switch (color.$1) {
                                  'emerald' => isArabic ? 'أخضر' : 'Green',
                                  'forestGold' => isArabic ? 'أخضر وذهبي' : 'Green & Gold',
                                  'skyBlue' => isArabic ? 'سماوي' : 'Sky Blue',
                                  _ => isArabic ? 'داكن' : 'Dark',
                                }),
                                selected: selected == color.$1,
                                onSelected: !isHost ? null : (_) async {
                                  try {
                                    await roomFeatures.setTheme(color.$1);
                                  } catch (error) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(error.toString())));
                                  }
                                },
                              ),
                            ),
                        ]),
                      ),
                    ],
                  ),
                );
              },
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
              child: StreamBuilder<List<RoomShopBackground>>(
                stream: _shop.watchBackgrounds(),
                builder: (context, catalogSnapshot) {
                  final catalog =
                      catalogSnapshot.data ?? const <RoomShopBackground>[];

                  return StreamBuilder<List<RoomBackgroundEntitlement>>(
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
                          final reward =
                              rewards.isEmpty ? null : rewards.first;

                          if (catalogSnapshot.connectionState ==
                                  ConnectionState.waiting &&
                              catalog.isEmpty) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (catalog.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  isArabic
                                      ? 'لا توجد خلفيات للبيع في الكتالوج حاليًا.'
                                      : 'No purchasable room backgrounds are configured yet.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: catalog.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = catalog[index];
                              final entitlement =
                                  ownedByTheme[item.themeId];
                              final isOwned = entitlement != null;

                              return _BackgroundStoreCard(
                                item: item,
                                owned: isOwned,
                                rewardAvailable: reward != null,
                                isHost: isHost,
                                isArabic: isArabic,
                                onBuy: _shop.isConfigured
                                    ? () => _purchase(
                                          context,
                                          item,
                                          isArabic,
                                        )
                                    : null,
                                onClaim: reward != null && _shop.isConfigured
                                    ? () => _claim(
                                          context,
                                          reward,
                                          item,
                                          isArabic,
                                        )
                                    : null,
                                onApply: isOwned && isHost
                                    ? () => roomFeatures.setPurchasedBackground(
                                          themeId: item.themeId,
                                          backgroundUrl:
                                              entitlement.backgroundUrl,
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

  Future<void> _purchase(
    BuildContext context,
    RoomShopBackground item,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _claim(
    BuildContext context,
    RoomBackgroundReward reward,
    RoomShopBackground item,
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

class _BackgroundStoreCard extends StatelessWidget {
  const _BackgroundStoreCard({
    required this.item,
    required this.owned,
    required this.rewardAvailable,
    required this.isHost,
    required this.isArabic,
    required this.onBuy,
    required this.onClaim,
    required this.onApply,
  });

  final RoomShopBackground item;
  final bool owned;
  final bool rewardAvailable;
  final bool isHost;
  final bool isArabic;
  final VoidCallback? onBuy;
  final VoidCallback? onClaim;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    final previewUrl = item.previewUrl?.trim() ?? '';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (previewUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 7,
              child: Image.network(
                previewUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _BackgroundPlaceholder(),
              ),
            )
          else
            const AspectRatio(
              aspectRatio: 16 / 7,
              child: _BackgroundPlaceholder(),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        owned
                            ? (isArabic ? 'مملوكة' : 'Owned')
                            : '${item.priceCoins} ${isArabic ? 'عملة' : 'coins'}',
                      ),
                    ],
                  ),
                ),
                if (owned && isHost)
                  FilledButton.tonal(
                    onPressed: onApply,
                    child: Text(isArabic ? 'تطبيق' : 'Apply'),
                  )
                else if (!owned && rewardAvailable)
                  FilledButton.tonal(
                    onPressed: onClaim,
                    child: Text(
                      isArabic ? 'مكافأة شهر' : '1-month reward',
                    ),
                  )
                else if (!owned)
                  FilledButton(
                    onPressed: onBuy,
                    child: Text(isArabic ? 'شراء' : 'Buy'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundPlaceholder extends StatelessWidget {
  const _BackgroundPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF30216E),
            Color(0xFF0D4A38),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.wallpaper_rounded,
          size: 42,
          color: Colors.white70,
        ),
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
            if (items.isEmpty) {
              return Center(child: Text(
                isArabic ? 'لا توجد عناصر مفعلة' : 'No active items',
              ));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(10),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final item = items[i];
                return Card(child: ListTile(
                  leading: Icon(switch (item.type) {
                    'frame' => Icons.crop_free_rounded,
                    'entrance' => Icons.auto_awesome_rounded,
                    _ => Icons.workspace_premium_rounded,
                  }),
                  title: Text(item.name),
                  subtitle: Text('${item.priceCoins} Coins • ${item.durationDays == null ? (isArabic ? 'دائم' : 'Permanent') : "${item.durationDays} days"}'),
                  trailing: Wrap(spacing: 4, children: [
                    if (type != 'vip') IconButton(
                      tooltip: isArabic ? 'شراء' : 'Buy',
                      onPressed: shop.isConfigured ? () => _pay(context, item) : null,
                      icon: const Icon(Icons.shopping_bag_outlined),
                    ),
                    IconButton(
                      tooltip: isArabic ? 'إهداء' : 'Gift',
                      onPressed: shop.isConfigured ? () => _gift(context, item) : null,
                      icon: const Icon(Icons.card_giftcard_outlined),
                    ),
                  ]),
                ));
              },
            );
          },
        )),
      ]),
    ));
  }
}
