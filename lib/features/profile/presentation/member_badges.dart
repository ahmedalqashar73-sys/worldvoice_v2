import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../engagement/services/engagement_service.dart';

abstract final class MemberBadgeCatalog {
  static const plans = [
    'monthly',
    'quarterly',
    'half_year',
    'annual',
    'lifetime',
  ];
  static const extras = ['aurora', 'sakura', 'celestial'];
  static String name(String id, bool ar) =>
      (ar
          ? const {
              'monthly': 'زمرد · شهر',
              'quarterly': 'ياقوت · ٣ أشهر',
              'half_year': 'أمِثيست · ٦ أشهر',
              'annual': 'التاج الذهبي · سنة',
              'lifetime': 'ألماس أبدي · مدى الحياة',
              'aurora': 'الشفق القطبي',
              'sakura': 'لؤلؤ الساكورا',
              'celestial': 'المجرة الملكية',
            }
          : const {
              'monthly': 'Emerald · Monthly',
              'quarterly': 'Sapphire · 3 months',
              'half_year': 'Amethyst · 6 months',
              'annual': 'Gold Crown · Yearly',
              'lifetime': 'Eternal Diamond · Lifetime',
              'aurora': 'Aurora',
              'sakura': 'Sakura Pearl',
              'celestial': 'Royal Galaxy',
            })[id] ??
      id;
  static Color color(String id) => switch (id) {
    'monthly' => const Color(0xFF56E6BA),
    'quarterly' => const Color(0xFF70C9FF),
    'half_year' => const Color(0xFFCE9CFF),
    'annual' => const Color(0xFFFFD680),
    'lifetime' => const Color(0xFFD0EDFF),
    'aurora' => const Color(0xFF68F6DF),
    'sakura' => const Color(0xFFFFB9D9),
    _ => const Color(0xFFAAA7FF),
  };
}

/// Compact code-drawn jewelry: crisp at chat size and independent of image assets.
class VipSignatureBadge extends StatelessWidget {
  const VipSignatureBadge({
    required this.design,
    this.large = false,
    super.key,
  });
  final String design;
  final bool large;
  @override
  Widget build(BuildContext context) {
    final color = MemberBadgeCatalog.color(design);
    final icon = switch (design) {
      'monthly' => Icons.eco_rounded,
      'quarterly' => Icons.shield_rounded,
      'half_year' => Icons.auto_awesome,
      'annual' => Icons.workspace_premium,
      'lifetime' => Icons.diamond_rounded,
      'sakura' => Icons.local_florist,
      'aurora' => Icons.waves_rounded,
      _ => Icons.nights_stay_rounded,
    };
    return Semantics(
      label: 'VIP ${MemberBadgeCatalog.name(design, false)}',
      child: Container(
        height: large ? 48 : 20,
        padding: EdgeInsets.symmetric(horizontal: large ? 15 : 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(large ? 15 : 7),
          border: Border.all(
            color: color.withValues(alpha: .9),
            width: large ? 1.4 : .7,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(color, const Color(0xFF121827), .56)!,
              const Color(0xFF121827),
              Color.lerp(color, const Color(0xFF121827), .7)!,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: .12),
              blurRadius: large ? 12 : 3,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: large ? 28 : 13, color: color),
            SizedBox(width: large ? 8 : 3),
            Text(
              'VIP',
              style: TextStyle(
                color: color,
                fontSize: large ? 25 : 11,
                height: 1,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w900,
                letterSpacing: .6,
              ),
            ),
            if (design == 'lifetime')
              Text(
                ' ∞',
                style: TextStyle(color: color, fontSize: large ? 24 : 12),
              ),
          ],
        ),
      ),
    );
  }
}

class GiftLevelBadge extends StatelessWidget {
  const GiftLevelBadge({required this.level, super.key});
  final int level;
  @override
  Widget build(BuildContext context) {
    final value = level.clamp(0, 50);
    final color = [
      const Color(0xFF85DACB),
      const Color(0xFF86CFFF),
      const Color(0xFFC7A6FF),
      const Color(0xFFFFBA8B),
      const Color(0xFFFFD66E),
    ][((value - 1).clamp(0, 49) ~/ 10)];
    return Semantics(
      label: 'Gift level $value',
      child: Container(
        height: 20,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF17262F),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: .7), width: .6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.diamond_rounded, size: 12, color: color),
            const SizedBox(width: 3),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 11,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PublicMemberMarks extends StatefulWidget {
  const PublicMemberMarks({required this.userId, super.key});
  final String userId;
  @override
  State<PublicMemberMarks> createState() => _PublicMemberMarksState();
}

class _PublicMemberMarksState extends State<PublicMemberMarks> {
  Future<Map<String, dynamic>>? _future;
  Timer? _timer;
  void _load() {
    _future =
        widget.userId.isEmpty ||
            Firebase.apps.isEmpty ||
            FirebaseAuth.instance.currentUser == null
        ? null
        : EngagementService.badge(widget.userId);
  }

  @override
  void initState() {
    super.initState();
    _load();
    if (_future == null) return;
    _timer = Timer.periodic(const Duration(seconds: 65), (_) {
      if (mounted &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        setState(_load);
      }
    });
  }

  @override
  void didUpdateWidget(covariant PublicMemberMarks oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _future,
    builder: (context, snapshot) {
      final data = snapshot.data;
      if (data == null) return const SizedBox.shrink();
      final level = (data['giftLevel'] as num?)?.toInt() ?? 0;
      final vip = data['vipBadge'] as String?;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (vip != null) ...[
            VipSignatureBadge(design: vip),
            const SizedBox(width: 4),
          ],
          GiftLevelBadge(level: level),
          const SizedBox(width: 5),
        ],
      );
    },
  );
}

class MemberBadgeShop extends StatefulWidget {
  const MemberBadgeShop({super.key});
  @override
  State<MemberBadgeShop> createState() => _MemberBadgeShopState();
}

class _MemberBadgeShopState extends State<MemberBadgeShop> {
  late Future<Map<String, dynamic>> _future = EngagementService.request(
    'member-style',
  );
  final Map<String, String> _requests = {};
  bool _busy = false;
  bool get ar => Localizations.localeOf(context).languageCode == 'ar';
  Future<void> _apply(String design, String action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final key = '$action:$design';
    final requestId = _requests.putIfAbsent(
      key,
      () => List.generate(
        24,
        (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join(),
    );
    try {
      await EngagementService.request(
        'member-style',
        body: {'design': design, 'action': action, 'requestId': requestId},
      );
      _requests.remove(key);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) EngagementService.invalidate(uid);
      if (mounted) {
        setState(() => _future = EngagementService.request('member-style'));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ar
                  ? 'تعذر تفعيل الشارة. تأكد من عضوية VIP والرصيد، ثم أعد المحاولة.'
                  : 'Could not apply badge. Check VIP membership and balance, then retry.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(ar ? 'شارات VIP ومستوى الهدايا' : 'VIP badges & Gift level'),
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () => setState(
                () => _future = EngagementService.request('member-style'),
              ),
              child: Text(ar ? 'إعادة المحاولة' : 'Retry'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final active = data['automatic'] != null;
        final progress = Map<String, dynamic>.from(data['progress'] as Map);
        final level = (progress['level'] as num).toInt();
        final floor = 5 * level * (level + 3);
        final next = (progress['next'] as num?)?.toDouble();
        final value = next == null
            ? 1.0
            : (((progress['points'] as num) - floor) / (next - floor)).clamp(
                0.0,
                1.0,
              );
        final owned = List<String>.from(data['owned'] as List? ?? []);
        final catalog = Map<String, dynamic>.from(
          data['catalog'] as Map? ?? {},
        );
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GiftLevelBadge(level: level),
                        const SizedBox(width: 10),
                        Text(
                          ar
                              ? 'مستوى الهدايا $level / 50'
                              : 'Gift level $level / 50',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: value,
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      next == null
                          ? (ar
                                ? 'وصلت إلى أعلى مستوى'
                                : 'Maximum level reached')
                          : (ar
                                ? 'باقي ${progress['remaining']} كوين من الهدايا للمستوى التالي'
                                : '${progress['remaining']} gifted coins to next level'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ar
                          ? '٢٠ كوين لأول مستوى، ثم تزيد ١٠ كوين لكل انتقال. يُحتسب إرسال الهدايا المدفوعة فقط.'
                          : '20 coins for level 1, then 10 more per step. Only paid gifts sent count.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              ar ? 'شارتك مع باقتك' : 'Included with your VIP plan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              ar
                  ? 'تُفعّل تلقائيًا مع العضوية.'
                  : 'Automatically included with an active membership.',
            ),
            for (final id in MemberBadgeCatalog.plans)
              Card(
                child: ListTile(
                  leading: VipSignatureBadge(design: id),
                  title: Text(MemberBadgeCatalog.name(id, ar)),
                  subtitle: Text(
                    data['automatic'] == id
                        ? (ar ? 'باقتك الحالية' : 'Your current plan')
                        : (ar
                              ? 'مشمولة مع هذه الباقة'
                              : 'Included with this plan'),
                  ),
                  trailing: data['automatic'] == id
                      ? const Icon(Icons.check_circle, color: Color(0xFF41C99E))
                      : null,
                ),
              ),
            if (active)
              TextButton(
                onPressed: _busy ? null : () => _apply('automatic', 'equip'),
                child: Text(ar ? 'استخدام شارة الباقة' : 'Use my plan badge'),
              ),
            const SizedBox(height: 20),
            Text(
              ar ? 'مجموعة التوقيع' : 'Signature Collection',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              ar
                  ? 'شراء دائم للتصميم • يظهر أثناء سريان VIP'
                  : 'Permanent design ownership • visible while VIP is active',
            ),
            for (final id in MemberBadgeCatalog.extras)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      VipSignatureBadge(design: id, large: true),
                      const SizedBox(height: 12),
                      Text(MemberBadgeCatalog.name(id, ar)),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: _busy || !active
                            ? null
                            : () => _apply(
                                id,
                                owned.contains(id) ? 'equip' : 'purchase',
                              ),
                        child: Text(
                          data['selected'] == id
                              ? (ar ? 'مستخدمة ✓' : 'Equipped ✓')
                              : !active
                              ? (ar ? 'تحتاج عضوية VIP' : 'VIP required')
                              : owned.contains(id)
                              ? (ar ? 'استخدام' : 'Use')
                              : data['admin'] == true
                              ? (ar ? 'تفعيل الأدمن مجانًا' : 'Admin · Free')
                              : (ar
                                    ? 'شراء · ${catalog[id]} كوين'
                                    : 'Buy · ${catalog[id]} coins'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
