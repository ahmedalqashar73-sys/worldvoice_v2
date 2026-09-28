import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/room_feature_models.dart';
import '../services/room_feature_service.dart';
import 'room_coin_store_sheet.dart';

/// The ONE gift chooser for real room/live/chat membership contexts.
/// Catalog, valuation and balance are read-only; settlement occurs on server.
class UnifiedGiftPanel extends StatefulWidget {
  const UnifiedGiftPanel({
    required this.contextType,
    required this.contextId,
    required this.recipients,
    this.onOpenCoinStore,
    super.key,
  });

  final String contextType;
  final String contextId;
  final Map<String, String> recipients;
  final VoidCallback? onOpenCoinStore;

  @override
  State<UnifiedGiftPanel> createState() => _UnifiedGiftPanelState();
}

class _UnifiedGiftPanelState extends State<UnifiedGiftPanel> {
  String? _recipient;
  RoomGiftCatalogItem? _gift;
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

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Center(child: Text(ar ? 'سجّل دخولك أولًا' : 'Sign in first'));
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('store_items')
          .where('type', isEqualTo: 'gift').snapshots(),
      builder: (context, giftSnapshot) {
        final gifts = giftSnapshot.data?.docs
            .map(RoomGiftCatalogItem.fromDoc)
            .where((gift) => gift.active && gift.priceCoins > 0)
            .toList(growable: false) ?? <RoomGiftCatalogItem>[];
        gifts.sort((a, b) => a.priceCoins.compareTo(b.priceCoins));
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.doc('economy_config/current')
              .snapshots(),
          builder: (context, policySnapshot) {
            final policy = policySnapshot.data?.data() ?? const <String, dynamic>{};
            final enabled = policy['enabled'] == true;
            final perUsd = (policy['coinsPerUsd'] as num?)?.toDouble();
            final share = (policy['receiverSharePercent'] as num?)?.toDouble();
            final diamondUsd = (policy['diamondUsdValue'] as num?)?.toDouble();
            final ready = enabled && perUsd != null && perUsd > 0 &&
                share != null && share >= 0 && share <= 100 &&
                diamondUsd != null && diamondUsd > 0;
            final selected = _gift != null && gifts.any((g) => g.id == _gift!.id)
                ? gifts.firstWhere((g) => g.id == _gift!.id) : null;
            final diamonds = selected != null && ready
                ? (selected.priceCoins / perUsd * (share / 100) / diamondUsd).floor()
                : null;
            final usd = diamonds == null ? null : diamonds * diamondUsd!;
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('users').doc(uid)
                  .snapshots(),
              builder: (context, walletSnapshot) {
                final coins = (walletSnapshot.data?.data()?['coins'] as num?)?.toInt() ?? 0;
                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: Row(children: [
                      const Icon(Icons.monetization_on_rounded, color: Color(0xFFD1AB4A)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(ar ? 'الرصيد: $coins كوينز' : 'Balance: $coins coins',
                          style: const TextStyle(fontWeight: FontWeight.w800))),
                      TextButton.icon(onPressed: _openRecharge,
                        icon: const Icon(Icons.add_circle_outline, size: 17),
                        label: Text(ar ? 'شحن' : 'Recharge')),
                    ]),
                  ),
                  if (!ready) Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(ar
                        ? 'الشراء غير متاح حتى اعتماد إعدادات المحفظة.'
                        : 'Purchases disabled until the economy is configured.',
                      textAlign: TextAlign.center),
                  ),
                  if (widget.contextType != 'room') Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(ar
                      ? 'هدايا اللايف والشات تحتاج تفعيل عضوية موثقة أولًا.'
                      : 'Live/chat gifting is locked until verified membership is available.',
                      textAlign: TextAlign.center),
                  ),
                  SizedBox(height: 48, child: widget.recipients.isEmpty
                    ? Center(child: Text(ar ? 'لا يوجد مستلم متاح' : 'No eligible recipients'))
                    : ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        children: widget.recipients.entries
                            .where((entry) => entry.key != uid)
                            .map((entry) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: Text(entry.value),
                                selected: _recipient == entry.key,
                                onSelected: _busy ? null : (_) => setState(() {
                                  _recipient = entry.key; _pendingKey = null;
                                  _needsRecharge = false;
                                }),
                              ),
                            )).toList(),
                      ),
                  ),
                  Expanded(child: giftSnapshot.hasError
                    ? Center(child: Text(ar ? 'تعذر تحميل الكتالوج' : 'Catalog unavailable'))
                    : gifts.isEmpty
                        ? Center(child: Text(ar ? 'لا توجد هدايا مفعلة' : 'No active gifts'))
                        : GridView.builder(
                            padding: const EdgeInsets.all(10),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3, childAspectRatio: .9,
                              mainAxisSpacing: 6, crossAxisSpacing: 6,
                            ),
                            itemCount: gifts.length,
                            itemBuilder: (context, index) {
                              final gift = gifts[index];
                              return Card(
                                color: selected?.id == gift.id
                                    ? Theme.of(context).colorScheme.primaryContainer
                                    : null,
                                child: InkWell(
                                  onTap: _busy ? null : () => setState(() {
                                    _gift = gift; _pendingKey = null;
                                    _needsRecharge = false;
                                  }),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(gift.emoji ?? '🎁',
                                          style: const TextStyle(fontSize: 26)),
                                      Text(gift.name, maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      Text('${gift.priceCoins} 🪙'),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )),
                  if (selected != null) Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text(diamonds == null
                      ? (ar ? 'قيمة المستلم تظهر بعد اعتماد الاقتصاد'
                          : 'Receiver value shown after economy setup')
                      : (ar
                          ? 'الهدية = حوالي $diamonds دايموند ≈ ${usd!.toStringAsFixed(2)} دولار (للهدية المدفوعة)'
                          : 'Paid gift ≈ $diamonds diamonds ≈ ${usd!.toStringAsFixed(2)} USD'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (_message != null) Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(_message!, textAlign: TextAlign.center),
                  ),
                  Padding(padding: const EdgeInsets.all(12),
                    child: FilledButton.icon(
                      onPressed: !_busy && ready && selected != null &&
                          widget.recipients.containsKey(_recipient) &&
                          widget.contextType == 'room' ? _send : null,
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
    );
  }
}
