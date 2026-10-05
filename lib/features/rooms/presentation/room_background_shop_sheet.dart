import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/worldvoice_avatar_frame.dart';
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

                          const freeThemes = <String>[
                            'emerald',
                            'skyBlue',
                            'forestGold',
                            'midnight',
                            'royalPurple',
                            'skyAura',
                            'softGreenFlow',
                            'silverWaves',
                          ];

                          // Three polished animated backgrounds are always
                          // free. Paid backgrounds stay server-authoritative.
                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                            itemCount: freeThemes.length + catalog.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: .68,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 10,
                            ),
                            itemBuilder: (context, index) {
                              if (index < freeThemes.length) {
                                final themeId = freeThemes[index];
                                return _FreeBackgroundCard(
                                  themeId: themeId,
                                  isArabic: isArabic,
                                  isHost: isHost,
                                  onApply: () async {
                                    try {
                                      await roomFeatures.setTheme(themeId);
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
                                );
                              }

                              final item =
                                  catalog[index - freeThemes.length];
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
                                onClaim:
                                    reward != null && _shop.isConfigured
                                        ? () => _claim(
                                              context,
                                              reward,
                                              item,
                                              isArabic,
                                            )
                                        : null,
                                onApply: isOwned && isHost
                                    ? () =>
                                        roomFeatures.setPurchasedBackground(
                                          themeId: item.themeId,
                                          backgroundUrl:
                                              entitlement.backgroundUrl,
                                        )
                                    : null,
                                onGift: _shop.isConfigured
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
    RoomShopBackground item,
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
          content: Text('${item.name} • ${item.priceCoins} coins'),
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

class _FreeBackgroundCard extends StatelessWidget {
  const _FreeBackgroundCard({
    required this.themeId,
    required this.isArabic,
    required this.isHost,
    required this.onApply,
  });

  final String themeId;
  final bool isArabic;
  final bool isHost;
  final VoidCallback onApply;

  String get _label => switch (themeId) {
        'skyAura' => isArabic ? 'هالة سماوية' : 'Sky Blue Aura',
        'softGreenFlow' => isArabic ? 'تدفق أخضر' : 'Soft Green Flow',
        'silverWaves' => isArabic ? 'موج فضي' : 'Silver Light Waves',
        'royalEmeraldMotion' =>
          isArabic ? 'الزمرد الملكي' : 'Royal Emerald Motion',
        'goldenVipGlow' =>
          isArabic ? 'وهج ذهبي ملكي' : 'Royal Golden Glow',
        'auroraWorld' =>
          isArabic ? 'أورورا وورلد' : 'Aurora World',
        'crystalBlueLuxury' =>
          isArabic ? 'الكريستال الأزرق' : 'Crystal Blue Luxury',
        'velvetNight' =>
          isArabic ? 'ليلة مخملية' : 'Velvet Night',
        'galaxyTalk' =>
          isArabic ? 'مجرة وورلد فويس' : 'WorldVoice Galaxy',
        _ => isArabic ? 'خلفية مجانية' : 'Free Background',
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _BuiltInBackgroundPreview(themeId: themeId)),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 7, 8, 0),
            child: Text(
              _label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              isArabic ? 'مجانية • متحركة' : 'Free • Animated',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 7, 7, 9),
            child: FilledButton.tonal(
              onPressed: isHost ? onApply : null,
              child: Text(isArabic ? 'استخدام مجانًا' : 'Use free'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuiltInBackgroundPreview extends StatefulWidget {
  const _BuiltInBackgroundPreview({required this.themeId});

  final String themeId;

  static List<Color> colorsFor(String themeId) => switch (themeId) {
        'skyAura' => const [
            Color(0xFFEAF9FF),
            Color(0xFF86D8F6),
            Color(0xFF3E9FD1),
          ],
        'softGreenFlow' => const [
            Color(0xFFE7FFF4),
            Color(0xFF79DAB0),
            Color(0xFF17845F),
          ],
        'silverWaves' => const [
            Color(0xFFF7F9FA),
            Color(0xFFC9D3D8),
            Color(0xFF7D929E),
          ],
        'goldenVipGlow' => const [
            Color(0xFF3E2C08),
            Color(0xFFD6A929),
            Color(0xFFFFECA7),
          ],
        'royalEmeraldMotion' => const [
            Color(0xFF052D22),
            Color(0xFF0E8A60),
            Color(0xFF63E5B4),
          ],
        'auroraWorld' => const [
            Color(0xFF0A3558),
            Color(0xFF22C7B8),
            Color(0xFF9B7BFF),
          ],
        'galaxyTalk' => const [
            Color(0xFF111225),
            Color(0xFF4B3A8C),
            Color(0xFF1D8AA5),
          ],
        'crystalBlueLuxury' => const [
            Color(0xFF071D3B),
            Color(0xFF2A8DD8),
            Color(0xFFBCEEFF),
          ],
        'velvetNight' => const [
            Color(0xFF140C1D),
            Color(0xFF4A203F),
            Color(0xFF9B5B7F),
          ],
        _ => const [
            Color(0xFF0D4A38),
            Color(0xFF1D9270),
          ],
      };

  @override
  State<_BuiltInBackgroundPreview> createState() =>
      _BuiltInBackgroundPreviewState();
}

class _BuiltInBackgroundPreviewState extends State<_BuiltInBackgroundPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _BuiltInBackgroundPreview.colorsFor(widget.themeId);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + t * .7, -1),
              end: Alignment(1, .35 + t * .65),
              colors: colors,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Align(
                alignment: Alignment(-.75 + t * 1.4, -.45),
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .16),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 28,
                        spreadRadius: 8,
                        color: colors.last.withValues(alpha: .22),
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: Icon(
                  Icons.graphic_eq_rounded,
                  size: 46,
                  color: Colors.white.withValues(alpha: .78),
                ),
              ),
            ],
          ),
        );
      },
    );
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
    required this.onGift,
  });

  final RoomShopBackground item;
  final bool owned;
  final bool rewardAvailable;
  final bool isHost;
  final bool isArabic;
  final VoidCallback? onBuy;
  final VoidCallback? onClaim;
  final VoidCallback? onApply;
  final VoidCallback? onGift;

  @override
  Widget build(BuildContext context) {
    final previewUrl = item.previewUrl?.trim() ?? '';
    final subtitle = item.durationDays == null
        ? (isArabic ? 'دائم' : 'Permanent')
        : '${item.durationDays} ${isArabic ? 'يوم' : 'days'}';
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: previewUrl.isNotEmpty
                ? Image.network(
                    previewUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        _BuiltInBackgroundPreview(themeId: item.themeId),
                  )
                : _BuiltInBackgroundPreview(themeId: item.themeId),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 7, 8, 0),
            child: Text(item.name, maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              owned ? (isArabic ? 'مملوكة' : 'Owned')
                  : '${item.priceCoins} coins • $subtitle',
              textAlign: TextAlign.center,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 7, 6, 9),
            child: Wrap(
              alignment: WrapAlignment.spaceEvenly,
              runSpacing: 4,
              spacing: 4,
              children: [
                if (owned && isHost)
                  FilledButton.tonal(
                    onPressed: onApply,
                    child: Text(isArabic ? 'تطبيق' : 'Apply'),
                  )
                else if (!owned && rewardAvailable)
                  FilledButton.tonal(
                    onPressed: onClaim,
                    child: Text(isArabic ? 'مكافأة' : 'Reward'),
                  )
                else if (!owned)
                  FilledButton(
                    onPressed: onBuy,
                    child: Text(isArabic ? 'اشتري' : 'Buy'),
                  ),
                if (!owned)
                  OutlinedButton(
                    onPressed: onGift,
                    child: Text(isArabic ? 'إرسال' : 'Send'),
                  ),
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