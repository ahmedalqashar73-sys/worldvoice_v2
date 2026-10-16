import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  late final Stream<RoomFeatureState> _roomStateStream;
  bool _loading = false;
  String? _busyTask;
  String? _error;

  @override
  void initState() {
    super.initState();
    _roomStateStream = widget.service.watchState();
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
          final raw = error.toString();
          final ar = Localizations.localeOf(context).languageCode == 'ar';
          _error = raw.contains('TimeoutException') ||
                  raw.contains('ROOM_TASK_BACKEND_TIMEOUT')
              ? (ar
                  ? 'خادم المهام لا يستجيب الآن. يجب نشر الباك إند الجديد قبل تفعيل المكافآت.'
                  : 'Mission server unavailable. Deploy the updated backend first.')
              : raw.replaceFirst('Bad state: ', '').replaceFirst('StateError: ', '');
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
          '+${result['awardedXp']} XP • ${result['roomLevel']}/50',
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
    const taskKeys = <String>['host_five', 'stage_five', 'stay_hours',
      'room_checkin', 'visit_5', 'visit_6', 'visit_30', 'visit_60'];
    final compatible = _status?['taskPolicyVersion'] == 3;
    final visitDays = ((_status?['progress'] as Map?)?['dayCount'] as num?)
            ?.toInt() ?? 0;
    final loyalty = visitDays >= 60
        ? (ar ? 'أسطورة الغرفة' : 'Room Legend')
        : visitDays >= 30
            ? (ar ? 'سفير الغرفة' : 'Room Ambassador')
            : visitDays >= 6
                ? (ar ? 'مبدع الغرفة' : 'Room Creative')
                : visitDays >= 5
                    ? (ar ? 'صديق الغرفة' : 'Room Friend')
                    : (ar ? 'زائر الغرفة' : 'Room Visitor');
    final rawMissions = _status?['missions'];
    final missions = compatible && rawMissions is List
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
          stream: _roomStateStream,
          builder: (context, snapshot) {
            final xp = (_status?['xp'] as num?)?.toInt() ??
                snapshot.data?.roomXp ?? 0;
            final level = roomLevelFromXp(xp);
            final currentLevelXp = (xp - roomXpThresholdForLevel(level))
                .clamp(0, roomXpRequiredForLevel(level));
            final requiredXp = level >= roomCastleMaxLevel ? 0
                : roomXpRequiredForLevel(level);
            final tier = roomCastleTierForLevel(level);
            const castleNamesAr = [
              'قلعة البداية', 'قلعة البرونز', 'قلعة الفضة',
              'قلعة الياقوت', 'قلعة الزمرد', 'القلعة الذهبية',
              'قلعة التنين', 'القلعة السماوية',
              'القلعة الإمبراطورية', 'قلعة الأساطير',
            ];
            const castleNamesEn = [
              'Starter Castle', 'Bronze Castle', 'Silver Castle',
              'Sapphire Castle', 'Emerald Castle', 'Golden Castle',
              'Dragon Castle', 'Sky Castle',
              'Imperial Castle', 'Legendary Castle',
            ];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Color.lerp(const Color(0xFF11573D),
                                const Color(0xFF756034), (tier - 1) / 9)!,
                            Colors.transparent,
                          ],
                          radius: 0.85,
                        ),
                      ),
                      child: Column(children: [
                        Text(ar ? 'عالم القلاع · القلعة $tier من 10'
                            : 'Castle journey · castle $tier of 10',
                          style: const TextStyle(color: Color(0xFF52755F),
                            fontSize: 12, fontWeight: FontWeight.w700)),
                        SizedBox(height: 200, width: double.infinity,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: SizedBox(key: ValueKey<int>(tier),
                              width: 240, height: 200,
                              child: RoomCastleArtwork(level: level)),
                          )),
                        Text(ar ? castleNamesAr[tier - 1] : castleNamesEn[tier - 1],
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF174E38),
                            fontSize: 22, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text('LEVEL $level', textDirection: TextDirection.ltr,
                          style: const TextStyle(color: Color(0xFF8B6827),
                            letterSpacing: 2, fontSize: 14,
                            fontWeight: FontWeight.w900)),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: Text(
                        level >= roomCastleMaxLevel
                            ? (ar ? 'وصلت المستوى 50' : 'Level 50 complete')
                            : 'Lv.$level  →  Lv.${level + 1}',
                        style: const TextStyle(
                          color: Color(0xFF174E38),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      )),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          level >= roomCastleMaxLevel
                              ? 'MAX LEVEL'
                              : '$currentLevelXp / $requiredXp XP',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF236B4B),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 9),
                    LinearProgressIndicator(
                      value: level >= roomCastleMaxLevel ? 1
                          : (currentLevelXp / requiredXp).clamp(0.0, 1.0),
                      minHeight: 8,
                      color: const Color(0xFF249369),
                      backgroundColor: const Color(0xFF284B3B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 3),
                      child: Text(
                        ar
                            ? 'مجموع نقاط القلعة: $xp XP • المستوى التالي عند ${level >= roomCastleMaxLevel ? xp : roomXpThresholdForLevel(level + 1)} XP'
                            : 'Total castle XP: $xp • Next level at ${level >= roomCastleMaxLevel ? xp : roomXpThresholdForLevel(level + 1)} XP',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFB9D4C0), fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(ar ? 'شاهد القلاع العشر'
                          : 'Explore all 10 castles',
                        style: const TextStyle(
                          color: Color(0xFF174E38),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      iconColor: const Color(0xFF1C7553),
                      collapsedIconColor: const Color(0xFF1C7553),
                      children: [
                        for (var index = 0;
                            index < roomCastleMaxTier; index++)
                          ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              backgroundColor: index + 1 <= tier
                                  ? const Color(0xFF1D7956)
                                  : const Color(0xFF284B3B),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: RoomCastleArtwork(level: index * 5 + 1),
                              ),
                            ),
                            title: Text(ar ? castleNamesAr[index]
                                : castleNamesEn[index],
                              style: const TextStyle(
                                color: Color(0xFF174E38),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text('Lv. ${index * 5 + 1}–${(index + 1) * 5}',
                              style: const TextStyle(color: Color(0xFF4F7565)),
                            ),
                            trailing: index + 1 < tier
                                ? const Icon(Icons.check_circle,
                                    color: Color(0xFF26865D))
                                : index + 1 == tier
                                    ? const Icon(Icons.stars_rounded,
                                        color: Color(0xFFC49B39))
                                    : const Icon(Icons.lock_outline,
                                        color: Color(0xFF9DAEA4)),
                          ),
                      ],
                    ),
                  ],
              ),
            );
          },
        ),
        if (_status?['maxed'] == true)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(ar
                    ? 'اكتملت قلعة المستوى 50! يمكنك متابعة أنشطة الروم، لكن لا توجد نقاط قلعة إضافية.'
                    : 'Castle level 50 complete! You can keep participating, but castle XP is capped.',
                  style: const TextStyle(color: Color(0xFF216C48)),
                ),
              ),
            ),
          ),
        Row(children: [
          Expanded(child: Text(
            ar ? 'مهام بيتك الصوتي' : 'Your voice room journey',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFFF2D797),
              fontWeight: FontWeight.w900,
            ),
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
        if (_status != null && !compatible)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(ar
                ? 'هذا الخادم يعمل بنظام نقاط قديم. يلزم تحديث الباك إند لاستلام المكافآت الجديدة.'
                : 'This server uses an older XP policy. Update the backend before claiming new rewards.',
              style: const TextStyle(color: Color(0xFFFFCC8B), fontSize: 13)),
          ),
        if (compatible)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFFF1D48C), size: 19),
              const SizedBox(width: 8),
              Expanded(child: Text(
                ar ? '$loyalty • $visitDays يوم زيارة موثّق'
                   : '$loyalty • $visitDays verified visiting days',
                style: const TextStyle(color: Color(0xFFE5DBB9),
                   fontWeight: FontWeight.w800),
              )),
            ]),
          ),
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
              'host_five' => ar ? 'استقبل 5 مستمعين' : 'Welcome 5 listeners',
              'stage_five' => ar ? 'اصعد 5 مستمعين إلى المسرح' : 'Bring 5 listeners on stage',
              'stay_hours' => ar ? 'ابقَ 60 دقيقة في الغرفة' : 'Stay 60 minutes in the room',
              'room_checkin' => ar ? 'سجّل زيارتك اليومية' : 'Daily room check-in',
              'visit_5' => ar ? 'صديق الغرفة • 5 أيام' : 'Room Friend • 5 days',
              'visit_6' => ar ? 'مبدع الغرفة • 6 أيام' : 'Room Creative • 6 days',
              'visit_30' => ar ? 'سفير الغرفة • 30 يومًا' : 'Room Ambassador • 30 days',
              _ => ar ? 'أسطورة الغرفة • 60 يومًا' : 'Room Legend • 60 days',
            };
            final score = switch (key) {
              'host_five' => 10, 'stage_five' => 5, 'stay_hours' => 60,
              'room_checkin' => 2, 'visit_5' => 15, 'visit_6' => 20,
              'visit_30' => 100, _ => 200,
            };
            final target = switch (key) {
              'host_five' => 5, 'stage_five' => 5, 'stay_hours' => 60,
              'room_checkin' => 1, 'visit_5' => 5, 'visit_6' => 6,
              'visit_30' => 30, _ => 60,
            };
            final description = configured && required != null && current != null
                ? '${current.clamp(0, required)}/$required • +$xp XP'
                : (ar ? 'المطلوب $target • +$score XP بعد التحقق'
                    : 'Target $target • +$score XP after verification');
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B4235), Color(0xFF17322C)],
                ),
                border: Border.all(color: const Color(0xFF37694F), width: .7),
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                leading: Icon(switch (key) {
                  'host_five' => Icons.groups_rounded,
                  'stage_five' => Icons.airline_seat_recline_extra_rounded,
                  'stay_hours' => Icons.hourglass_bottom_rounded,
                  'room_checkin' => Icons.login_rounded,
                  'visit_5' => Icons.handshake_rounded,
                  'visit_6' => Icons.auto_awesome_rounded,
                  'visit_30' => Icons.workspace_premium_rounded,
                  _ => Icons.military_tech_rounded,
                }, color: const Color(0xFFECC982)),
                title: Text(title, style: const TextStyle(
                  color: Color(0xFFF5EEDB), fontWeight: FontWeight.w800,
                )),
                subtitle: Text(description, style: const TextStyle(
                  color: Color(0xFFBBD2C4), fontSize: 12,
                )),
                trailing: claimed
                    ? const Icon(Icons.verified_rounded, color: Color(0xFF237950))
                    : FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFD6B665),
                          foregroundColor: const Color(0xFF123C2B),
                          disabledBackgroundColor: const Color(0xFF375347),
                          disabledForegroundColor: const Color(0xFF98B0A5),
                          minimumSize: const Size(112, 40),
                        ),
                        onPressed: compatible && configured && eligible &&
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
              ? 'ابقَ متصلًا لاحتساب مدة الحضور. تتجدد المهام اليومية الساعة 03:00 بتوقيت السعودية (00:00 UTC).'
              : 'Stay connected to record attendance. Daily missions reset at 00:00 UTC.',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _LeaderboardTab extends StatefulWidget {
  const _LeaderboardTab({required this.service});
  final RoomFeatureService service;

  @override
  State<_LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<_LeaderboardTab> {
  late final _speakers = widget.service.watchSpeakerStats();
  late final _gifts = widget.service.watchGifts();

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _speakers,
      builder: (context, speakerSnapshot) {
        return StreamBuilder<List<RoomGiftEvent>>(
          stream: _gifts,
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
                  ar ? 'نشاط التحدث المُبلّغ عنه' : 'Reported speaking activity',
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
                  ar ? 'الهدايا المستلمة مؤخرًا' : 'Recent gifts received',
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
            final castleTier = (data['castleTier'] as num?)?.toInt() ?? 0;
            final isCastle = type == 'castle_milestone' ||
                data['castleMilestone'] == true;
            return Card(
              child: ListTile(
                leading: isCastle
                    ? SizedBox(
                        width: 58,
                        height: 58,
                        child: RoomCastleArtwork(level: level),
                      )
                    : CircleAvatar(
                        child: Icon(isBackground
                            ? Icons.wallpaper_rounded
                            : Icons.card_giftcard_rounded),
                      ),
                title: Text(
                  isBackground
                      ? (isArabic
                          ? 'استحقاق خلفية لمدة شهر (عند تفعيل الكتالوج)'
                          : 'One-month background eligibility (catalog pending)')
                      : type == 'castle_milestone'
                          ? (isArabic
                              ? 'إنجاز قلعة الغرفة • المرحلة $castleTier'
                              : 'Room castle milestone • tier $castleTier')
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
                    ? Icons.hourglass_top_rounded
                    : isCastle
                        ? Icons.workspace_premium_rounded
                        : Icons.hourglass_bottom_rounded),
              ),
            );
          },
        );
      },
    );
  }
}


// Premium WebP castle artwork with the existing SVG as a safe fallback.
// Missing optional assets must never break the room or its task controls.
// Tap any castle icon to inspect the full artwork without increasing the
// footprint of the room seats or covering the room background.
class RoomCastleArtwork extends StatelessWidget {
  const RoomCastleArtwork({required this.level, super.key});
  final int level;

  Widget _image({int cacheWidth = 256}) => Image.asset(
    roomCastleWebpAssetForLevel(level),
    cacheWidth: cacheWidth,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    errorBuilder: (context, error, stackTrace) => SvgPicture.asset(
      roomCastleAssetForLevel(level),
      fit: BoxFit.contain,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final tier = roomCastleTierForLevel(level);
    final first = (tier - 1) * 5 + 1;
    final last = tier * 5;
    return Semantics(
      button: true,
      label: ar
          ? 'معاينة قلعة المستويات $first إلى $last'
          : 'Preview castle levels $first to $last',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showDialog<void>(
          context: context,
          builder: (dialogContext) => Dialog(
            backgroundColor: const Color(0xFF103D2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ar ? 'قلعة الغرفة' : 'Room Castle',
                    style: const TextStyle(
                      color: Color(0xFFFFD98C),
                      fontWeight: FontWeight.w900,
                      fontSize: 19,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(height: 300, width: 300, child: _image(cacheWidth: 512)),
                  const SizedBox(height: 8),
                  Text(
                    'Lv. $first–$last',
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(ar ? 'إغلاق' : 'Close',
                      style: const TextStyle(color: Color(0xFFFFD98C))),
                  ),
                ],
              ),
            ),
          ),
        ),
        child: _image(cacheWidth: 512),
      ),
    );
  }
}

/// Compact identity under the room title; tier tint follows castle progression.
class RoomCastleBadge extends StatelessWidget {
  const RoomCastleBadge({required this.level, required this.onTap, super.key});
  final int level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final safeLevel = level.clamp(1, roomCastleMaxLevel);
    final gold = (roomCastleTierForLevel(safeLevel) - 1) / 9;
    return Semantics(
      button: true,
      label: Localizations.localeOf(context).languageCode == 'ar'
          ? 'قلعة الغرفة، المستوى $safeLevel، افتح المهام'
          : 'Room castle, level $safeLevel, open missions',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minWidth: 70, minHeight: 32),
          padding: const EdgeInsetsDirectional.only(start: 3, end: 9),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              const Color(0xFF123E30),
              Color.lerp(const Color(0xFF247B58), const Color(0xFF94732B), gold)!,
            ]),
            border: Border.all(color: Color.lerp(
                const Color(0xFF75BB91), const Color(0xFFF1CF7A), gold)!),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Image.asset(roomCastleWebpAssetForLevel(safeLevel),
              width: 32, height: 32, cacheWidth: 128, fit: BoxFit.contain,
              errorBuilder: (_, error, stack) => SvgPicture.asset(
                roomCastleAssetForLevel(safeLevel), width: 32, height: 32)),
            const SizedBox(width: 4),
            Text('Lv.$safeLevel', textDirection: TextDirection.ltr,
              style: const TextStyle(color: Color(0xFFFFE4A6),
                fontSize: 11, fontWeight: FontWeight.w900)),
          ]),
        ),
      ),
    );
  }
}
