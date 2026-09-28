import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/room_coin_purchase_service.dart';
import '../data/coin_product_config.dart';

class RoomCoinStoreSheet extends StatefulWidget {
  const RoomCoinStoreSheet({super.key});

  @override
  State<RoomCoinStoreSheet> createState() => _RoomCoinStoreSheetState();
}

class _RoomCoinStoreSheetState extends State<RoomCoinStoreSheet> {
  final RoomCoinPurchaseService _store =
      RoomCoinPurchaseService.instance;

  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
    if (!kIsWeb) _store.initialize();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .74,
        child: Column(
          children: [
            ListTile(
              title: Text(
                isArabic ? 'شراء العملات' : 'Buy coins',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: user == null
                  ? null
                  : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('private_wallet')
                          .doc('summary')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final coins =
                            (snapshot.data?.data()?['coins'] as num?)
                                    ?.toInt() ??
                                0;
                        return Text(
                          isArabic
                              ? 'رصيدك الحالي: $coins'
                              : 'Current balance: $coins',
                        );
                      },
                    ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: isArabic ? 'محفظتي' : 'My wallet',
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    onPressed: user == null ? null : () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const _WalletView(),
                      );
                    },
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            if (_store.message?.trim().isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Material(
                  color:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      _store.message!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: kIsWeb
                  ? _WebCheckoutCatalog(isArabic: isArabic, store: _store)
                  : _store.loading
                  ? const Center(child: CircularProgressIndicator())
                  : !_store.storeAvailable
                      ? Center(
                          child: Text(
                            isArabic
                                ? 'المتجر غير متاح على هذا الجهاز.'
                                : 'The store is not available on this device.',
                          ),
                        )
                      : _store.products.isEmpty
                          ? Center(
                              child: Text(
                                isArabic
                                    ? 'لا توجد باقات Coins مفعلة حتى الآن.'
                                    : 'No coin packs are active yet.',
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _store.refreshProducts,
                              child: ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                itemCount: _store.products.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final item = _store.products[index];
                                  return Card(
                                    child: ListTile(
                                      leading: const CircleAvatar(
                                        child: Icon(
                                          Icons.monetization_on_rounded,
                                        ),
                                      ),
                                      title: Text(
                                        '${item.config.coins} Coins',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      subtitle: Text(item.product.title),
                                      trailing: FilledButton(
                                        onPressed: () => _store.buy(item),
                                        child: Text(item.product.price),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wallet preview and exchange are hosted in the existing coin-store sheet.
/// No client writes monetary Firestore fields, and payout requests are not
/// offered until a verified third-party payout provider issues account tokens.
class _WalletView extends StatefulWidget {
  const _WalletView();

  @override
  State<_WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<_WalletView> {
  final _amount = TextEditingController();
  final _service = RoomCoinPurchaseService.instance;
  bool _busy = false;
  String? _status;
  Map<String, dynamic>? _quote;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  int? get _diamonds => int.tryParse(_amount.text.trim());

  Future<void> _perform(
    Future<String> Function() action,
  ) async {
    if (_busy) return;
    setState(() { _busy = true; _status = null; });
    try {
      final response = await action();
      if (mounted) setState(() => _status = response);
    } catch (error) {
      if (mounted) {
        setState(() => _status =
            error.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Sign in first.'));
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .85,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text(ar ? 'محفظتي' : 'My wallet',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users').doc(uid)
                    .collection('private_wallet').doc('summary').snapshots(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data() ?? <String, dynamic>{};
                  if (snapshot.hasError) {
                    return Text(ar ? 'المحفظة غير متاحة' : 'Wallet unavailable');
                  }
                  final coins = (data['coins'] as num?)?.toInt() ?? 0;
                  final available = (data['diamonds'] as num?)?.toInt() ?? 0;
                  final pending =
                      (data['diamondsPending'] as num?)?.toInt() ?? 0;
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 14, runSpacing: 6,
                      children: [
                        Chip(label: Text(ar ? 'الكوينز: $coins' : 'Coins: $coins')),
                        Chip(label: Text(ar
                            ? 'دايموندز متاحة: $available'
                            : 'Available diamonds: $available')),
                        Chip(label: Text(ar
                            ? 'قيد الانتظار: $pending'
                            : 'Pending diamonds: $pending')),
                      ],
                    ),
                  );
                },
              ),
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .doc('economy_config/current').snapshots(),
                builder: (context, snapshot) {
                  final policy = snapshot.data?.data();
                  if (policy?['enabled'] != true) {
                    return Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(ar
                          ? 'تبديل العملات والسحب مقفلان حتى تفعيل إعدادات المحفظة.'
                          : 'Exchanges and withdrawals are locked until wallet settings are approved.',
                          textAlign: TextAlign.center),
                    );
                  }
                  final minimum =
                      (policy?['minExchangeDiamonds'] as num?)?.toInt();
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _amount,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: ar
                                ? 'عدد الدايموندز (الحد الأدنى: $minimum)'
                                : 'Diamonds (minimum: $minimum)',
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() => _quote = null),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.currency_exchange),
                            label: Text(ar ? 'تبديل إلى كوينز' : 'Exchange for coins'),
                            onPressed: _busy || minimum == null ||
                                    _diamonds == null || _diamonds! < minimum
                                ? null
                                : () async {
                                    final amount = _diamonds!;
                                    final confirmed =
                                        await showDialog<bool>(
                                      context: context,
                                      builder: (dialogContext) => AlertDialog(
                                        title: Text(ar ? 'تأكيد التبديل' : 'Confirm exchange'),
                                        content: Text(ar
                                            ? 'تبديل $amount دايموندز؟ تُحدد الكوينز من السيرفر، ولا يمكن التراجع.'
                                            : 'Exchange $amount diamonds? The server calculates your coins and this cannot be undone.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(dialogContext, false),
                                            child: Text(ar ? 'إلغاء' : 'Cancel'),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(dialogContext, true),
                                            child: Text(ar ? 'تأكيد' : 'Confirm'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed != true || !mounted) return;
                                    await _perform(() async {
                                      final result =
                                          await _service.exchangeDiamonds(amount);
                                      final coins =
                                          (result['receivedCoins'] as num?)?.toInt();
                                      return ar
                                          ? 'تم إضافة $coins كوينز'
                                          : 'Credited $coins coins';
                                    });
                                  },
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.receipt_long_outlined),
                            label: Text(ar ? 'تفاصيل السحب' : 'Withdrawal quote'),
                            onPressed: _busy || _diamonds == null ||
                                    _diamonds! <= 0
                                ? null
                                : () => _perform(() async {
                                      final quote = await _service
                                          .getWithdrawalQuote(_diamonds!);
                                      if (mounted) setState(() => _quote = quote);
                                      return ar
                                          ? 'هذه تفاصيل تقديرية، لم يُرسل طلب سحب.'
                                          : 'Quote only. No withdrawal was submitted.';
                                    }),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.hourglass_bottom),
                            label: Text(ar ? 'تحديث المبالغ المعلقة' : 'Release matured'),
                            onPressed: _busy
                                ? null : () => _perform(() async {
                                    final released =
                                        await _service.releaseMaturedDiamonds();
                                    return ar
                                        ? 'تم إتاحة $released دايموندز'
                                        : 'Released $released diamonds';
                                  }),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              if (_quote != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(ar
                      ? 'الإجمالي: ${_quote!['grossUsd']} USD، الرسوم: ${_quote!['feeUsd']} USD، الصافي: ${_quote!['netUsd']} USD، موعد المعالجة: ${_quote!['payoutWindow']}'
                      : 'Gross: ${_quote!['grossUsd']} USD; fee: ${_quote!['feeUsd']} USD; net: ${_quote!['netUsd']} USD; review window: ${_quote!['payoutWindow']}',
                      textAlign: TextAlign.center),
                ),
              if (_status != null)
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(_status!, textAlign: TextAlign.center),
                ),
              const Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users').doc(uid)
                      .collection('wallet_transactions')
                      .orderBy('createdAt', descending: true)
                      .limit(30).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text(ar
                          ? 'تعذر تحميل سجل المحفظة'
                          : 'Wallet history unavailable'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final history = snapshot.data!.docs;
                    if (history.isEmpty) {
                      return Center(child: Text(ar
                          ? 'لا توجد معاملات بعد'
                          : 'No transactions yet'));
                    }
                    return ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final item = history[index].data();
                        return ListTile(
                          dense: true,
                          title: Text((item['type'] ?? '').toString()),
                          subtitle: Text(
                            (item['source'] ?? '').toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            '${item['amount'] ?? 0} ${item['currency'] ?? ''}',
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
      ),
    );
  }
}

/// Stripe is presented only when WorldVoice is opened on the web. Android
/// and iOS must continue through native in_app_purchase.
class _WebCheckoutCatalog extends StatelessWidget {
  const _WebCheckoutCatalog({
    required this.isArabic, required this.store,
  });
  final bool isArabic;
  final RoomCoinPurchaseService store;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('coin_products')
          .where('active', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(isArabic
              ? 'تعذر تحميل باقات الويب'
              : 'Web packs unavailable'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final products = snapshot.data!.docs.map(CoinProductConfig.fromDoc)
            .where((item) => item.hasApprovedWebPrice)
            .toList(growable: false)
          ..sort((a, b) => a.coins.compareTo(b.coins));
        if (products.isEmpty) {
          return Center(child: Text(isArabic
              ? 'لا توجد باقات ويب معتمدة حاليًا.'
              : 'No approved web packs are active.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final product = products[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.credit_card_rounded),
                title: Text(isArabic
                    ? '${product.coins} كوينز' : '${product.coins} Coins'),
                subtitle: Text(
                    '${product.priceUsd!.toStringAsFixed(2)} USD'),
                trailing: FilledButton(
                  onPressed: () async {
                    try {
                      await store.startWebCheckout(product);
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error.toString()
                            .replaceFirst('Bad state: ', ''))),
                      );
                    }
                  },
                  child: Text(isArabic ? 'الدفع الآمن' : 'Secure checkout'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
