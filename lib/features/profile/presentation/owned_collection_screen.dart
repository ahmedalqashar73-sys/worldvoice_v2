import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/worldvoice_avatar_frame.dart';
import '../../rooms/data/chat_bubble_catalog.dart';
import '../../rooms/data/room_background_catalog.dart';
import '../../rooms/presentation/chat_bubble_frame.dart';
import '../../rooms/presentation/room_background_atlas.dart';
import '../../rooms/services/room_shop_service.dart';
import '../data/owned_collection_entry.dart';

/// The signed-in user's actual owned cosmetics, received visual gifts and
/// room rewards. Never creates an entitlement from a client or preview.
class OwnedCollectionScreen extends StatelessWidget {
  const OwnedCollectionScreen({this.initialTab = 0, super.key});
  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(body: Center(
        child: Text(ar ? 'يرجى تسجيل الدخول' : 'Please sign in'),
      ));
    }
    return DefaultTabController(
      length: 5,
      initialIndex: initialTab.clamp(0, 4),
      child: Scaffold(
        backgroundColor: const Color(0xFF091D19),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D352A),
          foregroundColor: Colors.white,
          title: Text(ar ? 'تم الامتلاك' : 'My Collection'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: const Color(0xFFFFDC91),
            unselectedLabelColor: Colors.white70,
            indicatorColor: const Color(0xFFFFDC91),
            tabs: [
              Tab(icon: const Icon(Icons.card_giftcard_rounded),
                  text: ar ? 'الهدايا' : 'Gifts'),
              Tab(icon: const Icon(Icons.crop_free_rounded),
                  text: ar ? 'الإطارات' : 'Frames'),
              Tab(icon: const Icon(Icons.wallpaper_rounded),
                  text: ar ? 'الخلفيات' : 'Backgrounds'),
              Tab(icon: const Icon(Icons.chat_bubble_outline_rounded),
                  text: ar ? 'الفقاعات' : 'Bubbles'),
              Tab(icon: const Icon(Icons.workspace_premium_outlined),
                  text: ar ? 'المزيد وVIP' : 'More & VIP'),
            ],
          ),
        ),
        body: TabBarView(children: [
          _ReceivedGiftTab(userId: uid, ar: ar),
          _OwnedAssetTab(userId: uid, type: 'frame', ar: ar),
          _OwnedAssetTab(userId: uid, type: 'background', ar: ar),
          _OwnedAssetTab(userId: uid, type: 'bubble', ar: ar),
          _OtherOwnedTab(userId: uid, ar: ar),
        ]),
      ),
    );
  }
}

Widget _empty(bool ar, String arLabel, String enLabel) => Center(
  child: Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.inventory_2_outlined, size: 62,
            color: Color(0xFFC7A873)),
        const SizedBox(height: 12),
        Text(ar ? arLabel : enLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70)),
      ],
    ),
  ),
);

Widget _error(bool ar) => _empty(ar,
    'تعذّر تحميل المقتنيات. تحقق من الإنترنت وصلاحيات Firebase.',
    'Unable to load collection. Check your connection and Firebase permissions.');

Widget _grid(List<OwnedCollectionEntry> entries, bool ar, String userId) {
  return LayoutBuilder(builder: (context, constraints) {
    final columns = constraints.maxWidth >= 700 ? 4 : 2;
    return GridView.builder(
      key: ValueKey('owned-grid-${entries.length}'),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 32),
      itemCount: entries.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns, childAspectRatio: .76,
        crossAxisSpacing: 10, mainAxisSpacing: 12,
      ),
      itemBuilder: (context, i) => _OwnedAssetCard(
        key: ValueKey(entries[i].id),
        entry: entries[i], ar: ar, userId: userId,
      ),
    );
  });
}

class _ReceivedGiftTab extends StatelessWidget {
  const _ReceivedGiftTab({required this.userId, required this.ar});
  final String userId;
  final bool ar;

  @override
  Widget build(BuildContext context) {
    // Visual gift receipts are different from consumable room rewards.
    // Both are shown, without incorrectly granting new gift balances.
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId)
          .collection('gift_notifications')
          .orderBy('createdAt', descending: true).limit(100).snapshots(),
      builder: (context, receipts) {
        if (receipts.hasError) return _error(ar);
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(userId)
              .collection('inventory').where('type', isEqualTo: 'gift')
              .snapshots(),
          builder: (context, inventory) {
            if (inventory.hasError) return _error(ar);
            if (!receipts.hasData || !inventory.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final gifted = receipts.data!.docs.where((doc) =>
                (doc.data()['type'] ?? 'gift').toString() == 'gift')
                .map((doc) => OwnedCollectionEntry.fromReceived(
                    doc.id, doc.data())).toList(growable: false);
            final rewards = inventory.data!.docs
                .map((doc) => OwnedCollectionEntry.fromInventory(
                    doc.id, doc.data()))
                .where((entry) => entry.quantity > 0)
                .toList(growable: false);
            final all = <OwnedCollectionEntry>[...rewards, ...gifted];
            if (all.isEmpty) {
              return _empty(ar, 'لم تستلم أي هدايا بعد. الهدايا القادمة من الروم واللايف والشات ستظهر هنا.',
                  'No received gifts yet. Room, Live and chat gifts will appear here.');
            }
            return Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  ar ? 'الهدايا المستلمة سجل موثّق، ولا تتحوّل تلقائيًا إلى هدايا قابلة لإعادة الإرسال.'
                     : 'Received gifts are verified receipts, not automatically reusable gifts.',
                  style: const TextStyle(color: Color(0xFFDFC69A), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(child: _grid(all, ar, userId)),
            ]);
          },
        );
      },
    );
  }
}

class _OwnedAssetTab extends StatelessWidget {
  const _OwnedAssetTab({
    required this.userId, required this.type, required this.ar,
  });
  final String userId;
  final String type;
  final bool ar;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId)
          .collection('inventory').where('type', isEqualTo: type).snapshots(),
      builder: (context, inventory) {
        if (inventory.hasError) return _error(ar);
        if (!inventory.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final entries = inventory.data!.docs
            .map((doc) => OwnedCollectionEntry.fromInventory(doc.id, doc.data()))
            .toList();
        if (type != 'background') return _results(entries);
        // Early room milestone background rewards were mirrored to
        // room_backgrounds, rather than the newer inventory collection.
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(userId)
              .collection('room_backgrounds').snapshots(),
          builder: (context, legacy) {
            if (legacy.hasError) return _error(ar);
            if (!legacy.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final themes = entries.map((entry) => entry.themeId).toSet();
            for (final doc in legacy.data!.docs) {
              final entry = OwnedCollectionEntry.fromLegacyBackground(
                  doc.id, doc.data());
              if (themes.add(entry.themeId)) entries.add(entry);
            }
            return _results(entries);
          },
        );
      },
    );
  }

  Widget _results(List<OwnedCollectionEntry> entries) {
    if (entries.isEmpty) {
      return _empty(ar, 'لا توجد مقتنيات من هذا النوع حتى الآن.',
          'Nothing owned in this category yet.');
    }
    return _grid(entries, ar, userId);
  }
}

class _OtherOwnedTab extends StatelessWidget {
  const _OtherOwnedTab({required this.userId, required this.ar});
  final String userId;
  final bool ar;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId)
          .collection('inventory').snapshots(),
      builder: (context, inventory) {
        if (inventory.hasError) return _error(ar);
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(userId)
              .collection('room_rewards').snapshots(),
          builder: (context, rewardSnapshot) {
            if (rewardSnapshot.hasError) return _error(ar);
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('users')
                  .doc(userId).snapshots(),
              builder: (context, profile) {
                if (profile.hasError) return _error(ar);
                if (!inventory.hasData || !rewardSnapshot.hasData ||
                    !profile.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final entries = inventory.data!.docs
                    .map((doc) => OwnedCollectionEntry.fromInventory(
                        doc.id, doc.data()))
                    .where((item) => !const {
                      'gift', 'frame', 'background', 'bubble',
                    }.contains(item.type)).toList();
                entries.addAll(rewardSnapshot.data!.docs.map((doc) =>
                    OwnedCollectionEntry.fromRoomReward(doc.id, doc.data())));
                final data = profile.data!.data() ?? const <String, dynamic>{};
                final expires = OwnedCollectionEntry.expiryOf(
                    {'expiresAt': data['vipExpiresAt']});
                if (data['isVip'] == true &&
                    (expires == null || expires.isAfter(DateTime.now()))) {
                  entries.add(OwnedCollectionEntry(
                    id: 'verified-vip-status', type: 'vip',
                    itemId: 'verified-vip-status',
                    name: 'WorldVoice VIP', source: 'verified_membership',
                    expiresAt: expires,
                  ));
                }
                if (entries.isEmpty) {
                  return _empty(ar,
                      'لا توجد شارات أو تأثيرات دخول أو مكافآت مهام حتى الآن.',
                      'No VIP badges, entry effects or room rewards yet.');
                }
                return _grid(entries, ar, userId);
              },
            );
          },
        );
      },
    );
  }
}

class _OwnedAssetCard extends StatefulWidget {
  const _OwnedAssetCard({
    required this.entry, required this.ar, required this.userId, super.key,
  });
  final OwnedCollectionEntry entry;
  final String userId;
  final bool ar;

  @override
  State<_OwnedAssetCard> createState() => _OwnedAssetCardState();
}

class _OwnedAssetCardState extends State<_OwnedAssetCard> {
  bool _busy = false;
  final RoomShopService _shop = RoomShopService();

  bool get _ar => widget.ar;
  OwnedCollectionEntry get entry => widget.entry;

  String _title() {
    if (entry.type == 'frame') {
      return WorldVoiceAvatarFrame.label(entry.itemId, ar: _ar);
    }
    if (entry.type == 'background') {
      return RoomBackgroundCatalog.itemForTheme(entry.themeId)
              ?.localizedName(_ar) ?? entry.name;
    }
    if (entry.type == 'bubble') {
      final bubble = WorldVoiceChatBubbles.find(entry.bubbleId);
      if (bubble != null) return _ar ? bubble.nameAr : bubble.name;
    }
    if (entry.type == 'reward') {
      return _ar ? entry.name.replaceFirst('Room level', 'مستوى الغرفة')
          : entry.name;
    }
    return entry.name;
  }

  String _source() {
    if (entry.isExpired) return _ar ? 'انتهت الصلاحية' : 'Expired';
    if (entry.pendingReward) {
      return _ar ? 'مكافأة مستحقة • تحتاج تفعيلًا' : 'Earned reward • pending activation';
    }
    return switch (entry.source) {
      'received_gift' => _ar ? 'هدية مستلمة' : 'Received gift',
      'gift' => _ar ? 'إهداء من مستخدم' : 'Gift from a member',
      'purchase' => _ar ? 'تم شراؤه' : 'Purchased',
      'admin_grant' => _ar ? 'منحة إدارية' : 'Admin grant',
      'room_level_reward' => _ar ? 'مكافأة مهام الروم' : 'Room task reward',
      'video_box' => _ar ? 'مكافأة Video Box' : 'Video Box reward',
      'verified_membership' => _ar ? 'عضوية VIP مفعّلة' : 'Active VIP membership',
      _ => _ar ? 'تم الامتلاك' : 'Owned',
    };
  }

  Future<void> _apply() async {
    if (_busy || !entry.isUsable) return;
    setState(() => _busy = true);
    try {
      if (entry.type == 'frame') {
        await _shop.setProfileFrame(entry.itemId);
      } else if (entry.type == 'bubble') {
        await _shop.setChatBubble(entry.bubbleId);
      } else {
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_ar ? 'تم تطبيق العنصر' : 'Item equipped'),
      ));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_ar ? 'تعذر تطبيق العنصر: $error'
            : 'Could not equip item: $error'),
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _art() {
    switch (entry.type) {
      case 'gift':
        final id = entry.itemId;
        if (RegExp(r'^wv_gift_[0-9]{3}$').hasMatch(id)) {
          return Image.asset('assets/gifts/hd/$id.webp',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.card_giftcard_rounded, color: Color(0xFFFFD98F), size: 60));
        }
        return const Icon(Icons.card_giftcard_rounded,
            color: Color(0xFFFFD98F), size: 60);
      case 'frame':
        return Center(child: WorldVoiceAvatarFrame(
          frameId: entry.itemId, size: 94, animate: false,
          child: const ColoredBox(color: Color(0xFF1F3A37),
              child: Center(child: Icon(Icons.person_rounded,
                  color: Colors.white, size: 47))),
        ));
      case 'background':
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: RoomBackgroundAtlas(themeId: entry.themeId),
        );
      case 'bubble':
        final design = WorldVoiceChatBubbles.find(entry.bubbleId);
        if (design != null) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(12),
            child: WorldVoiceBubbleFrame(design: design,
              child: const Text('WorldVoice',
                style: TextStyle(color: Colors.white))),
          ));
        }
        return const Icon(Icons.chat_bubble_outline_rounded,
            color: Color(0xFFFFD98F), size: 58);
      case 'vip':
        return const Icon(Icons.workspace_premium_rounded,
            color: Color(0xFFFFD98F), size: 65);
      case 'reward':
        return const Icon(Icons.castle_outlined,
            color: Color(0xFFFFD98F), size: 65);
      default:
        return const Icon(Icons.auto_awesome_rounded,
            color: Color(0xFFFFD98F), size: 62);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEquip = entry.isUsable &&
        (entry.type == 'frame' ||
            (entry.type == 'bubble' && entry.bubbleId.isNotEmpty));
    return Card(
      color: const Color(0xFF15382E),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0x665B9F7A)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Column(
          children: [
            Expanded(child: SizedBox(
              width: double.infinity, child: _art(),
            )),
            const SizedBox(height: 7),
            Text(_title(), maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(_source(), maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFFFD98F), fontSize: 11)),
            if (entry.expiresAt != null)
              Text('${entry.expiresAt!.toLocal().year}-${entry.expiresAt!.toLocal().month.toString().padLeft(2, '0')}-${entry.expiresAt!.toLocal().day.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white60, fontSize: 10)),
            if (entry.quantity > 1)
              Text('× ${entry.quantity}', style: const TextStyle(
                color: Colors.white70, fontSize: 11)),
            if (canEquip)
              SizedBox(
                height: 31, width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: _busy ? null : _apply,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(_busy ? '...' : (_ar ? 'استخدام' : 'Use')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
