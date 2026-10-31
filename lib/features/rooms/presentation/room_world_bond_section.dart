import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../profile/presentation/world_bond_gift_art.dart';
import '../../profile/presentation/world_bond_level_badge.dart';
import '../../profile/presentation/world_bond_screen.dart';

/// Room-card-only preview. The gallery and payment confirmation open on the
/// existing WorldBond page; the room, Live, and global app theme are unchanged.
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
    final query = widget.isSelf
        ? ''
        : '?peerId=${Uri.encodeQueryComponent(widget.userId)}';
    _overview = widget.overviewLoader?.call() ??
        WorldBondApi.request('world-bond/overview$query');
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.isArabic;
    const gold = Color(0xFFFFD991);
    const pale = Color(0xFFDFF7EE);
    const teal = Color(0xFF164A3F);
    const kinds = <(String, String, String, IconData, Color)>[
      ('learning', 'رفيق التعلّم', 'Learning companion',
        Icons.menu_book_rounded, Color(0xFF24B88E)),
      ('language', 'رفيق اللغة', 'Language partner',
        Icons.translate_rounded, Color(0xFF46BEDB)),
      ('friend', 'صديق مميز', 'Close friend',
        Icons.handshake_rounded, Color(0xFFBD8AF2)),
      ('duo', 'ثنائي WorldVoice', 'WorldVoice duo',
        Icons.favorite_rounded, Color(0xFFF4CA7F)),
    ];
    const gifts = <(int, int)>[(1, 100), (2, 200), (3, 500), (4, 1000)];

    return Container(
      key: const ValueKey('room-worldbond-section'),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF184F41), Color(0xFF092B29), Color(0xFF163F3D)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withValues(alpha: .5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const Icon(Icons.diversity_2_rounded, color: gold, size: 22),
            const SizedBox(width: 7),
            Expanded(child: Text(
              ar ? 'WorldBond • العلاقات المميزة'
                 : 'WorldBond • Special connections',
              style: const TextStyle(color: gold,
                fontSize: 14, fontWeight: FontWeight.w900),
            )),
            TextButton(
              onPressed: () => widget.onOpen(null),
              child: Text(ar ? 'التفاصيل' : 'Details',
                style: const TextStyle(color: pale)),
            ),
          ]),
          FutureBuilder<Map<String, dynamic>>(
            future: _overview,
            builder: (context, snapshot) {
              final records = (snapshot.data?['bonds'] as List? ?? const [])
                  .whereType<Map>().toList(growable: false);
              final myself = Firebase.apps.isNotEmpty
                  ? FirebaseAuth.instance.currentUser?.uid : null;
              Map? matching(String type) {
                Map? pending;
                for (final entry in records) {
                  if (entry['type'] != type ||
                      (!widget.isSelf &&
                       ((entry['members'] as List?)?.contains(widget.userId)
                           != true))) {
                    continue;
                  }
                  if (entry['status'] == 'active') return entry;
                  if (entry['status'] == 'pending') pending = entry;
                }
                return pending;
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final tileWidth = (constraints.maxWidth - 9) / 2;
                  return Wrap(
                    spacing: 9, runSpacing: 9,
                    children: [
                      for (final kind in kinds)
                        SizedBox(
                          width: tileWidth,
                          child: Builder(builder: (context) {
                            final relation = matching(kind.$1);
                            final status = relation?['status'];
                            final level = (relation?['level'] as num?)?.toInt() ?? 1;
                            final members = relation?['members'] as List?;
                            final partnerId = members == null
                                ? ''
                                : members.map((id) => id.toString())
                                    .firstWhere((id) => id != myself,
                                      orElse: () => '');
                            final isFree = status != 'active' &&
                                status != 'pending';
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                key: ValueKey('room-worldbond-${kind.$1}'),
                                onTap: () => widget.onOpen(kind.$1),
                                borderRadius: BorderRadius.circular(16),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      kind.$5.withValues(alpha: .27),
                                      teal,
                                    ]),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: kind.$5.withValues(alpha: .5)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 12),
                                    child: Column(children: [
                                      if (isFree)
                                        Align(
                                          alignment: AlignmentDirectional.topEnd,
                                          child: const Icon(
                                            Icons.add_circle_rounded,
                                            size: 20, color: Color(0xFFFF5C71)),
                                        ),
                                      if (status == 'active' && partnerId.isNotEmpty)
                                        _RoomBondPartnerAvatar(
                                          partnerId: partnerId, tint: kind.$5)
                                      else
                                        Icon(kind.$4, size: 26, color: kind.$5),
                                      const SizedBox(height: 6),
                                      Text(ar ? kind.$2 : kind.$3,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12, fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 6),
                                      if (status == 'active')
                                        WorldBondLevelBadge(level: level,
                                          compact: true, isArabic: ar)
                                      else
                                        Text(
                                          status == 'pending'
                                              ? (ar ? 'بانتظار القبول' : 'Pending')
                                              : snapshot.hasError
                                                  ? (ar ? 'تحقق من الاتصال' : 'Offline')
                                                  : !snapshot.hasData
                                                      ? (ar ? 'جارٍ التحميل' : 'Loading')
                                                      : widget.isSelf
                                                          ? (ar ? 'روابطي' : 'My bonds')
                                                          : (ar ? 'إرسال دعوة' : 'Invite'),
                                          maxLines: 1,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: pale, fontSize: 10)),
                                    ]),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.redeem_rounded, color: gold, size: 20),
            const SizedBox(width: 7),
            Expanded(child: Text(
              ar ? 'هدايا WorldBond الحصرية' : 'Exclusive WorldBond gifts',
              style: const TextStyle(
                color: gold, fontWeight: FontWeight.w800, fontSize: 13)),
            ),
            IconButton(
              tooltip: ar ? 'معرض الهدايا' : 'Gift gallery',
              onPressed: () => widget.onOpen(widget.isSelf ? null : 'gifts'),
              icon: const Icon(Icons.chevron_left_rounded, color: gold),
            ),
          ]),
          Text(
            ar ? 'اضغط على رفيق التعلّم أو أي علاقة لفتح هداياها وشاراتها.'
               : 'Open any connection to view its gift gallery and badges.',
            style: const TextStyle(fontSize: 11, color: pale)),
          const SizedBox(height: 8),
          // Compact previews only. The full gallery stays behind a tap.
          LayoutBuilder(builder: (context, constraints) {
            final tileWidth = (constraints.maxWidth - 18) / 4;
            return Wrap(
              spacing: 6, runSpacing: 6,
              children: [
                for (final gift in gifts)
                  SizedBox(
                    width: tileWidth,
                    child: Material(
                      color: const Color(0xFF1C463E),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        key: ValueKey('room-worldbond-gift-${gift.$1}'),
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => widget.onOpen(widget.isSelf ? null : 'gifts'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2, vertical: 7),
                          child: Column(children: [
                            WorldBondGiftArt(level: gift.$1, size: 44),
                            const SizedBox(height: 3),
                            Text('LV${gift.$1}',
                              style: const TextStyle(
                                color: gold, fontWeight: FontWeight.w900,
                                fontSize: 10)),
                            Text('${gift.$2} ${ar ? 'كوين' : 'coins'}',
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: pale, fontSize: 9)),
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
                ar ? 'للعرض فقط؛ لا يمكن إرسال هدية لنفسك.'
                   : 'Preview only; you cannot gift yourself.',
                style: const TextStyle(color: pale, fontSize: 11),
              ),
            ),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey('room-worldbond-open-full'),
              onPressed: () => widget.onOpen(widget.isSelf ? null : 'gifts'),
              style: OutlinedButton.styleFrom(
                foregroundColor: gold,
                side: const BorderSide(color: gold),
              ),
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(ar ? 'فتح معرض العلاقات والهدايا'
                  : 'Explore bonds and gifts'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomBondPartnerAvatar extends StatelessWidget {
  const _RoomBondPartnerAvatar({
    required this.partnerId, required this.tint,
  });
  final String partnerId;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      return CircleAvatar(radius: 17, backgroundColor: tint,
        child: const Icon(Icons.person_rounded, color: Colors.white, size: 19));
    }
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
        .collection('users').doc(partnerId).get(),
      builder: (context, snapshot) {
        final photo = (snapshot.data?.data()?['photoUrl'] as String?)?.trim();
        return CircleAvatar(
          radius: 17,
          backgroundColor: tint,
          backgroundImage: photo != null && photo.startsWith('https://')
              ? NetworkImage(photo) : null,
          child: photo == null || !photo.startsWith('https://')
              ? const Icon(Icons.person_rounded, color: Colors.white, size: 19)
              : null,
        );
      },
    );
  }
}
