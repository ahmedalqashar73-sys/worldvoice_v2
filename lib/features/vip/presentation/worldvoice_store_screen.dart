import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/vip/vip_entitlement.dart';
import '../../rooms/data/room_shop_models.dart';
import '../../rooms/presentation/room_coin_store_sheet.dart';
import '../../rooms/services/room_shop_service.dart';
import '../vip_membership_screen.dart';
import 'worldvoice_vip_badge.dart';

/// A single WorldVoice storefront for membership, VIP badges, and cosmetics.
/// Monetary checkout always uses Google Play / App Store in the existing
/// native coin shop; cosmetic coin debits are authorized by the backend.
class WorldVoiceStoreScreen extends StatefulWidget {
  const WorldVoiceStoreScreen({required this.languageCode, super.key});

  final String languageCode;

  @override
  State<WorldVoiceStoreScreen> createState() => _WorldVoiceStoreScreenState();
}

class _WorldVoiceStoreScreenState extends State<WorldVoiceStoreScreen> {
  final RoomShopService _shop = RoomShopService();
  bool _busy = false;

  bool get _ar => widget.languageCode == 'ar';

  void _openCoins() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const RoomCoinStoreSheet(),
    );
  }

  Future<void> _equip(String? id) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _shop.equipVipBadge(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_ar ? 'تم تحديث الشارة بنجاح' : 'VIP badge updated'),
      ));
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _buy(RoomStoreItem item) async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_ar ? 'تأكيد الشراء' : 'Confirm purchase'),
        content: Text(_ar
            ? 'شراء ${item.name} مقابل ${item.priceCoins} عملة؟'
            : 'Buy ${item.name} for ${item.priceCoins} coins?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_ar ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_ar ? 'شراء' : 'Buy'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await _shop.purchaseItem(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_ar ? 'تم الشراء بنجاح' : 'Purchase complete')),
      );
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(Object error) {
    final message = error.toString();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message.contains('NOT_ENOUGH_COINS')
          ? (_ar ? 'رصيد العملات غير كافٍ.' : 'Not enough coins.')
          : message.contains('VIP_REQUIRED')
              ? (_ar ? 'هذه الزينة لأعضاء VIP فقط.' : 'VIP membership required.')
              : (_ar ? 'تعذّر تنفيذ العملية. حاول مجددًا.'
                  : 'Could not complete the action. Try again.')),
      action: message.contains('NOT_ENOUGH_COINS')
          ? SnackBarAction(
              label: _ar ? 'المتجر' : 'Coins',
              onPressed: _openCoins,
            )
          : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_ar ? 'متجر WorldVoice' : 'WorldVoice Store'),
          actions: [
            IconButton(
              tooltip: _ar ? 'شراء العملات' : 'Get coins',
              icon: const Icon(Icons.monetization_on_outlined),
              onPressed: _openCoins,
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: _ar ? 'عضوية VIP' : 'VIP Gold'),
              Tab(text: _ar ? 'الشارات' : 'VIP Badges'),
              Tab(text: _ar ? 'الإطارات' : 'Frames'),
              Tab(text: _ar ? 'الخلفيات' : 'Backgrounds'),
            ],
          ),
        ),
        body: uid == null
            ? Center(child: Text(_ar ? 'يرجى تسجيل الدخول.' : 'Sign in first.'))
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users').doc(uid).snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final profile = snap.data?.data();
                  final vip = VipEntitlement.isActive(profile);
                  final activeId = (profile?['activeBadgeId'] ?? '').toString();
                  final badgeExpiry = profile?['vipBadgeExpiresAt'];
                  final equipped = badgeExpiry is Timestamp &&
                      badgeExpiry.toDate().isAfter(DateTime.now()) &&
                      vip ? activeId : '';
                  return TabBarView(
                    children: [
                      _membershipTab(vip),
                      _badgeTab(vip, equipped),
                      _catalogTab('frame', vip),
                      _catalogTab('background', vip),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _membershipTab(bool isVip) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF105944), Color(0xFF1A8A69)],
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(children: [
            const Icon(Icons.workspace_premium_rounded,
                size: 64, color: Color(0xFFFFD978)),
            const SizedBox(height: 8),
            const Text('WorldVoice VIP Gold',
                style: TextStyle(color: Colors.white,
                    fontSize: 25, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text(
              isVip
                  ? (_ar ? 'عضويتك VIP فعّالة' : 'Your VIP membership is active')
                  : (_ar ? 'عالم أوسع للتعلّم والتواصل'
                      : 'More freedom to learn and connect'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => VipMembershipScreen(
                  languageCode: widget.languageCode,
                ),
              )),
              icon: const Icon(Icons.stars_rounded),
              label: Text(_ar ? 'مزايا وحالة العضوية' : 'Benefits and membership status'),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        _benefit(Icons.timer_outlined,
            _ar ? 'وقت غير محدود' : 'Unlimited time',
            _ar ? 'في الروم واللايف كمضيف أو ضيف' : 'As host or guest in rooms and Live'),
        _benefit(Icons.smart_toy_rounded, 'Teacher AI',
            _ar ? 'حصري للـVIP في الغرف الصوتية' : 'VIP-only in voice rooms'),
        _benefit(Icons.translate_rounded,
            _ar ? 'حتى 10 لغات تعلّم' : 'Up to 10 learning languages',
            _ar ? 'وتصفح الزوار وإخفاء سجل الزيارات'
                : 'Visitor insights and private visits'),
        const SizedBox(height: 12),
        Text(_ar
            ? 'ستظهر الأسعار الحقيقية وخيار الاشتراك عندما تتم الموافقة على منتجات Google Play وApp Store والتحقق الآمن من المشتريات.'
            : 'Native subscription offers will appear once Google Play and App Store products and secure verification are approved.',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _benefit(IconData icon, String label, String info) => Card(
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFF177D5D)),
          title: Text(label),
          subtitle: Text(info),
        ),
      );

  Widget _badgeTab(bool vip, String equipped) {
    return StreamBuilder<List<RoomStoreItem>>(
      stream: _shop.watchStoreItems('badge'),
      builder: (context, products) => StreamBuilder<Set<String>>(
        stream: _shop.watchOwnedItemIds('badge'),
        builder: (context, owned) {
          final approved = <String, RoomStoreItem>{
            for (final item in products.data ?? <RoomStoreItem>[]) item.id: item,
          };
          final ownedIds = owned.data ?? <String>{};
          final width = MediaQuery.sizeOf(context).width;
          final cols = width > 420 ? 3 : 2;
          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              ListTile(
                leading: const Icon(Icons.verified_rounded,
                    color: Color(0xFFC49237)),
                title: Text(_ar ? 'شارات WorldVoice VIP' : 'WorldVoice VIP Badges'),
                subtitle: Text(_ar
                    ? 'شارات خاصة لأعضاء VIP، بمدد 7 أو 15 أو 30 يومًا.'
                    : 'Exclusive 7, 15 or 30-day VIP cosmetics.'),
              ),
              if (!vip)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: Text(_ar ? 'متاح لأعضاء VIP فقط' : 'VIP only'),
                    subtitle: Text(_ar
                        ? 'يمكنك معاينة الشارات أولًا.'
                        : 'You can preview the badge collection.'),
                  ),
                ),
              if (equipped.isNotEmpty)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: _busy ? null : () => _equip(null),
                    icon: const Icon(Icons.visibility_off_outlined),
                    label: Text(_ar ? 'إزالة الشارة الحالية' : 'Unequip badge'),
                  ),
                ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  childAspectRatio: .71,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: WorldVoiceVipBadgeDesign.designs.length,
                itemBuilder: (context, index) {
                  final design = WorldVoiceVipBadgeDesign.designs[index];
                  final product = approved[design.id];
                  final hasIt = ownedIds.contains(design.id);
                  final selected = equipped == design.id;
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(9),
                      child: Column(children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(_ar ? 'جديد' : 'New',
                              style: const TextStyle(
                                color: Color(0xFFB57919),
                                fontSize: 12, fontWeight: FontWeight.w800,
                              )),
                        ),
                        Expanded(
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: WorldVoiceVipBadge(
                                badgeId: design.id,
                                compact: false,
                              ),
                            ),
                          ),
                        ),
                        Text(_ar ? design.nameAr : design.nameEn,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(product == null
                            ? (_ar ? 'قريبًا' : 'Coming soon')
                            : product.priceCoins.toString() +
                                (_ar ? ' عملة • ' : ' coins • ') +
                                (product.durationDays ?? 0).toString() +
                                (_ar ? ' يوم' : ' days'),
                            style: const TextStyle(fontSize: 11)),
                        const SizedBox(height: 5),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonal(
                            onPressed: _busy || !vip || product == null || selected
                                ? null
                                : hasIt
                                    ? () => _equip(design.id)
                                    : () => _buy(product),
                            child: Text(selected
                                ? (_ar ? 'مستخدمة' : 'Equipped')
                                : hasIt
                                    ? (_ar ? 'استخدام' : 'Equip')
                                    : (_ar ? 'شراء' : 'Buy')),
                          ),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _catalogTab(String type, bool vip) {
    return StreamBuilder<List<RoomStoreItem>>(
      stream: _shop.watchStoreItems(type),
      builder: (context, products) => StreamBuilder<Set<String>>(
        stream: _shop.watchOwnedItemIds(type),
        builder: (context, owned) {
          final items = products.data ?? <RoomStoreItem>[];
          if (items.isEmpty) {
            return Center(
              child: Text(_ar
                  ? 'لم يتم تفعيل عناصر هذه الفئة في المتجر بعد.'
                  : 'No approved items are available yet.'),
            );
          }
          final ownedIds = owned.data ?? <String>{};
          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              final hasIt = ownedIds.contains(item.id);
              final durationLabel = item.durationDays == null
                  ? ''
                  : ' • ${item.durationDays} ${_ar ? 'يوم' : 'days'}';
              return Card(
                child: ListTile(
                  leading: Icon(
                    type == 'frame'
                        ? Icons.auto_awesome_rounded
                        : Icons.wallpaper_rounded,
                    color: const Color(0xFF148266),
                  ),
                  title: Text(item.name),
                  subtitle: Text('${item.priceCoins} ${_ar ? 'عملة' : 'coins'}$durationLabel'),
                  trailing: FilledButton.tonal(
                    onPressed: hasIt || _busy
                        ? null : () => _buy(item),
                    child: Text(hasIt
                        ? (_ar ? 'مملوك' : 'Owned')
                        : (_ar ? 'شراء' : 'Buy')),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
