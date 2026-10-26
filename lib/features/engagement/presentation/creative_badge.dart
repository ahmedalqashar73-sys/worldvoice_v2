import 'dart:async';
import 'package:flutter/material.dart';
import '../services/engagement_service.dart';

class CreativeBadge extends StatefulWidget {
  const CreativeBadge({required this.userId, this.compact = false, super.key});
  final String userId;
  final bool compact;
  @override
  State<CreativeBadge> createState() => _CreativeBadgeState();
}
class _CreativeBadgeState extends State<CreativeBadge> {
  late Future<Map<String, dynamic>> _future;
  Timer? _refresh;
  @override
  void initState() {
    super.initState(); _future = EngagementService.badge(widget.userId);
    _refresh = Timer.periodic(const Duration(seconds: 65), (_) {
      if (mounted && WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        setState(() => _future = EngagementService.badge(widget.userId));
      }
    });
  }
  @override
  void dispose() { _refresh?.cancel(); super.dispose(); }
  @override
  void didUpdateWidget(covariant CreativeBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) _future = EngagementService.badge(widget.userId);
  }
  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _future,
    builder: (context, snapshot) {
      final data = snapshot.data;
      if (data == null) return const SizedBox.shrink();
      final creative = (data['creativeCycles'] as num? ?? 0).toInt();
      final completed = (data['completedCycles'] as num? ?? 0).toInt();
      final level = (data['giftLevel'] as num?)?.toInt();
      final ar = Localizations.localeOf(context).languageCode == 'ar';
      if (widget.compact) {
        if (creative == 0 && completed == 0) return const SizedBox.shrink();
        return AchievementMark(creativeCycles: creative, completedCycles: completed, compact: true);
      }
      return Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        if (level != null) Chip(label: Text(ar ? 'مستوى الهدايا $level' : 'Gift level $level')),
        if (creative > 0 || completed > 0) AchievementMark(
          creativeCycles: creative, completedCycles: completed),
      ]);
    },
  );
}

class AchievementMark extends StatelessWidget {
  const AchievementMark({required this.creativeCycles, required this.completedCycles,
    this.compact = false, super.key});
  final int creativeCycles, completedCycles;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final creative = creativeCycles > 0;
    final title = creative ? (ar ? 'المبدع المتكامل' : 'Complete Creative')
      : (ar ? 'مكتمل الدورة' : 'Cycle achiever');
    final count = creative ? creativeCycles : completedCycles;
    final icon = Icon(creative ? Icons.workspace_premium_rounded : Icons.verified_rounded,
      color: const Color(0xFFFFD675), size: compact ? 14 : 24);
    final label = '$title · $count';
    return Semantics(label: label, button: true, child: Tooltip(message: label,
      child: InkWell(onTap: () => showDialog<void>(context: context,
        builder: (context) => AlertDialog(title: Text(title), content: Text(creative
          ? (ar ? 'أكمل دورة المكافآت، وشارك ٦٠ دقيقة، واستضاف خمسة مشاركين. شارة دائمة.\nدورات الإبداع: $count'
            : 'Completed a reward cycle, participated for 60 minutes and hosted five guests. Permanent achievement.\nCreative cycles: $count')
          : (ar ? 'دورات المكافآت المكتملة: $count' : 'Completed reward cycles: $count')),
          actions: [TextButton(onPressed: () => Navigator.pop(context),
            child: Text(ar ? 'حسنًا' : 'OK'))])),
        child: compact ? icon : Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFF145840),
            borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFD9B65C))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [icon,
            const SizedBox(width: 6), Flexible(child: Text(label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))])),
      )));
  }
}
