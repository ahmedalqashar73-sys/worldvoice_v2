import 'package:flutter/material.dart';

import '../../profile/presentation/world_bond_gift_art.dart';
import '../../profile/presentation/world_bond_screen.dart';

/// A compact entry into the REAL WorldBond flows on every room profile,
/// including the host's own card. Gifts do not use room/Live gift widgets.
class RoomWorldBondSection extends StatefulWidget {
  const RoomWorldBondSection({
    required this.userId,
    required this.isSelf,
    required this.isArabic,
    required this.onOpen,
    this.overviewLoader,
    super.key,
  });

  final String userId;
  final bool isSelf;
  final bool isArabic;
  /// A relationship type, or 'gifts' for the exclusive gift catalog.
  /// Null opens the overview of the user's own relationships.
  final ValueChanged<String?> onOpen;
  final Future<Map<String, dynamic>> Function()? overviewLoader;

  @override
  State<RoomWorldBondSection> createState() => _RoomWorldBondSectionState();
}

class _RoomWorldBondSectionState extends State<RoomWorldBondSection> {
  late Future<Map<String, dynamic>> _overview;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RoomWorldBondSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId ||
        widget.isSelf != oldWidget.isSelf ||
        widget.overviewLoader != oldWidget.overviewLoader) {
      _load();
    }
  }

  void _load() {
    _overview = widget.overviewLoader?.call() ??
        WorldBondApi.request('world-bond/overview' +
            (widget.isSelf ? '' :
                '?peerId=${Uri.encodeQueryComponent(widget.userId)}'));
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.isArabic;
    const gold = Color(0xFFFFD78D);
    const pale = Color(0xFFDDF7EB);
    const dark = Color(0xFF0F2F29);
    const kinds = <(String, String, String, IconData)>[
      ('learning', 'رفيق التعلّم', 'Learning companion', Icons.menu_book_rounded),
      ('language', 'رفيق اللغة', 'Language partner', Icons.translate_rounded),
      ('friend', 'صديق مميز', 'Close friend', Icons.handshake_rounded),
      ('duo', 'ثنائي WorldVoice', 'WorldVoice duo', Icons.favorite_rounded),
    ];
    const gifts = <(int, String, String, int)>[
      (1, 'وعد الزمرد', 'Emerald Promise', 100),
      (2, 'جسر الصداقة الذهبي', 'Golden Bridge', 200),
      (3, 'انسجام الكريستال', 'Crystal Harmony', 500),
      (4, 'رابطة التاج الملكي', 'Royal Bond', 1000),
    ];
    return Container(
      key: const ValueKey('room-worldbond-section'),
      decoration: BoxDecoration(
        color: dark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withValues(alpha: .38)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            const Icon(Icons.diversity_2_rounded, color: gold),
            const SizedBox(width: 8),
            Expanded(child: Text(
              ar ? 'WorldBond • روابط مميزة' : 'WorldBond • Special connections',
              style: const TextStyle(
                color: gold, fontWeight: FontWeight.w800, fontSize: 15),
            )),
            TextButton(
              onPressed: () => widget.onOpen(null),
              child: Text(ar ? 'عرض الكل' : 'See all',
                style: const TextStyle(color: pale)),
            ),
          ]),
          const SizedBox(height: 4),
          FutureBuilder<Map<String, dynamic>>(
            future: _overview,
            builder: (context, snapshot) {
              final records = (snapshot.data?['bonds'] as List? ?? const [])
                  .whereType<Map>().toList(growable: false);
              String status(String type) {
                final matches = records.where((item) =>
                    item['type'] == type &&
                    (widget.isSelf ||
                        (item['members'] is List &&
                         (item['members'] as List).contains(widget.userId))));
                if (matches.any((item) => item['status'] == 'active')) {
                  return ar ? 'علاقة نشطة' : 'Active';
                }
                if (matches.any((item) => item['status'] == 'pending')) {
                  return ar ? 'بانتظار القبول' : 'Pending';
                }
                if (snapshot.hasError) return ar ? 'تحقق من الاتصال' : 'Offline';
                if (!snapshot.hasData) return ar ? 'جارٍ التحميل' : 'Loading';
                return widget.isSelf
                    ? (ar ? 'روابطي' : 'My connections')
                    : (ar ? 'إرسال دعوة' : 'Invite');
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final tileWidth = (constraints.maxWidth - 8) / 2;
                  return Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      for (final kind in kinds)
                        SizedBox(
                          width: tileWidth,
                          child: Material(
                            color: const Color(0xFF165340),
                            borderRadius: BorderRadius.circular(13),
                            child: InkWell(
                              key: ValueKey('room-worldbond-${kind.$1}'),
                              borderRadius: BorderRadius.circular(13),
                              onTap: () => widget.onOpen(kind.$1),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 12),
                                child: Column(children: [
                                  Icon(kind.$4, color: gold, size: 22),
                                  const SizedBox(height: 5),
                                  Text(ar ? kind.$2 : kind.$3,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white, fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 3),
                                  Text(status(kind.$1), maxLines: 1,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: pale, fontSize: 10)),
                                ]),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 14),
          Row(children: [
            const Icon(Icons.redeem_rounded, color: gold, size: 20),
            const SizedBox(width: 6),
            Expanded(child: Text(
              ar ? 'هدايا WorldBond الخاصة' : 'WorldBond exclusive gifts',
              style: const TextStyle(
                color: gold, fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            ar
                ? 'هدايا مستقلة تمامًا عن الروم واللايف. الإهداء بعد قبول العلاقة فقط.'
                : 'Separate from room and Live gifts. Sending requires an accepted bond.',
            style: const TextStyle(color: pale, fontSize: 11)),
          const SizedBox(height: 9),
          LayoutBuilder(builder: (context, constraints) {
            final tileWidth = (constraints.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                for (final gift in gifts)
                  SizedBox(
                    width: tileWidth,
                    child: Material(
                      color: const Color(0xFF184739),
                      borderRadius: BorderRadius.circular(13),
                      child: InkWell(
                        key: ValueKey('room-worldbond-gift-${gift.$1}'),
                        onTap: () => widget.onOpen('gifts'),
                        borderRadius: BorderRadius.circular(13),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 9, horizontal: 5),
                          child: Column(children: [
                            WorldBondGiftArt(level: gift.$1, size: 54),
                            const SizedBox(height: 4),
                            Text(ar ? gift.$2 : gift.$3,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white, fontSize: 11)),
                            Text('LV ${gift.$1} • ${gift.$4} ${ar ? 'كوين' : 'coins'}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: gold, fontSize: 11,
                                fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
          if (widget.isSelf)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                ar ? 'هذه هدايا للآخرين؛ لا يمكنك إهداء نفسك.'
                   : 'These are gifts for others. You cannot gift yourself.',
                style: const TextStyle(color: pale, fontSize: 11),
              ),
            ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey('room-worldbond-open-full'),
              onPressed: () => widget.onOpen(widget.isSelf ? null : 'gifts'),
              style: OutlinedButton.styleFrom(
                foregroundColor: gold,
                side: const BorderSide(color: gold),
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(ar ? 'فتح WorldBond بالكامل' : 'Open full WorldBond'),
            ),
          ),
        ],
      ),
    );
  }
}
