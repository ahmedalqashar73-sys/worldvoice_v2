import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/room_feature_models.dart';
import '../data/room_moderation_models.dart';
import '../services/room_feature_service.dart';

class RoomExtrasSheet extends StatelessWidget {
  const RoomExtrasSheet({
    required this.roomId,
    required this.participants,
    required this.isHost,
    required this.showTeacherAiSeat,
    this.onOpenCoinStore,
    this.initialTab = 0,
    super.key,
  });

  final int initialTab;
  final String roomId;
  final List<RoomParticipant> participants;
  final bool isHost;
  final bool showTeacherAiSeat;
  final VoidCallback? onOpenCoinStore;

  @override
  Widget build(BuildContext context) {
    final service = RoomFeatureService(roomId: roomId);
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .82,
        child: DefaultTabController(
          length: 5,
          initialIndex: initialTab,
          child: Column(
            children: [
              ListTile(
                title: Text(
                  isArabic ? 'مزايا الغرفة' : 'Room features',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                trailing: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: isArabic ? 'الثيم' : 'Theme'),
                  Tab(text: isArabic ? 'المهام' : 'Tasks'),
                  Tab(text: isArabic ? 'الهدايا' : 'Gifts'),
                  Tab(text: isArabic ? 'الترتيب' : 'Leaderboard'),
                  Tab(text: isArabic ? 'المكافآت' : 'Rewards'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _ThemeTab(service: service, isHost: isHost),
                    _TasksTab(service: service),
                    _GiftsTab(
                      service: service,
                      participants: participants,
                      showTeacherAiSeat: showTeacherAiSeat,
                      onOpenCoinStore: onOpenCoinStore,
                    ),
                    _LeaderboardTab(service: service),
                    _RewardsTab(
                      roomId: roomId,
                      isArabic: isArabic,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeTab extends StatelessWidget {
  const _ThemeTab({required this.service, required this.isHost});
  final RoomFeatureService service;
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    const themes = <(String, String, IconData)>[
      ('royalPurple', 'Royal Purple', Icons.auto_awesome_rounded),
      ('emerald', 'Emerald', Icons.eco_rounded),
      ('midnight', 'Midnight', Icons.nights_stay_rounded),
    ];
    return StreamBuilder<RoomFeatureState>(
      stream: service.watchState(),
      builder: (context, snapshot) {
        final selected = snapshot.data?.themeId ?? 'royalPurple';
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final theme in themes)
              Card(
                child: ListTile(
                  enabled: isHost,
                  onTap: isHost ? () => service.setTheme(theme.$1) : null,
                  leading: Icon(theme.$3),
                  title: Text(theme.$2),
                  trailing: selected == theme.$1
                      ? const Icon(Icons.check_circle_rounded)
                      : const Icon(Icons.circle_outlined),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TasksTab extends StatelessWidget {
  const _TasksTab({required this.service});
  final RoomFeatureService service;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final day = '${now.year}-${now.month}-${now.day}';
    final week = '${now.year}-W${((now.difference(DateTime(now.year)).inDays) ~/ 7) + 1}';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _TaskTile(
          title: 'Join the room conversation',
          points: 10,
          onComplete: () => service.completeTask(
            taskKey: 'daily_join',
            points: 10,
            periodKey: day,
          ),
        ),
        _TaskTile(
          title: 'Practice speaking',
          points: 20,
          onComplete: () => service.completeTask(
            taskKey: 'daily_speaking',
            points: 20,
            periodKey: day,
          ),
        ),
        _TaskTile(
          title: 'Weekly room participation',
          points: 50,
          onComplete: () => service.completeTask(
            taskKey: 'weekly_participation',
            points: 50,
            periodKey: week,
          ),
        ),
      ],
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.title,
    required this.points,
    required this.onComplete,
  });
  final String title;
  final int points;
  final Future<void> Function() onComplete;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: const Icon(Icons.task_alt_rounded),
          title: Text(title),
          subtitle: Text('+$points XP'),
          trailing: FilledButton(
            onPressed: () async {
              try {
                await onComplete();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task completed.')),
                );
              } catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(error.toString())));
              }
            },
            child: const Text('Complete'),
          ),
        ),
      );
}

class _GiftsTab extends StatefulWidget {
  const _GiftsTab({required this.service, required this.participants,
    required this.showTeacherAiSeat, this.onOpenCoinStore});
  final RoomFeatureService service;
  final List<RoomParticipant> participants;
  final bool showTeacherAiSeat;
  final VoidCallback? onOpenCoinStore;
  @override
  State<_GiftsTab> createState() => _GiftsTabState();
}

class _GiftsTabState extends State<_GiftsTab> {
  late final _catalog = widget.service.watchGiftCatalog();
  String? _recipient;
  RoomGiftCatalogItem? _gift;
  bool _sending = false;
  int _category = 0;

  Future<void> _send(String name, bool ar) async {
    final gift = _gift;
    final recipient = _recipient;
    if (gift == null || recipient == null || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.service.sendGift(recipientId: recipient,
        recipientName: name, giftId: gift.id, points: gift.priceCoins);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ar ? 'تم إرسال الهدية' : 'Gift sent')));
    } catch (error) {
      if (!mounted) return;
      final insufficient = error.toString().contains('NOT_ENOUGH_COINS');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(insufficient
        ? (ar ? 'رصيد العملات غير كافٍ' : 'Not enough coins')
        : (ar ? 'تعذر إرسال الهدية، حاول مجددًا' : 'Could not send gift. Please retry.'))));
      if (insufficient) widget.onOpenCoinStore?.call();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final targets = <String, String>{
      for (final p in widget.participants.where((p) => p.isOnStage && p.userId != uid))
        p.userId: p.displayName,
      if (widget.showTeacherAiSeat) 'teacher_ai': 'Teacher AI',
    };
    return StreamBuilder<List<RoomGiftCatalogItem>>(
      stream: _catalog,
      builder: (context, snapshot) {
        final gifts = snapshot.data ?? const <RoomGiftCatalogItem>[];
        final filtered = gifts.where((g) => switch (_category) {
          1 => g.priceCoins <= 50,
          2 => g.priceCoins > 50 && g.priceCoins <= 150,
          3 => g.priceCoins > 150 && g.priceCoins <= 500,
          4 => g.priceCoins > 500,
          _ => true,
        }).toList();
        final canSend = !_sending && targets.containsKey(_recipient) &&
          _gift != null && gifts.any((g) => g.id == _gift!.id);
        return Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(ar ? 'اختر المستلم' : 'Choose recipient',
              style: const TextStyle(fontWeight: FontWeight.bold)))),
          SizedBox(height: 58, child: targets.isEmpty
            ? Center(child: Text(ar ? 'ادعُ شخصًا إلى المنصة لإرسال هدية' : 'Invite someone onto the stage to send a gift'))
            : ListView(padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal, children: targets.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4), child: ChoiceChip(
                  avatar: const Icon(Icons.person_rounded, size: 18),
                  label: Text(e.value), selected: _recipient == e.key,
                  onSelected: _sending ? null : (_) => setState(() => _recipient = e.key),
                ))).toList())),
          SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12), children: [
              for (final (index, label) in [(0, ar ? 'الكل' : 'All'), (1, '1–50'),
                (2, '51–150'), (3, '151–500'), (4, '501+')])
                Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: ChoiceChip(
                  label: Text(label), selected: _category == index,
                  onSelected: (_) => setState(() => _category = index))),
            ])),
          Expanded(child: snapshot.hasError
            ? Center(child: Text(ar ? 'تعذر تحميل الهدايا' : 'Could not load gifts'))
            : snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                ? Center(child: Text(ar ? 'لا توجد هدايا في هذه الفئة' : 'No gifts in this category'))
                : GridView.builder(padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.sizeOf(context).width < 350 ? 3 : 4,
                    mainAxisExtent: 118 + MediaQuery.textScalerOf(context).scale(24),
                    mainAxisSpacing: 8, crossAxisSpacing: 8),
                  itemCount: filtered.length, itemBuilder: (context, index) {
                    final gift = filtered[index];
                    return Material(color: _gift?.id == gift.id
                      ? const Color(0xFF51408A) : Colors.white.withValues(alpha: .06),
                      borderRadius: BorderRadius.circular(18), child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: _sending ? null : () => setState(() => _gift = gift),
                        child: Padding(padding: const EdgeInsets.all(8), child: Column(
                          mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(gift.emoji?.isNotEmpty == true ? gift.emoji! : '🎁', style: const TextStyle(fontSize: 34)),
                            const SizedBox(height: 6),
                            Text(gift.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('🪙 ${gift.priceCoins}', style: const TextStyle(color: Color(0xFFFFD68A), fontSize: 12)),
                          ]))));
                  })),
          Padding(padding: const EdgeInsets.all(12), child: Row(children: [
            if (widget.onOpenCoinStore != null) TextButton.icon(
              onPressed: widget.onOpenCoinStore, icon: const Icon(Icons.add_circle_outline),
              label: Text(ar ? 'شحن' : 'Top up')),
            Expanded(child: FilledButton(onPressed: canSend
              ? () => _send(targets[_recipient]!, ar) : null,
              child: Text(_sending ? (ar ? 'جارٍ الإرسال…' : 'Sending…')
                : (ar ? 'إرسال الهدية' : 'Send gift')))),
          ])),
        ]);
      },
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab({required this.service});
  final RoomFeatureService service;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.watchSpeakerStats(),
      builder: (context, speakerSnapshot) {
        return StreamBuilder<List<RoomGiftEvent>>(
          stream: service.watchGifts(),
          builder: (context, giftSnapshot) {
            final giftTotals = <String, int>{};
            final giftNames = <String, String>{};
            for (final gift
                in giftSnapshot.data ?? const <RoomGiftEvent>[]) {
              giftTotals[gift.recipientId] =
                  (giftTotals[gift.recipientId] ?? 0) + gift.points;
              giftNames[gift.recipientId] = gift.recipientName;
            }
            final giftRanking = giftTotals.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            final speakers = speakerSnapshot.data?.docs ??
                const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Most active speakers',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                if (speakers.isEmpty)
                  const ListTile(
                    leading: Icon(Icons.mic_none_rounded),
                    title: Text('No speaking activity yet.'),
                  )
                else
                  for (var index = 0; index < speakers.length; index++)
                    ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(
                        (speakers[index].data()['displayName'] ??
                                'WorldVoice user')
                            .toString(),
                      ),
                      trailing: Text(
                        _formatDuration(
                          (speakers[index].data()['seconds'] as num?)
                                  ?.toInt() ??
                              0,
                        ),
                      ),
                    ),
                const Divider(height: 28),
                Text(
                  'Top gifts received',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                if (giftRanking.isEmpty)
                  const ListTile(
                    leading: Icon(Icons.card_giftcard_rounded),
                    title: Text('No gifts yet.'),
                  )
                else
                  for (var index = 0; index < giftRanking.length; index++)
                    ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(
                        giftNames[giftRanking[index].key] ??
                            'WorldVoice user',
                      ),
                      trailing: Text('${giftRanking[index].value} pts'),
                    ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return minutes > 0 ? '${minutes}m ${remaining}s' : '${remaining}s';
  }
}


class _RewardsTab extends StatelessWidget {
  const _RewardsTab({
    required this.roomId,
    required this.isArabic,
  });

  final String roomId;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('room_rewards')
          .where('roomId', isEqualTo: roomId)
          .snapshots(),
      builder: (context, snapshot) {
        final rewards = snapshot.data?.docs ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        if (rewards.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Text(
                isArabic
                    ? 'لا توجد مكافآت من هذه الغرفة حتى الآن.'
                    : 'No rewards from this room yet.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final sorted = rewards.toList()
          ..sort((a, b) {
            final aLevel = (a.data()['level'] as num?)?.toInt() ?? 0;
            final bLevel = (b.data()['level'] as num?)?.toInt() ?? 0;
            return bLevel.compareTo(aLevel);
          });

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sorted.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final data = sorted[index].data();
            final level = (data['level'] as num?)?.toInt() ?? 0;
            final type = (data['type'] ?? '').toString();
            final expiryRaw = data['expiresAt'];
            final expiry =
                expiryRaw is Timestamp ? expiryRaw.toDate() : null;

            final isBackground = type == 'background_month';
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(
                    isBackground
                        ? Icons.wallpaper_rounded
                        : Icons.card_giftcard_rounded,
                  ),
                ),
                title: Text(
                  isBackground
                      ? (isArabic
                          ? 'خلفية مجانية لمدة شهر'
                          : 'Free background for one month')
                      : (isArabic ? 'حزمة هدايا مجانية' : 'Free gift pack'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  expiry == null
                      ? '${isArabic ? 'مكافأة مستوى' : 'Room level reward'} $level'
                      : '${isArabic ? 'مستوى' : 'Level'} $level • '
                          '${expiry.year}-'
                          '${expiry.month.toString().padLeft(2, '0')}-'
                          '${expiry.day.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.verified_rounded),
              ),
            );
          },
        );
      },
    );
  }
}
