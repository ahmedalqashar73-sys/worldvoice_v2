import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/room_coin_purchase_service.dart';
import '../data/coin_product_config.dart';

const _storeInk = Color(0xFF092920);
const _storeJade = Color(0xFF12654B);
const _storeGold = Color(0xFFF4D58B);

/// The existing WorldVoice coin store: local products are display-only
/// unless the native store returns a real purchasable SKU and the backend
/// verifies the current finance policy at purchase time.
class RoomCoinStoreSheet extends StatefulWidget {
  const RoomCoinStoreSheet({super.key});

  @override
  State<RoomCoinStoreSheet> createState() => _RoomCoinStoreSheetState();
}

class _RoomCoinStoreSheetState extends State<RoomCoinStoreSheet> {
  final RoomCoinPurchaseService _store = RoomCoinPurchaseService.instance;

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

  Widget _coinMedallion({double dimension = 50}) => Container(
    width: dimension,
    height: dimension,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [
        Color(0xFFFFF1BE), Color(0xFFF1C466),
        Color(0xFFA7732D), Color(0xFFFAE7A0),
      ], stops: [0, .42, .82, 1]),
      boxShadow: [
        BoxShadow(color: Color(0x6630C38A), blurRadius: 18),
      ],
    ),
    child: Icon(Icons.auto_awesome_rounded,
      color: const Color(0xFF98672B), size: dimension * .44),
  );

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final user = FirebaseAuth.instance.currentUser;
    final paymentMethod = kIsWeb
        ? (ar ? 'Visa / Mastercard • الويب الآمن'
              : 'Visa / Mastercard • secure web')
        : defaultTargetPlatform == TargetPlatform.iOS
            ? (ar ? 'الدفع عبر App Store' : 'Apple App Store billing')
            : (ar ? 'الدفع عبر Google Play' : 'Google Play billing');

    return SafeArea(
      child: Container(
        height: MediaQuery.sizeOf(context).height * .84,
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_storeInk, Color(0xFF144C39), Color(0xFF0C2923)]),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(children: [
              _coinMedallion(dimension: 45),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ar ? 'متجر WorldVoice الملكي' : 'WorldVoice Royal Store',
                    style: const TextStyle(color: Colors.white,
                      fontSize: 20, fontWeight: FontWeight.w900)),
                  Text(ar ? 'كوينز • هدايا • محفظة'
                          : 'Coins • Gifts • Wallet',
                    style: const TextStyle(color: _storeGold,
                      fontWeight: FontWeight.w600, fontSize: 12)),
                ],
              )),
              IconButton(
                tooltip: ar ? 'محفظتي' : 'My wallet',
                color: _storeGold,
                icon: const Icon(Icons.account_balance_wallet_outlined),
                onPressed: user == null ? null : () {
                  showModalBottomSheet<void>(
                    context: context, isScrollControlled: true,
                    builder: (_) => const _WalletView());
                },
              ),
              IconButton(
                color: Colors.white70,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withValues(alpha: .065),
                border: Border.all(color: _storeGold.withValues(alpha: .32)),
              ),
              child: Row(children: [
                const Icon(Icons.account_balance_wallet_rounded,
                    color: _storeGold, size: 25),
                const SizedBox(width: 12),
                Expanded(child: StreamBuilder<
                    DocumentSnapshot<Map<String, dynamic>>>(
                  stream: user == null ? null : _store.watchMyWallet(),
                  builder: (context, snapshot) {
                    final available = snapshot.data?.exists == true
                        && !snapshot.hasError;
                    final balance = available
                        ? (snapshot.data!.data()?['coins'] as num?)?.toInt()
                        : null;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ar ? 'رصيدك من العملات' : 'Your coin balance',
                          style: const TextStyle(color: Colors.white70,
                              fontSize: 12)),
                        Text(balance == null ? '—' : '$balance',
                          style: const TextStyle(color: _storeGold,
                              fontSize: 23, fontWeight: FontWeight.w900)),
                      ],
                    );
                  },
                )),
                const Icon(Icons.verified_user_outlined,
                    color: Color(0xFF9DE3B5), size: 21),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 1, 18, 9),
            child: Row(children: [
              Icon(kIsWeb ? Icons.credit_card_outlined
                       : Icons.shopping_bag_outlined,
                   color: _storeGold, size: 19),
              const SizedBox(width: 8),
              Expanded(child: Text(paymentMethod,
                style: const TextStyle(color: Color(0xFFE4F5E9),
                  fontSize: 12, fontWeight: FontWeight.w700))),
              if (!kIsWeb)
                const Icon(Icons.lock_outline_rounded,
                  size: 17, color: Color(0xFF9DE3B5)),
            ]),
          ),
          if (_store.message?.trim().isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(_store.message!,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFFFE0A7),
                    fontSize: 11)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 2, 18, 7),
            child: Row(children: [
              Expanded(child: Text(ar ? 'اختر باقة الكوينز'
                                     : 'Choose your coin pack',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w900, fontSize: 16))),
              Text(ar ? '7 باقات' : '7 pack sizes',
                style: const TextStyle(color: _storeGold, fontSize: 12)),
            ]),
          ),
          Expanded(
            child: kIsWeb
                ? _WebCheckoutCatalog(isArabic: ar, store: _store)
                : _store.loading
                    ? const Center(child: CircularProgressIndicator(
                        color: _storeGold))
                    : _store.products.isEmpty
                        ? _PlannedCoinPacks(ar: ar)
                        : RefreshIndicator(
                            color: _storeJade,
                            onRefresh: _store.refreshProducts,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 8, 16, 28),
                              itemCount: CoinProductConfig.proposedPackSizes.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final amount =
                                    CoinProductConfig.proposedPackSizes[index];
                                CoinStoreProduct? item;
                                for (final available in _store.products) {
                                  if (available.config.coins == amount) {
                                    item = available;
                                    break;
                                  }
                                }
                                final approved = item;
                                return _PremiumCoinPack(
                                  amount: amount,
                                  subtitle: approved?.product.title ??
                                      (ar ? 'قيد اعتماد المتجر' :
                                         'Pending store approval'),
                                  buttonLabel: approved?.product.price ??
                                      (ar ? 'قريبًا' : 'Soon'),
                                  enabled: approved != null,
                                  onBuy: approved == null ? null :
                                      () => _store.buy(approved));
                              },
                            ),
                          ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
            child: Text(kIsWeb
                ? (ar
                    ? 'الدفع بالبطاقات فقط بعد تفعيل حساب Stripe والتحقق المالي.'
                    : 'Card payments require an active verified Stripe merchant.')
                : (ar
                    ? 'السعر النهائي وطريقة الدفع يحددهما متجر جهازك؛ لن تُخصم أموال في وضع المعاينة.'
                    : 'Your platform store confirms prices and payment methods. Preview never charges.'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFBAD1C7), fontSize: 10)),
          ),
        ]),
      ),
    );
  }
}

/// Never show hardcoded money prices or a fake working checkout.
class _PlannedCoinPacks extends StatelessWidget {
  const _PlannedCoinPacks({required this.ar});
  final bool ar;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 7, 16, 25),
    itemCount: CoinProductConfig.proposedPackSizes.length,
    separatorBuilder: (_, _) => const SizedBox(height: 8),
    itemBuilder: (context, index) => _PremiumCoinPack(
      amount: CoinProductConfig.proposedPackSizes[index],
      subtitle: ar ? 'الباقة قيد الإعداد'
                   : 'Pending store approval',
      buttonLabel: ar ? 'قريبًا' : 'Soon',
      enabled: false),
  );
}

class _PremiumCoinPack extends StatelessWidget {
  const _PremiumCoinPack({
    required this.amount, required this.subtitle,
    required this.buttonLabel, required this.enabled,
    this.onBuy,
  });
  final int amount;
  final String subtitle;
  final String buttonLabel;
  final bool enabled;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [
          Color(0xFF19503D), Color(0xFF10392F),
        ]),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color:
          _storeGold.withValues(alpha: enabled ? .62 : .27)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 5),
        leading: Container(
          height: 45, width: 45,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(colors: [
              Color(0xFFFFECAF), Color(0xFFE7AD4F), Color(0xFFB87B36)]),
            boxShadow: [
              BoxShadow(color: _storeGold.withValues(alpha: .22),
                blurRadius: 13),
            ],
          ),
          child: const Icon(Icons.stars_rounded,
              color: Color(0xFF8E5B20), size: 26)),
        title: Text('$amount  🪙',
          style: const TextStyle(color: Colors.white,
              fontWeight: FontWeight.w900, fontSize: 19)),
        subtitle: Text(subtitle, maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFFB8D4C7),
            fontSize: 11)),
        trailing: FilledButton(
          onPressed: enabled ? onBuy : null,
          style: FilledButton.styleFrom(
            backgroundColor: _storeGold,
            foregroundColor: const Color(0xFF214536),
            disabledBackgroundColor: const Color(0xFF31594A),
            disabledForegroundColor: const Color(0xFFBDCEBE),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
          child: Text(buttonLabel,
            style: const TextStyle(fontWeight: FontWeight.w900)),
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
                stream: _service.watchMyWallet(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data() ?? <String, dynamic>{};
                  if (snapshot.hasError ||
                      snapshot.data?.exists != true) {
                    return Text(ar
                        ? 'يلزم تجهيز محفظتك الخاصة قبل استخدام الميزات المالية.'
                        : 'Your private wallet must be prepared before using financial features.');
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
                  if (policy?['enabled'] != true ||
                      policy?['privateWalletCutoverVerified'] != true ||
                      policy?['publicProfileRulesVerified'] != true) {
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
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.doc('economy_config/current')
          .snapshots(),
      builder: (context, policySnapshot) {
        final policy = policySnapshot.data?.data();
        final economyReady = policy?['enabled'] == true &&
            policy?['privateWalletCutoverVerified'] == true &&
            policy?['publicProfileRulesVerified'] == true;
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
          return _PlannedCoinPacks(ar: isArabic);
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: CoinProductConfig.proposedPackSizes.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final amount = CoinProductConfig.proposedPackSizes[index];
            CoinProductConfig? product;
            for (final candidate in products) {
              if (candidate.coins == amount) {
                product = candidate;
                break;
              }
            }
            final approved = product;
            return _PremiumCoinPack(
              amount: amount,
              subtitle: approved == null
                ? (isArabic ? 'قيد اعتماد السعر' : 'Price approval pending')
                : '${approved.priceUsd!.toStringAsFixed(2)} USD • Visa / Mastercard',
              buttonLabel: !economyReady
                ? (isArabic ? 'بانتظار التفعيل' : 'Pending')
                : approved == null
                    ? (isArabic ? 'قريبًا' : 'Soon')
                    : (isArabic ? 'الدفع الآمن' : 'Secure checkout'),
              enabled: approved != null && economyReady,
              onBuy: approved == null || !economyReady ? null : () async {
                try {
                  await store.startWebCheckout(approved);
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.toString()
                        .replaceFirst('Bad state: ', ''))),
                  );
                }
              },
            );
          },
        );
      },
    );
      },
    );
  }
}
