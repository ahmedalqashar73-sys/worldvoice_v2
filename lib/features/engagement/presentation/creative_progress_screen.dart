import 'package:flutter/material.dart';

import '../services/engagement_service.dart';
import 'reward_journey_card.dart';

typedef CreativeBadgeLoader = Future<Map<String, dynamic>> Function(String userId);

/// A profile link, not an inline list of room missions. Counts come from the
/// authenticated engagement backend and are never derived from device days.
class CreativeProfileLink extends StatefulWidget {
  const CreativeProfileLink({
    required this.userId,
    this.badgeLoader,
    this.onOpen,
    super.key,
  });

  final String userId;
  final CreativeBadgeLoader? badgeLoader;
  final VoidCallback? onOpen;

  @override
  State<CreativeProfileLink> createState() => _CreativeProfileLinkState();
}

class _CreativeProfileLinkState extends State<CreativeProfileLink> {
  late Future<Map<String, dynamic>> _badge;

  Future<Map<String, dynamic>> _load() =>
      (widget.badgeLoader ?? EngagementService.badge)(widget.userId);

  @override
  void initState() {
    super.initState();
    _badge = _load();
  }

  @override
  void didUpdateWidget(covariant CreativeProfileLink oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.badgeLoader != widget.badgeLoader) {
      _badge = _load();
    }
  }

  Future<void> _open() async {
    if (widget.onOpen != null) {
      widget.onOpen!();
      return;
    }
    await Navigator.of(context).push<void>(MaterialPageRoute(
      builder: (_) => CreativeProgressScreen(userId: widget.userId),
    ));
    if (!mounted) return;
    EngagementService.invalidate(widget.userId);
    setState(() => _badge = _load());
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Semantics(
      button: true,
      label: ar ? 'افتح إنجازات كريتيف' : 'Open Creative achievements',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _open,
        child: Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF192B29),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF385A49)),
          ),
          child: Row(children: [
            const Icon(Icons.workspace_premium_rounded,
                color: Color(0xFFE5C57A), size: 31),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ar ? 'كريتيف · المبدع' : 'Creative achievements',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(ar ? 'سجل الإنجازات والتسجيل اليومي'
                    : 'Achievements and daily check-in',
                    style: const TextStyle(color: Color(0xFFB7C9BE),
                        fontSize: 12)),
              ],
            )),
            FutureBuilder<Map<String, dynamic>>(
              future: _badge,
              builder: (context, snapshot) {
                final count = (snapshot.data?['creativeCycles'] as num?)?.toInt();
                return Text(
                  count == null ? '—' : '$count',
                  style: const TextStyle(
                    fontSize: 21, fontWeight: FontWeight.w900,
                    color: Color(0xFFEFD18C)),
                );
              },
            ),
            const SizedBox(width: 7),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFE5C57A)),
          ]),
        ),
      ),
    );
  }
}

/// Daily application reward cycle and room-verified Creative milestones stay
/// distinct. No invented 413-day streak or unverified room task counter.
class CreativeProgressScreen extends StatefulWidget {
  const CreativeProgressScreen({
    required this.userId,
    this.badgeLoader,
    super.key,
  });

  final String userId;
  final CreativeBadgeLoader? badgeLoader;

  @override
  State<CreativeProgressScreen> createState() => _CreativeProgressScreenState();
}

class _CreativeProgressScreenState extends State<CreativeProgressScreen> {
  late Future<Map<String, dynamic>> _badge;

  @override
  void initState() {
    super.initState();
    _badge = (widget.badgeLoader ?? EngagementService.badge)(widget.userId);
  }

  @override
  void didUpdateWidget(covariant CreativeProgressScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.badgeLoader != widget.badgeLoader) {
      _badge = (widget.badgeLoader ?? EngagementService.badge)(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(ar ? 'كريتيف · إنجازاتي' : 'My Creative journey')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        children: [
          Text(ar ? 'إنجازات الغرف الصوتية' : 'Voice room achievements',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, dynamic>>(
            future: _badge,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(ar ? 'تعذّر تحميل الإنجازات. أعد فتح الصفحة.'
                    : 'Achievements unavailable. Reopen to retry.');
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final creative = (snapshot.data!['creativeCycles'] as num?)?.toInt() ?? 0;
              final completed = (snapshot.data!['completedCycles'] as num?)?.toInt() ?? 0;
              return Row(children: [
                Expanded(child: _VerifiedCreativeStat(
                  icon: Icons.workspace_premium_rounded,
                  count: creative,
                  title: ar ? 'مرات المبدع' : 'Creative awards')),
                const SizedBox(width: 10),
                Expanded(child: _VerifiedCreativeStat(
                  icon: Icons.verified_rounded,
                  count: completed,
                  title: ar ? 'الدورات المكتملة' : 'Completed cycles')),
              ]);
            },
          ),
          const SizedBox(height: 24),
          Text(ar ? 'التسجيل اليومي' : 'Daily check-in',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(ar
              ? 'هدايا الحضور اليومية مستقلة عن خبرة الغرفة.'
              : 'Daily attendance gifts are separate from room XP.',
              style: Theme.of(context).textTheme.bodySmall),
          const RewardJourneyCard(compactProfile: true),
        ],
      ),
    );
  }
}

class _VerifiedCreativeStat extends StatelessWidget {
  const _VerifiedCreativeStat({
    required this.icon,
    required this.count,
    required this.title,
  });
  final IconData icon;
  final int count;
  final String title;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 17),
    decoration: BoxDecoration(
      color: const Color(0xFF193B30),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(children: [
      Icon(icon, color: const Color(0xFFE9C77F)),
      const SizedBox(height: 8),
      Text('$count', style: const TextStyle(
        fontSize: 27, color: Color(0xFFFFDE97),
        fontWeight: FontWeight.w900)),
      Text(title, textAlign: TextAlign.center, style: const TextStyle(
        color: Colors.white, fontSize: 12)),
    ]),
  );
}
