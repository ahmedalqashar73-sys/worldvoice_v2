import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/room_coin_purchase_service.dart';

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
    _store.initialize();
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
              trailing: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
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
              child: _store.loading
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
