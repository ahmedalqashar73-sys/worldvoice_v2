import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/room_shop_models.dart';
import '../services/room_feature_service.dart';
import '../services/room_shop_service.dart';

class RoomBackgroundShopSheet extends StatelessWidget {
  RoomBackgroundShopSheet({
    required this.roomFeatures,
    required this.isHost,
    super.key,
  });

  final RoomFeatureService roomFeatures;
  final bool isHost;
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
                isArabic ? 'متجر خلفيات الغرفة' : 'Room background store',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: user == null
                  ? null
                  : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
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
