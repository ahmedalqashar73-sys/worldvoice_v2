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
    super.key,
  });

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

class _GiftsTab extends StatelessWidget {
  const _GiftsTab({
    required this.service,
    required this.participants,
    required this.showTeacherAiSeat,
    this.onOpenCoinStore,
  });
  final RoomFeatureService service;
  final List<RoomParticipant> participants;
  final bool showTeacherAiSeat;
  final VoidCallback? onOpenCoinStore;

  @override
  Widget build(BuildContext context) {
    final targets = participants.where((p) => p.isOnStage).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (targets.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No stage member is available for gifts.'),
          ),
        for (final target in targets)
          _GiftTargetTile(
            service: service,
            recipientId: target.userId,
            recipientName: target.displayName,
            photoUrl: target.photoUrl,
            onOpenCoinStore: onOpenCoinStore,
          ),
        if (showTeacherAiSeat)
          _GiftTargetTile(
            service: service,
            recipientId: 'teacher_ai',
            recipientName: 'Teacher AI',
            teacherAi: true,
            onOpenCoinStore: onOpenCoinStore,
          ),
      ],
    );
  }
}

class _GiftTargetTile extends StatelessWidget {
  const _GiftTargetTile({
    required this.service,
    required this.recipientId,
    required this.recipientName,
    this.photoUrl,
    this.teacherAi = false,
    this.onOpenCoinStore,
  });

  final RoomFeatureService service;
  final String recipientId;
  final String recipientName;
  final String? photoUrl;
  final bool teacherAi;
  final VoidCallback? onOpenCoinStore;

  Future<void> _send(
    BuildContext context,
    (String, int) gift,
  ) async {
    try {
      await service.sendGift(
        recipientId: recipientId,
        recipientName: recipientName,
        giftId: gift.$1,
        points: gift.$2,
      );
    } catch (error) {
      if (!context.mounted) return;
      final notEnough = error.toString().contains('NOT_ENOUGH_COINS');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            notEnough
                ? 'Not enough coins. Add coins from the WorldVoice store.'
                : error.toString(),
          ),
        ),
      );
      if (notEnough && onOpenCoinStore != null) {
        onOpenCoinStore!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: !teacherAi && photoUrl?.isNotEmpty == true
              ? NetworkImage(photoUrl!)
              : null,
          child: teacherAi
              ? const Icon(Icons.smart_toy_rounded)
              : photoUrl?.isNotEmpty == true
                  ? null
                  : const Icon(Icons.person_rounded),
        ),
        title: Text(recipientName),
        subtitle: const Text('Send room gift'),
        trailing: PopupMenuButton<(String, int)>(
          onSelected: (gift) => _send(context, gift),
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: ('rose', 10),
              child: Text('🌹 Rose • 10 coins'),
            ),
            PopupMenuItem(
              value: ('star', 50),
              child: Text('⭐ Star • 50 coins'),
            ),
            PopupMenuItem(
              value: ('dragon', 500),
              child: Text('🐉 Dragon • 500 coins'),
            ),
          ],
        ),
      ),
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
