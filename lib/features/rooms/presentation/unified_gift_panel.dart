import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/room_feature_models.dart';
import '../data/room_moderation_models.dart';
import '../services/room_feature_service.dart';

// Single gift panel. Do not fork a second copy for live or chat.
class UnifiedGiftPanel extends StatefulWidget {
  const UnifiedGiftPanel({required this.service, required this.participants,
    required this.showTeacherAiSeat, this.onOpenCoinStore,
    this.giftContext = 'room', this.contextId, super.key});
  final RoomFeatureService service;
  final List<RoomParticipant> participants;
  // Reusable across room, live, and conversation contexts once those sessions
  // have an authoritative members collection.
  final String giftContext;
  final String? contextId;
  final bool showTeacherAiSeat;
  final VoidCallback? onOpenCoinStore;
  @override
  State<UnifiedGiftPanel> createState() => _UnifiedGiftPanelState();
}

class _UnifiedGiftPanelState extends State<UnifiedGiftPanel> {
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
        recipientName: name, giftId: gift.id, points: gift.priceCoins,
        context: widget.giftContext, contextId: widget.contextId);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ar ? 'تم إرسال الهدية' : 'Gift sent'))); }
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

