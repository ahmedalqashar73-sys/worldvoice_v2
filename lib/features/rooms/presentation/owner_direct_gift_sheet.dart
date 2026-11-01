import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/classic_gift_catalog.dart';
import '../data/room_feature_models.dart';
import '../services/room_shop_service.dart';
import 'store_gift_options.dart';

/// Owner-only direct gifting of the existing, unmodified WorldVoice catalog.
class OwnerDirectGiftSheet extends StatefulWidget {
  const OwnerDirectGiftSheet({super.key});

  @override
  State<OwnerDirectGiftSheet> createState() => _OwnerDirectGiftSheetState();
}

class _OwnerDirectGiftSheetState extends State<OwnerDirectGiftSheet> {
  final RoomShopService _shop = RoomShopService();
  late final Future<List<RoomGiftCatalogItem>> _catalog =
      _loadPublishedGifts();

  Future<List<RoomGiftCatalogItem>> _loadPublishedGifts() async {
    final previews = await ClassicGiftCatalog.load();
    // Previews deliberately have active:false. Only backend-published gifts
    // may be paid for; preserve the same merge policy as room/live.
    final snapshot = await FirebaseFirestore.instance
        .collection('store_items')
        .where('type', isEqualTo: 'gift').get();
    return ClassicGiftCatalog.merge(
      previews: previews,
      published: snapshot.docs.map(RoomGiftCatalogItem.fromDoc).toList(),
    );
  }
  String _search = '';
  bool _sending = false;

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

  Future<void> _send(RoomGiftCatalogItem item) async {
    if (_sending || !item.active) return;
    final person = await pickStoreGiftRecipient(context, _shop, _ar);
    if (person == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(_ar ? 'تأكيد إرسال الهدية' : 'Confirm gift delivery'),
        content: Text(
          '${_ar ? (item.nameAr ?? item.name) : item.name}\n'
          '${person.displayName} • ${person.username.isNotEmpty ? '@${person.username}' : person.uid}\n'
          '${item.priceCoins} 🪙\n'
          '${_ar ? 'ستصل الهدية فورًا إلى سجل هداياه دون قبول.' : 'The gift will arrive immediately in their received gifts, without acceptance.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(_ar ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(_ar ? 'إرسال' : 'Send'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _sending = true);
    try {
      await _shop.sendOwnerDirectGift(
        giftId: item.id, recipientId: person.uid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_ar
            ? 'تم تسليم الهدية إلى المستلم وخصم سعرها.'
            : 'Gift delivered and catalog coins charged.'),
      ));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.toString().replaceFirst('Bad state: ', '')),
      ));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .83,
      child: Column(children: [
        ListTile(
          title: Text(_ar ? 'إهداء هدايا WorldVoice' : 'Gift WorldVoice items',
            style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(_ar
              ? 'كتالوج الهدايا الأصلي • إهداء مباشر للمالك'
              : 'Existing gift catalog • Owner direct delivery'),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: _ar ? 'ابحث عن الهدية' : 'Find a gift',
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _search = value.trim().toLowerCase()),
          ),
        ),
        if (_sending) const LinearProgressIndicator(),
        Expanded(
          child: FutureBuilder<List<RoomGiftCatalogItem>>(
            future: _catalog,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text(_ar
                    ? 'تعذر قراءة كتالوج الهدايا'
                    : 'Unable to load gift catalog'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final visible = snapshot.data!.where((item) {
                final q = _search;
                return q.isEmpty || item.name.toLowerCase().contains(q) ||
                    (item.nameAr ?? '').toLowerCase().contains(q) ||
                    item.id.toLowerCase().contains(q);
              }).toList();
              return ListView.builder(
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final item = visible[index];
                  return ListTile(
                    leading: SizedBox(
                      width: 48,
                      height: 48,
                      child: Image.asset(
                        'assets/gifts/hd/${item.id}.webp',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Center(
                          child: Text(item.emoji ?? '🎁',
                            style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                    ),
                    title: Text(_ar ? (item.nameAr ?? item.name) : item.name),
                    subtitle: Text('${item.priceCoins} 🪙'),
                    trailing: FilledButton.tonal(
                      onPressed: _sending || !item.active ? null : () => _send(item),
                      child: Text(_ar ? 'إهداء' : 'Gift'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    ),
  );
}
