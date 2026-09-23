import 'package:flutter/material.dart';

import '../data/room_feature_models.dart';
import '../data/room_moderation_models.dart';
import '../services/room_feature_service.dart';

class RoomExtrasSheet extends StatelessWidget {
  const RoomExtrasSheet({
    required this.roomId,
    required this.participants,
    required this.isHost,
    super.key,
  });

  final String roomId;
  final List<RoomParticipant> participants;
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    final service = RoomFeatureService(roomId: roomId);
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .82,
        child: DefaultTabController(
          length: 4,
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
                    ),
                    _LeaderboardTab(service: service),
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
              RadioListTile<String>(
                value: theme.$1,
                groupValue: selected,
                onChanged: !isHost
                    ? null
                    : (value) {
                        if (value != null) service.setTheme(value);
                      },
                secondary: Icon(theme.$3),
                title: Text(theme.$2),
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
  });
  final RoomFeatureService service;
  final List<RoomParticipant> participants;

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
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: target.photoUrl?.isNotEmpty == true
                    ? NetworkImage(target.photoUrl!)
                    : null,
                child: target.photoUrl?.isNotEmpty == true
                    ? null
                    : const Icon(Icons.person_rounded),
              ),
              title: Text(target.displayName),
              subtitle: const Text('Send room gift'),
              trailing: PopupMenuButton<(String, int)>(
                onSelected: (gift) => service.sendGift(
                  recipientId: target.userId,
                  recipientName: target.displayName,
                  giftId: gift.$1,
                  points: gift.$2,
                ),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: ('rose', 10),
                    child: Text('🌹 Rose • 10'),
                  ),
                  PopupMenuItem(
                    value: ('star', 50),
                    child: Text('⭐ Star • 50'),
                  ),
                  PopupMenuItem(
                    value: ('dragon', 500),
                    child: Text('🐉 Dragon • 500'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab({required this.service});
  final RoomFeatureService service;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RoomGiftEvent>>(
      stream: service.watchGifts(),
      builder: (context, snapshot) {
        final totals = <String, int>{};
        final names = <String, String>{};
        for (final gift in snapshot.data ?? const <RoomGiftEvent>[]) {
          totals[gift.recipientId] =
              (totals[gift.recipientId] ?? 0) + gift.points;
          names[gift.recipientId] = gift.recipientName;
        }
        final ranking = totals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        if (ranking.isEmpty) {
          return const Center(child: Text('No gifts yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ranking.length,
          itemBuilder: (context, index) {
            final entry = ranking[index];
            return ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(names[entry.key] ?? 'WorldVoice user'),
              trailing: Text('${entry.value} pts'),
            );
          },
        );
      },
    );
  }
}
