import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/room_feature_models.dart';
import '../services/room_feature_service.dart';

class RoomExtrasSheet extends StatelessWidget {
  const RoomExtrasSheet({
    required this.roomId,
    this.initialTab = 0,
    super.key,
  });

  final int initialTab;
  final String roomId;

  @override
  Widget build(BuildContext context) {
    final service = RoomFeatureService(roomId: roomId);
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .82,
        child: DefaultTabController(
          length: 3,
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
                  Tab(text: isArabic ? 'المهام' : 'Tasks'),
                  Tab(text: isArabic ? 'الترتيب' : 'Leaderboard'),
                  Tab(text: isArabic ? 'المكافآت' : 'Rewards'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _TasksTab(service: service),
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

class _TasksTab extends StatefulWidget {
  const _TasksTab({required this.service});
  final RoomFeatureService service;

  @override
  State<_TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<_TasksTab> {
  Map<String, dynamic>? _status;
  bool _loading = false;
  String? _busyTask;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    try {
      final status = await widget.service.taskStatus();
      if (mounted) {
        setState(() => _status = status);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _status = null;
          _error = error.toString().replaceFirst('Bad state: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _claim(String key) async {
    if (_busyTask != null) return;
    setState(() { _busyTask = key; _error = null; });
    try {
      final result = await widget.service.claimVerifiedTask(key);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          '+${result['awardedXp']} XP • ${result['roomLevel']}/60',
        ),
      ));
      // No client XP or rewards are created by this widget.
      final status = await widget.service.taskStatus();
      if (mounted) {
        setState(() => _status = status);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString().replaceFirst('Bad state: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busyTask = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    const taskKeys = ['ten_minutes', 'host_five', 'three_gifts', 'stay_hours'];
    final rawMissions = _status?['missions'];
    final missions = rawMissions is List
        ? rawMissions.whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList(growable: false)
        : <Map<String, dynamic>>[];
    Map<String, dynamic>? findMission(String key) {
      for (final mission in missions) {
        if (mission['key'] == key) return mission;
      }
      return null;
    }

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        StreamBuilder<RoomFeatureState>(
          stream: widget.service.watchState(),
          builder: (context, snapshot) {
            final level = (snapshot.data?.roomLevel ?? 1).clamp(1, 60);
            final xp = snapshot.data?.roomXp ?? 0;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.castle_rounded,
                          color: Color(0xFFC4A457)),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          ar ? 'مستوى الغرفة $level من 60'
                              : 'Room level $level of 60',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text('${xp.clamp(0, 5900)} XP'),
                    ]),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: level >= 60 ? 1
                          : ((xp % 100) / 100).clamp(0.0, 1.0),
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(ar ? 'عرض مستويات 1–60'
                          : 'Show levels 1–60'),
                      children: [
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: [
                            for (var number = 1; number <= 60; number++)
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: number <= level
                                    ? const Color(0xFF216B4D)
                                    : Theme.of(context)
                                        .colorScheme.surfaceContainerHighest,
                                child: Text('$number',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: number <= level
                                        ? Colors.white
                                        : Theme.of(context)
                                            .colorScheme.onSurface,
                                  )),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        Row(children: [
          Expanded(child: Text(
            ar ? 'مهام موثقة من الخادم' : 'Server-verified missions',
            style: Theme.of(context).textTheme.titleMedium,
          )),
          IconButton(
            onPressed: _loading || _busyTask != null ? null : _refresh,
            tooltip: ar ? 'تحديث التقدم' : 'Refresh progress',
            icon: _loading
                ? const SizedBox.square(dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded),
          ),
        ]),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(_error!, style: TextStyle(
                color: Theme.of(context).colorScheme.error)),
          ),
        for (final key in taskKeys) ...[
          Builder(builder: (context) {
            final mission = findMission(key);
            final configured = mission?['configured'] == true;
            final claimed = mission?['claimed'] == true;
            final eligible = mission?['eligible'] == true;
            final current = (mission?['current'] as num?)?.toInt();
            final required = (mission?['required'] as num?)?.toInt();
            final xp = (mission?['xp'] as num?)?.toInt();
            final title = switch (key) {
              'ten_minutes' => ar ? 'البقاء 10 دقائق بالغرفة' : 'Stay 10 minutes',
              'host_five' => ar ? 'استضف خمسة مشاركين' : 'Host five participants',
              'three_gifts' => ar ? 'أرسل ثلاث هدايا' : 'Send three gifts',
              _ => ar ? 'البقاء لساعات' : 'Stay for hours',
            };
            final description = configured && required != null && current != null
                ? '${current.clamp(0, required)}/$required • +$xp XP'
                : key == 'ten_minutes'
                    ? (ar ? '10 دقائق • 4 XP'
                        : '10 minutes • 4 XP')
                    : key == 'host_five'
                        ? (ar ? '5 مشاركين • 50 XP'
                            : '5 participants • 50 XP')
                        : (ar
                            ? 'عدد الساعات والنقاط يُحددان في إعدادات الغرفة.'
                            : 'Hours/reward require approved room mission settings.');
            return Card(
              child: ListTile(
                leading: Icon(switch (key) {
                  'ten_minutes' => Icons.timer_outlined,
                  'host_five' => Icons.groups_rounded,
                  'three_gifts' => Icons.card_giftcard_rounded,
                  _ => Icons.hourglass_bottom_rounded,
                }),
                title: Text(title),
                subtitle: Text(description),
                trailing: claimed
                    ? const Icon(Icons.verified_rounded, color: Color(0xFF237950))
                    : FilledButton(
                        onPressed: configured && eligible &&
                                _busyTask == null && !_loading
                            ? () => _claim(key) : null,
                        child: Text(_busyTask == key
                            ? (ar ? 'جارٍ التحقق' : 'Checking')
                            : (ar ? 'استلام XP' : 'Claim XP')),
                      ),
              ),
            );
          }),
        ],
        const SizedBox(height: 8),
        Text(
          ar
              ? 'لا تُمنح النقاط إلا بعد أن يتحقق الخادم من البقاء والمشاركين والهدايا. حاليًا تحتاج هذه المهام إلى خادم WorldVoice الكامل.'
              : 'XP requires server-verified attendance, participants and gift events. The full WorldVoice backend must be deployed.',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
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
                          ? 'استحقاق خلفية لمدة شهر'
                          : 'One-month background eligibility')
                      : (isArabic
                          ? 'استحقاق باقة هدايا (بعد تفعيل الكتالوج)'
                          : 'Gift pack eligibility (pending catalog activation)'),
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
                trailing: Icon(isBackground
                    ? Icons.redeem_rounded
                    : Icons.hourglass_bottom_rounded),
              ),
            );
          },
        );
      },
    );
  }
}
