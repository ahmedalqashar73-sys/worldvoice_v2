import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/engagement_service.dart';
import 'creative_badge.dart';

class RewardJourneyCard extends StatefulWidget {
  const RewardJourneyCard({this.loadStatus, this.claimReward, super.key});
  final Future<Map<String, dynamic>> Function()? loadStatus;
  final Future<void> Function(Map<String, dynamic>)? claimReward;
  @override
  State<RewardJourneyCard> createState() => _RewardJourneyCardState();
}
class _RewardJourneyCardState extends State<RewardJourneyCard> with WidgetsBindingObserver {
  Map<String, dynamic>? _data;
  bool _busy = false, _failed = false;
  DateTime? _receivedAt;
  Timer? _timer;
  @override
  void initState() {
    super.initState(); WidgetsBinding.instance.addObserver(this); _load();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted || _data == null ||
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return;
      }
      if (_remaining.inSeconds <= 0) { _load(); } else { setState(() {}); }
    });
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }
  @override
  void dispose() { _timer?.cancel(); WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  Duration get _remaining {
    final elapsed = DateTime.now().difference(_receivedAt ?? DateTime.now()).inMilliseconds;
    final ms = ((_data?['nextAtMs'] as num? ?? 0) -
      (_data?['serverNowMs'] as num? ?? 0)).toInt() - elapsed;
    return Duration(milliseconds: ms < 0 ? 0 : ms);
  }
  Future<void> _load() async {
    if (_busy) return;
    setState(() { _busy = true; _failed = false; });
    try {
      final data = await (widget.loadStatus?.call() ?? EngagementService.request('status'));
      if (mounted) setState(() { _data = data; _receivedAt = DateTime.now(); });
    } catch (_) { if (mounted) setState(() => _failed = true); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _claim() async {
    if (_busy || _data?['canClaim'] != true) return;
    setState(() => _busy = true);
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    try {
      final body = {'startDay': _data!['startDay'], 'day': _data!['day']};
      if (widget.claimReward != null) { await widget.claimReward!(body); }
      else {
        await EngagementService.request('claim', body: body);
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) EngagementService.invalidate(uid);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ar
        ? 'هدية الدورة وصلت إلى حقيبتك' : 'Your reward is in your gift bag')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ar
          ? 'تعذر الاستلام. حدّث الحالة وحاول مرة أخرى.' : 'Unable to claim. Refresh and try again.')));
      }
    } finally { if (mounted) { setState(() => _busy = false); await _load(); } }
  }
  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final data = _data;
    final claimed = (data?['claimedDays'] as num? ?? 0).toInt();
    final rest = data?['phase'] == 'rest';
    final remaining = _remaining;
    final countdown = '${remaining.inHours}:${(remaining.inMinutes % 60).toString().padLeft(2, '0')}';
    if (_failed) {
      return Card(
        color: const Color(0xFFEAF6EF), elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          const Icon(Icons.card_giftcard_rounded, color: Color(0xFF98742D)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ar ? 'هدايا الحضور' : 'Attendance gifts',
                style: const TextStyle(color: Color(0xFF145840), fontWeight: FontWeight.w800)),
              Text(ar ? 'تعذّر تحميل المكافآت. أعد المحاولة.'
                  : 'Could not load rewards. Try again.',
                style: const TextStyle(color: Color(0xFF52755F), fontSize: 12)),
            ])),
          IconButton(onPressed: _busy ? null : _load,
            tooltip: ar ? 'إعادة المحاولة' : 'Retry',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF147A50))),
        ])),
      );
    }
    return Card(color: const Color(0xFFEAF6EF), margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ar ? 'هدايا الحضور' : 'Attendance gifts', style: const TextStyle(
            color: Color(0xFF145840), fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(ar ? '٣ أيام هدايا، ثم يوم راحة' : '3 reward days, then 1 rest day',
            style: const TextStyle(color: Color(0xFF245C49))),
          if (data == null) const LinearProgressIndicator()
          else ...[
            const SizedBox(height: 12),
            Row(children: List.generate(4, (index) => Expanded(child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: index < claimed ? const Color(0xFFD5EADD) : const Color(0xFFF5F8F1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: index < claimed
                  ? const Color(0xFF83B99B) : const Color(0xFFE5DDBF)),
              ),
              child: Column(children: [
              Icon(index == 3 ? Icons.nights_stay_outlined
                : index < claimed ? Icons.check_circle : Icons.card_giftcard,
                color: index < claimed || (index == 3 && rest)
                  ? const Color(0xFF147A50) : const Color(0xFF727D77)),
              Text(index == 3 ? (ar ? 'راحة' : 'Rest') : (ar ? 'اليوم ${index + 1}' : 'Day ${index + 1}'),
                style: const TextStyle(color: Color(0xFF245C49))),
              if (index < 3) Text('×${index + 1}', style: const TextStyle(color: Color(0xFF245C49))),
            ]))))),
            const SizedBox(height: 12),
            Text(ar ? 'هدايا مجانية في الحقيبة؛ ليست رصيد كوينز.' : 'Free gifts in your bag, not wallet coins.',
              style: const TextStyle(color: Color(0xFF245C49))),
            Text(ar ? 'التجدد الساعة ٣ صباحًا بتوقيت السعودية' : 'Days reset at 03:00 Saudi time',
              style: const TextStyle(color: Color(0xFF245C49), fontSize: 12)),
            const SizedBox(height: 8),
            if (data['canClaim'] == true) FilledButton.icon(onPressed: _busy ? null : _claim,
              icon: const Icon(Icons.card_giftcard), label: Text(ar ? 'استلم هديتك' : 'Claim gift'))
            else Text(rest ? (ar ? 'استراحة الرحلة · الدورة التالية بعد $countdown' : 'Rest day · Next cycle in $countdown')
              : (ar ? 'تم الاستلام · الخطوة التالية بعد $countdown' : 'Claimed · Next step in $countdown'),
              style: const TextStyle(color: Color(0xFF145840), fontWeight: FontWeight.w700)),
            const Divider(),
            Text(ar ? 'طريق المبدع المتكامل' : 'Path to Complete Creative',
              style: const TextStyle(color: Color(0xFF145840), fontWeight: FontWeight.w800)),
            Text(ar ? 'الدورة $claimed/3 · الحضور ${((data['activeMs'] as num? ?? 0) / 60000).floor()}/60 دقيقة'
              : 'Cycle $claimed/3 · Presence ${((data['activeMs'] as num? ?? 0) / 60000).floor()}/60 min',
              style: const TextStyle(color: Color(0xFF245C49))),
            Text(data['hostedFive'] == true ? (ar ? '✓ استضافة خمسة مشاركين' : '✓ Hosted five guests')
              : (ar ? 'استضف خمسة مشاركين خلال الدورة' : 'Host five guests during this cycle'),
              style: const TextStyle(color: Color(0xFF245C49))),
            if ((data['creativeCycles'] as num? ?? 0) > 0) AchievementMark(
              creativeCycles: (data['creativeCycles'] as num).toInt(),
              completedCycles: (data['completedCycles'] as num? ?? 0).toInt()),
          ],
        ])));
  }
}
