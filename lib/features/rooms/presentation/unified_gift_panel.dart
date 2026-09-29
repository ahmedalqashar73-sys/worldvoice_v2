import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/room_feature_models.dart';
import '../data/classic_gift_catalog.dart';
import 'classic_gift_visual.dart';
import '../services/room_feature_service.dart';
import '../services/room_coin_purchase_service.dart';
import 'room_coin_store_sheet.dart';

/// The ONE gift chooser for real room/live/chat membership contexts.
/// Catalog, valuation and balance are read-only; settlement occurs on server.
class UnifiedGiftPanel extends StatefulWidget {
  const UnifiedGiftPanel({
    required this.contextType,
    required this.contextId,
    required this.recipients,
    this.onOpenCoinStore,
    this.onPreview,
    super.key,
  });

  final String contextType;
  final String contextId;
  final Map<String, String> recipients;
  final VoidCallback? onOpenCoinStore;
  /// Optional in-context animation preview, never a gift delivery.
  final void Function(RoomGiftCatalogItem gift, String? recipientId)? onPreview;

  @override
  State<UnifiedGiftPanel> createState() => _UnifiedGiftPanelState();
}

class _UnifiedGiftPanelState extends State<UnifiedGiftPanel> {
  late final Future<List<RoomGiftCatalogItem>> _classicPreviews =
      ClassicGiftCatalog.load();
  String? _recipient;
  RoomGiftCatalogItem? _gift;
  int _giftCategory = 0; // 1-50, 51-150, 151-500, premium 501+

  bool _inSelectedCategory(RoomGiftCatalogItem gift) {
    final price = gift.priceCoins;
    return switch (_giftCategory) {
      0 => price >= 1 && price <= 50,
      1 => price > 50 && price <= 150,
      2 => price > 150 && price <= 500,
      _ => price > 500,
    };
  }
  bool _busy = false;
  bool _needsRecharge = false;
  String? _pendingKey;
  String? _pendingSignature;
  String? _message;

  String _newKey() => List<int>.generate(24, (_) => Random.secure().nextInt(256))
      .map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  Future<void> _send() async {
    final gift = _gift;
    final recipient = _recipient;
    if (_busy || gift == null || recipient == null) return;
    final signature = '${widget.contextType}:${widget.contextId}:$recipient:${gift.id}';
    if (signature != _pendingSignature) {
      _pendingSignature = signature;
      _pendingKey = _newKey();
    }
    setState(() { _busy = true; _message = null; });
    try {
      await RoomFeatureService.sendContextGift(
        context: widget.contextType, contextId: widget.contextId,
        recipientId: recipient, giftId: gift.id, requestKey: _pendingKey,
      );
      if (!mounted) return;
      setState(() {
        _needsRecharge = false;
        _pendingKey = null;
        _pendingSignature = null;
        _message = Localizations.localeOf(context).languageCode == 'ar'
            ? 'تم إرسال الهدية' : 'Gift sent';
      });
    } catch (error) {
      if (!mounted) return;
      final reason = error.toString();
      final insufficient = reason.contains('NOT_ENOUGH_COINS');
      setState(() {
        _needsRecharge = insufficient;
        _message = insufficient
            ? (Localizations.localeOf(context).languageCode == 'ar'
                ? 'رصيدك لا يكفي. اشحن ثم اضغط متابعة الهدية.'
                : 'Not enough coins. Recharge then continue your gift.')
            : reason.replaceFirst('Bad state: ', '');
      });
      if (insufficient) _openRecharge();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openRecharge() {
    if (widget.onOpenCoinStore != null) {
      widget.onOpenCoinStore!();
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const RoomCoinStoreSheet(),
    );
  }

  Future<void> _previewGift(RoomGiftCatalogItem gift) async {
    // Voice rooms can dismiss the picker and preview directly over the stage.
    // This callback is presentation-only and never touches Firestore/wallets.
    if (widget.onPreview != null) {
      widget.onPreview!(gift, _recipient);
      return;
    }
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final sender = FirebaseAuth.instance.currentUser?.displayName?.trim();
    final senderName = sender?.isNotEmpty == true
        ? sender! : (ar ? 'أنت' : 'You');
    final recipientName = widget.recipients[_recipient] ??
        (ar ? 'اختر المستلم' : 'Select recipient');
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .7),
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF104C39),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(ar ? 'تجربة التأثير — دون خصم كوينات'
                : 'Animation preview — no coins charged',
              style: const TextStyle(color: Color(0xFFB8F0D4),
                  fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [
                  Color(0xFF164D38), Color(0xFF275B42)]),
                border: Border.all(color: const Color(0xFFDFBF76)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(ar ? 'من المرسل إلى المستلم' : 'GIFT FROM • TO',
                  style: const TextStyle(
                    color: Color(0xFF9CD9B5),
                    fontSize: 10, fontWeight: FontWeight.bold)),
                Text('$senderName  ✦  $recipientName',
                  maxLines: 2, textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFFFE3AA),
                    fontSize: 13, fontWeight: FontWeight.w900)),
              ]),
            ),
            const SizedBox(height: 5),
            ClassicGiftVisual(gift: gift, size: 177, animate: true),
            Text(gift.localizedName(ar), textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18,
                  fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('${gift.priceCoins} 🪙',
              style: const TextStyle(color: Color(0xFFFFD981),
                  fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(ar ? 'إغلاق' : 'Close',
                style: const TextStyle(color: Colors.white)),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Center(child: Text(ar ? 'سجّل دخولك أولًا' : 'Sign in first'));
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF09271F), Color(0xFF14513A),
                   Color(0xFF082B25)])),
      child: FutureBuilder<List<RoomGiftCatalogItem>>(
      future: _classicPreviews,
      builder: (context, classicSnapshot) => StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('store_items')
          .where('type', isEqualTo: 'gift').snapshots(),
      builder: (context, giftSnapshot) {
        final published = giftSnapshot.data?.docs
            .map(RoomGiftCatalogItem.fromDoc)
            .toList(growable: false) ?? <RoomGiftCatalogItem>[];
        final previews = classicSnapshot.data ?? const <RoomGiftCatalogItem>[];
        final classics = ClassicGiftCatalog.merge(
          previews: previews, published: published);
        final shownGifts = _giftCategory == 0
            ? classics
            : (published.where((gift) =>
                gift.active && gift.priceCoins > 0 &&
                _inSelectedCategory(gift)).toList(growable: true)
                  ..sort((a, b) => a.priceCoins.compareTo(b.priceCoins)));
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.doc('economy_config/current')
              .snapshots(),
          builder: (context, policySnapshot) {
            final policy = policySnapshot.data?.data() ?? const <String, dynamic>{};
            final enabled = policy['enabled'] == true;
            final perUsd = (policy['coinsPerUsd'] as num?)?.toDouble();
            final share = (policy['receiverSharePercent'] as num?)?.toDouble();
            final diamondUsd = (policy['diamondUsdValue'] as num?)?.toDouble();
            final ready = enabled &&
                policy['privateWalletCutoverVerified'] == true &&
                policy['publicProfileRulesVerified'] == true &&
                perUsd != null && perUsd > 0 &&
                share != null && share >= 0 && share <= 100 &&
                diamondUsd != null && diamondUsd > 0;
            final selected = _gift != null &&
                    shownGifts.any((g) => g.id == _gift!.id)
                ? shownGifts.firstWhere((g) => g.id == _gift!.id) : null;
            final diamonds = selected != null && ready
                ? (selected.priceCoins / perUsd * (share / 100) / diamondUsd).floor()
                : null;
            final usd = diamonds == null ? null : diamonds * diamondUsd!;
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: RoomCoinPurchaseService.instance.watchMyWallet(),
              builder: (context, walletSnapshot) {
                final walletReady = walletSnapshot.data?.exists == true &&
                    !walletSnapshot.hasError;
                final coins = walletReady
                    ? (walletSnapshot.data!.data()?['coins'] as num?)?.toInt()
                    : null;
                return Column(children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF08281F).withValues(alpha: .65),
                      border: const Border(bottom: BorderSide(
                        color: Color(0x66DCBE77))),
                    ),
                    child: Row(children: [
                      const Icon(Icons.auto_awesome_rounded,
                        color: Color(0xFFF8DC95), size: 24),
                      const SizedBox(width: 9),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ar ? 'WorldVoice • الهدايا الملكية'
                                  : 'WorldVoice • Royal Gifts',
                            style: const TextStyle(
                              color: Colors.white, fontSize: 16,
                              fontWeight: FontWeight.w900)),
                          Text(walletReady
                            ? (ar ? 'رصيدك: $coins كوينز'
                                  : 'Balance: $coins coins')
                            : (ar ? 'المحفظة قيد التجهيز'
                                  : 'Wallet setup pending'),
                            style: const TextStyle(
                              color: Color(0xFFF6DCA0), fontSize: 12,
                              fontWeight: FontWeight.w800)),
                        ],
                      )),
                      FilledButton.tonalIcon(
                        onPressed: _openRecharge,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE4C27B),
                          foregroundColor: const Color(0xFF17412E)),
                        icon: const Icon(Icons.add_circle_rounded, size: 17),
                        label: Text(ar ? 'شحن' : 'Recharge'),
                      ),
                    ]),
                  ),
                  if (!ready) Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(ar
                        ? 'الشراء غير متاح حتى اعتماد إعدادات المحفظة.'
                        : 'Purchases disabled until the economy is configured.',
                      textAlign: TextAlign.center),
                  ),
                  SizedBox(height: 48, child: widget.recipients.isEmpty
                    ? Center(child: Text(
                        ar ? 'اختر هديتك لتجربة التأثير'
                           : 'Choose a gift to preview its effect',
                        style: const TextStyle(color: Color(0xFFB5D7C5),
                            fontSize: 12)))
                    : ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        children: widget.recipients.entries
                            .where((entry) => entry.key != uid)
                            .map((entry) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: Text(entry.value),
                                labelStyle: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w700),
                                backgroundColor: const Color(0xFF265B46),
                                selectedColor: const Color(0xFF956C30),
                                side: const BorderSide(color: Color(0x6680CBA9)),
                                selected: _recipient == entry.key,
                                onSelected: _busy ? null : (_) => setState(() {
                                  _recipient = entry.key; _pendingKey = null;
                                  _needsRecharge = false;
                                }),
                              ),
                            )).toList(),
                      ),
                  ),
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      children: [
                        for (var tier = 0; tier < 4; tier++)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 6),
                            child: ChoiceChip(
                              selected: _giftCategory == tier,
                              selectedColor: const Color(0xFF93703D),
                              backgroundColor: const Color(0xFF214C3A),
                              labelStyle: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w800),
                              side: const BorderSide(color: Color(0x6689C8A6)),
                              avatar: Icon(
                                tier == 3 ? Icons.auto_awesome_rounded
                                    : Icons.card_giftcard_rounded,
                                size: 17,
                                color: tier == 3
                                    ? const Color(0xFFC79730)
                                    : null,
                              ),
                              label: Text(switch (tier) {
                                0 => ar ? '1–50 كوينز' : '1–50 coins',
                                1 => ar ? '51–150 كوينز' : '51–150 coins',
                                2 => ar ? '151–500 كوينز' : '151–500 coins',
                                _ => ar ? 'الهدايا الفخمة' : 'Luxury gifts',
                              }),
                              onSelected: _busy ? null : (_) => setState(() {
                                _giftCategory = tier;
                                _gift = null;
                                _pendingKey = null;
                                _pendingSignature = null;
                                _needsRecharge = false;
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_giftCategory == 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Text(ar
                        ? '30 هدية كلاسيكية فاخرة • اختر هدية لتجربة الحركة'
                        : '30 classic premium gifts • tap to preview effects',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFEBD49B),
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                    ),
                  Expanded(child: classicSnapshot.hasError && _giftCategory == 0
                    ? Center(child: Text(ar
                        ? 'تعذر تحميل هدايا التجربة'
                        : 'Gift previews could not be loaded'))
                    : _giftCategory == 0 && !classicSnapshot.hasData
                        ? const Center(child: CircularProgressIndicator())
                    : giftSnapshot.hasError && _giftCategory != 0
                        ? Center(child: Text(ar
                            ? 'تعذر تحميل الكتالوج'
                            : 'Catalog unavailable'))
                    : shownGifts.isEmpty
                        ? Center(child: Text(ar
                            ? 'لا توجد هدايا منشورة في هذه الفئة'
                            : 'No published gifts in this category'))
                        : GridView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3, mainAxisExtent: 139,
                              mainAxisSpacing: 6, crossAxisSpacing: 4),
                            itemCount: shownGifts.length,
                            itemBuilder: (context, index) {
                              final gift = shownGifts[index];
                              final chosen = selected?.id == gift.id;
                              return InkWell(
                                key: ValueKey('gift-${gift.id}'),
                                borderRadius: BorderRadius.circular(14),
                                onTap: _busy ? null : () => setState(() {
                                  _gift = gift;
                                  _pendingKey = null;
                                  _pendingSignature = null;
                                  _needsRecharge = false;
                                }),
                                onLongPress: () => _previewGift(gift),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedScale(
                                      scale: chosen ? 1.08 : 1,
                                      duration: const Duration(
                                        milliseconds: 180),
                                      child: ClassicGiftVisual(
                                        gift: gift, size: 86),
                                    ),
                                    Text(gift.localizedName(ar),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: chosen
                                            ? const Color(0xFFFFDE94)
                                            : Colors.white)),
                                    const SizedBox(height: 2),
                                    Text('${gift.priceCoins} 🪙',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFC69B33))),
                                    if (chosen)
                                      Container(
                                        width: 17, height: 3,
                                        margin: const EdgeInsets.only(top: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8D589),
                                          borderRadius:
                                              BorderRadius.circular(100))),
                                  ],
                                ),
                              );
                            },
                          )),
                  if (selected != null && selected.active) Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    child: Text(diamonds == null
                      ? (ar ? 'قيمة المستلم تظهر بعد اعتماد الاقتصاد'
                          : 'Receiver value appears after economy setup')
                      : (ar
                          ? 'قيمة المستلم: $diamonds دايموند ≈ ${usd!.toStringAsFixed(2)} دولار'
                          : 'Receiver value: $diamonds diamonds ≈ ${usd!.toStringAsFixed(2)} USD'),
                      textAlign: TextAlign.center),
                  ),
                  if (selected != null && !selected.active)
                    Text(ar ? 'عرض تجريبي فقط • الإرسال غير مفعل'
                        : 'Preview only • sending not enabled',
                      style: const TextStyle(fontSize: 12,
                          color: Color(0xFF9D7327))),
                  if (selected != null)
                    TextButton.icon(
                      key: const ValueKey('gift-animation-preview'),
                      onPressed: () => _previewGift(selected),
                      icon: const Icon(Icons.play_circle_outline,
                          color: Color(0xFF0B8358)),
                      label: Text(ar ? 'جرّب تأثير الهدية'
                          : 'Preview gift effect',
                        style: const TextStyle(color: Color(0xFF0B8358))),
                    ),
                  if (_message != null) Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(_message!, textAlign: TextAlign.center),
                  ),
                  Padding(padding: const EdgeInsets.all(12),
                    child: FilledButton.icon(
                      onPressed: !_busy && ready && walletReady &&
                          selected?.active == true &&
                          widget.contextType != 'live' &&
                          widget.recipients.containsKey(_recipient)
                          ? _send : null,
                      icon: _busy ? const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.card_giftcard_outlined),
                      label: Text(_needsRecharge
                          ? (ar ? 'متابعة الهدية بعد الشحن' : 'Continue gift after recharge')
                          : (ar ? 'إرسال الهدية' : 'Send gift')),
                    ),
                  ),
                ]);
              },
            );
          },
        );
      },
    )));
  }
}
