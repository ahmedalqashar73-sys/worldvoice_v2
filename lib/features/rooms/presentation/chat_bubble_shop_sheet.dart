import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/chat_bubble_catalog.dart';
import '../services/room_shop_service.dart';
import '../services/vip_room_features.dart';
import 'chat_bubble_frame.dart';
import 'room_coin_store_sheet.dart';

/// A section of the existing WorldVoice backgrounds/frames shopping center.
/// Server, never the device, charges coins, owns inventory and validates equip.
class WorldVoiceChatBubbleShopSheet extends StatefulWidget {
  const WorldVoiceChatBubbleShopSheet({super.key});
  @override
  State<WorldVoiceChatBubbleShopSheet> createState() => _BubbleShopState();
}

class _BubbleShopState extends State<WorldVoiceChatBubbleShopSheet> {
  final _shop = RoomShopService();
  int? _days = 7;
  ChatBubbleTier? _tier;
  bool _busy = false;
  bool _admin = false;

  @override
  void initState() {
    super.initState();
    _shop.adminAccess.then((allowed) {
      if (mounted) setState(() => _admin = allowed);
    });
  }

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

  void _notice(String value) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
    }
  }

  Future<void> _failed(Object error) async {
    if (!mounted) return;
    if (error.toString().contains('NOT_ENOUGH_COINS')) {
      await showModalBottomSheet<void>(context: context,
        isScrollControlled: true, builder: (_) => const RoomCoinStoreSheet());
    } else {
      _notice(error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  Future<bool> _confirm(ChatBubbleDesign design, {String? recipient}) async {
    final label = _ar ? design.nameAr : design.name;
    final duration = _days == null
        ? (_ar ? 'دائم' : 'Permanent')
        : '$_days ${_ar ? 'أيام' : 'days'}';
    final policyText = _ar
      ? 'تبدأ الصلاحية فور وصول العنصر. الهدية المكررة تمدد المدة المتبقية.'
      : 'Validity starts at delivery. Repeated gifts extend existing time.';
    final result = await showDialog<bool>(context: context,
      builder: (dialog) => AlertDialog(
        title: Text(recipient == null
          ? (_ar ? 'تأكيد الشراء' : 'Confirm purchase')
          : (_ar ? 'تأكيد الإهداء' : 'Confirm gift')),
        content: Text('$label • $duration\n'
            '${design.price(_days)} ${_ar ? 'كوين' : 'coins'}'
            '${recipient == null ? '' : '\n$recipient'}\n'
            '$policyText'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false),
            child: Text(_ar ? 'إلغاء' : 'Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialog, true),
            child: Text(_ar ? 'تأكيد' : 'Confirm')),
        ],
      ));
    return result == true;
  }

  Future<void> _buy(ChatBubbleDesign design) async {
    if (_busy || design.isVip) return;
    setState(() => _busy = true);
    try {
      final admin = await _shop.adminAccess;
      if (!mounted) return;
      if (admin) {
        // Only the authenticated server can grant an administrator cosmetic.
        await _shop.grantItem(design.storeId(_days));
      } else {
        if (!await _confirm(design)) return;
        await _shop.purchaseItem(design.storeId(_days));
      }
      try {
        await _shop.setChatBubble(design.id);
        _notice(admin
          ? (_ar ? 'تم تفعيل الفقاعة مجانًا للأدمن، بدون خصم كوينز.'
            : 'Equipped free for admin. No coins deducted.')
          : (_ar ? 'تم الشراء وتفعيل الفقاعة للرسائل الجديدة.'
            : 'Purchased and equipped for new messages.'));
      } catch (_) {
        _notice(_ar ? 'تم الشراء. اضغط استخدام لتفعيل الفقاعة؛ لا تحتاج للشراء مجددًا.'
          : 'Purchased. Tap Use to equip; you do not need to buy again.');
      }
    } catch (error) { await _failed(error); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _gift(ChatBubbleDesign design) async {
    if (_busy || design.isVip) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final contacts = await FirebaseFirestore.instance.collection('users')
        .doc(uid).collection('following').get();
      if (!mounted) return;
      final recipient = await showDialog<QueryDocumentSnapshot<Map<String, dynamic>>>(
        context: context,
        builder: (dialog) => SimpleDialog(
          title: Text(_ar ? 'اختر صديقًا' : 'Choose a friend'),
          children: contacts.docs.isEmpty
            ? [Padding(padding: const EdgeInsets.all(15),
                child: Text(_ar ? 'لا يوجد أصدقاء' : 'No friends'))]
            : contacts.docs.map((doc) => SimpleDialogOption(
                onPressed: () => Navigator.pop(dialog, doc),
                child: Text((doc.data()['displayName'] ?? doc.id).toString()),
              )).toList(),
        ),
      );
      if (recipient == null || !mounted ||
          !await _confirm(design, recipient:
            (recipient.data()['displayName'] ?? recipient.id).toString())) {
        return;
      }
      setState(() => _busy = true);
      await _shop.giftItem(
        itemId: design.storeId(_days), recipientId: recipient.id);
      _notice(_ar ? 'تم الإهداء؛ بدأت الصلاحية فور الوصول.'
        : 'Gift delivered; validity starts now.');
    } catch (error) { await _failed(error); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _equip(String designId) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _shop.setChatBubble(designId);
      _notice(_ar ? 'تم تطبيق الفقاعة.' : 'Bubble equipped.');
    } catch (error) { _notice(error.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  void _preview(ChatBubbleDesign design) {
    showDialog<void>(context: context, builder: (dialog) =>
      AlertDialog(
        title: Text(_ar ? design.nameAr : design.name),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          WorldVoiceBubbleFrame(design: design, showSignature: true,
            child: const Text('Hello! How are you today? 🌸',
              style: TextStyle(color: Colors.white, fontSize: 16))),
          const SizedBox(height: 12),
          WorldVoiceBubbleFrame(design: design, compact: true,
            child: const Text('WorldVoice Room / Live',
              style: TextStyle(color: Colors.white))),
        ]),
        actions: [TextButton(
          onPressed: () => Navigator.pop(dialog),
          child: Text(_ar ? 'إغلاق' : 'Close'))],
      ));
  }

  bool _owned(ChatBubbleDesign design,
      Map<String, Map<String, dynamic>> items, bool vip) {
    if (design.isVip) return vip;
    final data = items[design.inventoryId];
    if (data == null || data['type'] != 'bubble' ||
        data['bubbleId'] != design.id ||
        (data['quantity'] as num? ?? 0) <= 0) {
      return false;
    }
    final exp = data['expiresAt'];
    return exp == null || (exp is Timestamp &&
        exp.toDate().isAfter(DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Sign in to use Bubbles'));
    return SafeArea(child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .84,
      child: Column(children: [
        ListTile(
          leading: const Icon(Icons.chat_bubble_outline_rounded),
          title: Text(_ar ? 'فقاعات الدردشة' : 'Chat Bubbles',
            style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(_ar ? 'الشات الخاص • الروم • اللايف'
            : 'Private chats • Rooms • Live'),
          trailing: IconButton(icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context)),
        ),
        Wrap(spacing: 6, children: [
          for (final days in <int?>[7, 30, null])
            ChoiceChip(
              label: Text(days == null ? (_ar ? 'دائم' : 'Permanent')
                  : days.toString() + (_ar ? ' أيام' : ' days')),
              selected: _days == days,
              onSelected: (_) => setState(() => _days = days)),
        ]),
        SingleChildScrollView(scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final tier in <ChatBubbleTier?>[
              null, ...ChatBubbleTier.values
            ])
              Padding(padding: const EdgeInsetsDirectional.only(end: 6),
                child: FilterChip(
                  label: Text(tier == null
                    ? (_ar ? 'الكل' : 'All')
                    : WorldVoiceChatBubbles.tierName(tier, ar: _ar)),
                  selected: _tier == tier,
                  onSelected: (_) => setState(() => _tier = tier))),
          ])),
        Expanded(child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users')
            .doc(uid).snapshots(),
          builder: (context, profileSnapshot) =>
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('users')
                .doc(uid).collection('inventory')
                .where('type', isEqualTo: 'bubble').snapshots(),
              builder: (context, ownedSnapshot) {
                final profile = profileSnapshot.data?.data();
                final selected = (profile?['chatBubbleId'] ?? 'free').toString();
                final vip = VipRoomFeatures.activeVip(
                  profile, DateTime.now());
                final items = <String, Map<String, dynamic>>{
                  for (final doc in ownedSnapshot.data?.docs ??
                      <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                    doc.id: doc.data(),
                };
                final designs = WorldVoiceChatBubbles.designs
                  .where((d) => _tier == null || d.tier == _tier)
                  .toList();
                return Column(children: [
                  Row(children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.inventory_2_outlined, size: 17),
                    const SizedBox(width: 6),
                    Text(_ar ? 'حقيبتي' : 'My Collection',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: Text(_ar ? 'الافتراضية' : 'Default'),
                      onPressed: _busy || selected == 'free'
                          ? null : () => _equip('free')),
                    const SizedBox(width: 8),
                  ]),
                  Expanded(child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                    itemCount: designs.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: .69,
                      mainAxisSpacing: 10, crossAxisSpacing: 10),
                    itemBuilder: (context, index) {
                      final design = designs[index];
                      final owned = _owned(design, items, vip);
                      final active = owned && selected == design.id;
                      final exp = items[design.inventoryId]?['expiresAt'];
                      final permanent = owned && !design.isVip && exp == null;
                      final duration = _days == null
                          ? (_ar ? 'دائم' : 'Permanent')
                          : '$_days ${_ar ? 'أيام' : 'days'}';
                      return Card(
                        clipBehavior: Clip.antiAlias, margin: EdgeInsets.zero,
                        child: Padding(padding: const EdgeInsets.all(7),
                          child: Column(children: [
                            Expanded(child: Center(
                              child: GestureDetector(
                                onTap: () => _preview(design),
                                child: WorldVoiceBubbleFrame(design: design,
                                  child: const Text('Hello!',
                                    style: TextStyle(color: Colors.white,
                                      fontWeight: FontWeight.w800)))))),
                            Text(_ar ? design.nameAr : design.name,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 3),
                            Text(design.isVip ? 'VIP Exclusive'
                              : _admin ? (_ar ? 'مجاني للأدمن' : 'Free for admin')
                              : '${design.price(_days)} 🪙 • $duration',
                              style: const TextStyle(fontSize: 10)),
                            if (owned)
                              Text(design.isVip ? 'VIP'
                                : permanent ? (_ar ? 'ملكية دائمة' : 'Forever')
                                : exp is Timestamp
                                  ? exp.toDate().toLocal().toString().split(' ').first
                                  : (_ar ? 'مملوكة' : 'Owned'),
                                style: const TextStyle(fontSize: 10,
                                  color: Color(0xFF32B889))),
                            const SizedBox(height: 5),
                            Row(children: [
                              Expanded(child: OutlinedButton(
                                onPressed: () => _preview(design),
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero),
                                child: Text(_ar ? 'معاينة' : 'Preview',
                                  style: const TextStyle(fontSize: 10)))),
                              const SizedBox(width: 4),
                              Expanded(child: FilledButton(
                                onPressed: _busy || !_shop.isConfigured ||
                                    active || (design.isVip && !vip)
                                    ? null
                                    : owned ? () => _equip(design.id)
                                    : () => _buy(design),
                                style: FilledButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero),
                                child: Text(active ? (_ar ? 'مفعّلة' : 'Active')
                                  : owned ? (_ar ? 'استخدام' : 'Use')
                                  : design.isVip ? 'VIP'
                                  : _admin ? (_ar ? 'تفعيل مجاني' : 'Use free')
                                  : (_ar ? 'شراء' : 'Buy'),
                                  style: const TextStyle(fontSize: 10)))),
                            ]),
                            if (!design.isVip)
                              Row(children: [
                                if (owned && !permanent)
                                  Expanded(child: TextButton(
                                    onPressed: _busy || !_shop.isConfigured
                                      ? null : () => _buy(design),
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(0, 27),
                                      padding: EdgeInsets.zero),
                                    child: Text(_ar ? 'تجديد' : 'Renew',
                                      style: const TextStyle(fontSize: 10)))),
                                Expanded(child: TextButton(
                                  onPressed: _busy || !_shop.isConfigured
                                    ? null : () => _gift(design),
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(0, 27),
                                    padding: EdgeInsets.zero),
                                  child: Text(_ar ? 'إهداء' : 'Gift',
                                    style: const TextStyle(fontSize: 10)))),
                              ]),
                          ]),
                        ),
                      );
                    },
                  )),
                ]);
              },
            ),
        )),
      ]),
    ));
  }
}
