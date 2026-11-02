import 'package:flutter/material.dart';

import '../../../core/widgets/worldvoice_avatar_frame.dart';
import '../../rooms/data/chat_bubble_catalog.dart';
import '../../rooms/data/classic_gift_catalog.dart';
import '../../rooms/data/room_background_catalog.dart';
import '../../rooms/data/room_feature_models.dart';
import '../../rooms/presentation/chat_bubble_frame.dart';
import '../../rooms/presentation/classic_gift_visual.dart';

/// Reusable, persistent chat artwork for server-confirmed gifts.
class WorldVoiceChatGiftCard extends StatelessWidget {
  const WorldVoiceChatGiftCard({
    required this.data, required this.ar, required this.peerName,
    this.allowDetails = true, this.large = false, super.key,
  });

  final Map<String, dynamic> data;
  final bool ar;
  final String peerName;
  final bool allowDetails;
  final bool large;

  static String itemIdOf(Map<String, dynamic> data) =>
      (data['itemId'] ?? data['giftId'] ?? '').toString().trim();

  static String kindOf(Map<String, dynamic> data) {
    final id = itemIdOf(data);
    for (final kind in ['frame', 'background', 'bubble', 'entrance', 'vip']) {
      if (id.startsWith('${kind}__')) return kind;
    }
    return 'gift';
  }

  static String? localBackgroundAsset(Map<String, dynamic> data) {
    final id = itemIdOf(data);
    if (!id.startsWith('background__')) return null;
    return RoomBackgroundCatalog.assetPathForTheme(
      id.substring('background__'.length),
    );
  }

  String get _kind => kindOf(data);
  String get _id => itemIdOf(data);

  /// Bubble purchase IDs encode duration separately from the design.
  static String bubbleDesignIdOf(Map<String, dynamic> data) =>
      itemIdOf(data).replaceFirst('bubble__', '').split('__').first;
  String get _sender =>
      (data['senderName'] ?? (ar ? 'المرسل' : 'Sender')).toString();
  String get _receiver => (data['recipientName'] ?? peerName).toString();
  String get _label => switch (_kind) {
    'frame' => ar ? 'إطار مميز' : 'Profile frame',
    'background' => ar ? 'خلفية فاخرة' : 'Premium background',
    'bubble' => ar ? 'فقاعة دردشة' : 'Chat bubble',
    'entrance' => ar ? 'تأثير دخول' : 'Entrance effect',
    'vip' => 'VIP',
    _ => ar ? 'هدية WorldVoice' : 'WorldVoice Gift',
  };

  String _name(RoomGiftCatalogItem? gift) {
    if (gift != null) return gift.localizedName(ar);
    final provided = (ar ? data['nameAr'] ?? data['name']
        : data['name'] ?? data['nameAr'])?.toString().trim();
    // Prefer translated, installed artwork catalog names to raw shop IDs.
    if (_kind == 'bubble') {
      final design = WorldVoiceChatBubbles.find(bubbleDesignIdOf(data));
      if (design != null) return ar ? design.nameAr : design.name;
    }
    if (provided != null && provided.isNotEmpty) return provided;
    if (_kind == 'frame') return WorldVoiceAvatarFrame.label(_id, ar: ar);
    if (_kind == 'background') {
      final theme = RoomBackgroundCatalog.itemForTheme(
        _id.replaceFirst('background__', ''),
      );
      if (theme != null) return theme.localizedName(ar);
    }
    if (_kind == 'bubble') {
      final design = WorldVoiceChatBubbles.find(
        bubbleDesignIdOf(data),
      );
      if (design != null) return ar ? design.nameAr : design.name;
    }
    return _label;
  }

  Widget _fallback(double size) => SizedBox(
    width: size, height: size,
    child: Icon(switch (_kind) {
      'frame' => Icons.account_circle_outlined,
      'background' => Icons.wallpaper_rounded,
      'bubble' => Icons.chat_bubble_outline,
      'vip' => Icons.workspace_premium_rounded,
      _ => Icons.card_giftcard_rounded,
    }, size: size * .48, color: const Color(0xFFECD19A)),
  );

  Widget _art(RoomGiftCatalogItem? gift) {
    final size = large ? 150.0 : 100.0;
    if (_kind == 'gift' && gift != null) {
      return ClassicGiftVisual(gift: gift, size: size);
    }
    if (_kind == 'gift' && RegExp(r'^wv_gift_[0-9]{3}$').hasMatch(_id)) {
      return Image.asset(
        'assets/gifts/hd/$_id.webp',
        width: size, height: size, fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _fallback(size),
      );
    }
    if (_kind == 'background') {
      final path = localBackgroundAsset(data);
      if (path != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(path, width: large ? 195 : 150,
            height: size, fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallback(size)),
        );
      }
    }
    if (_kind == 'frame' && WorldVoiceAvatarFrame.isPremium(_id)) {
      return WorldVoiceAvatarFrame(
        frameId: _id, size: size, animate: false,
        child: CircleAvatar(
          backgroundColor: const Color(0xFF165440),
          child: Icon(Icons.person_rounded, size: size * .35,
            color: const Color(0xFFF1DDA2)),
        ),
      );
    }
    if (_kind == 'bubble') {
      final design = WorldVoiceChatBubbles.find(
        bubbleDesignIdOf(data),
      );
      if (design != null) {
        return SizedBox(
          width: large ? 210 : 170,
          child: WorldVoiceBubbleFrame(
            design: design, compact: true,
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Text(ar ? 'مرحبًا!' : 'Hello!',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white)),
            ),
          ),
        );
      }
    }
    return _fallback(size);
  }

  Widget _card(RoomGiftCatalogItem? gift) {
    final coins = data['points'] ?? data['priceCoins'] ?? data['chargedCoins'];
    final duration = (data['durationDays'] as num?)?.toInt();
    final quantity = (data['quantity'] as num?)?.toInt() ?? 1;
    return Container(
      width: large ? 285 : 252,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF115840), Color(0xFF092D24), Color(0xFF173C30)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: const Color(0xFFE4C37B), width: 1.3),
        boxShadow: const [BoxShadow(
          color: Color(0x34000000), blurRadius: 10,
          offset: Offset(0, 4))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.auto_awesome, color: Color(0xFFFFDA91), size: 17),
        Text(ar ? '$_sender أهدى إلى $_receiver'
                : '$_sender sent to $_receiver',
          maxLines: 2, textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFFFFE5A5),
            fontWeight: FontWeight.w800, fontSize: 12)),
        const SizedBox(height: 6),
        _art(gift),
        const SizedBox(height: 6),
        Text(_name(gift), maxLines: 2, textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white,
            fontSize: 14, fontWeight: FontWeight.w900)),
        Text(_label, style: const TextStyle(
          fontSize: 11, color: Color(0xFFB4D8C6))),
        if (quantity > 1) Text('× $quantity',
          style: const TextStyle(color: Color(0xFFEBD08A))),
        if (duration != null && duration > 0)
          Text(ar ? '$duration أيام' : '$duration days',
            style: const TextStyle(color: Color(0xFFEED79D))),
        if (_kind != 'gift' && duration == null)
          Text(ar ? 'في مقتنيات المستلم' : 'Added to recipient inventory',
            style: const TextStyle(
              color: Color(0xFFB4D8C6), fontSize: 10)),
        if (coins is num && coins > 0)
          Text('${coins.toInt()} 🪙',
            style: const TextStyle(
              color: Color(0xFFFFD991), fontWeight: FontWeight.bold)),
        if (data['nonRedeemable'] == true)
          Text(ar ? 'هدية اختبار دون ألماس قابل للسحب'
                  : 'Test gift: no redeemable diamonds',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFB4D8C6),
              fontSize: 10)),
        if (allowDetails)
          Text(ar ? 'اضغط لعرض الهدية' : 'Tap to view gift',
            style: const TextStyle(color: Color(0xFFD7C58F),
              fontSize: 10)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RoomGiftCatalogItem>>(
      future: _kind == 'gift' ? ClassicGiftCatalog.load() : null,
      builder: (context, snapshot) {
        RoomGiftCatalogItem? gift;
        for (final item in snapshot.data ?? const <RoomGiftCatalogItem>[]) {
          if (item.id == _id) { gift = item; break; }
        }
        final content = _card(gift);
        if (!allowDetails) return content;
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => showDialog<void>(
            context: context,
            builder: (ctx) => Dialog(
              backgroundColor: Colors.transparent,
              child: SingleChildScrollView(
                child: WorldVoiceChatGiftCard(
                  data: data, ar: ar, peerName: peerName,
                  allowDetails: false, large: true,
                ),
              ),
            ),
          ),
          child: content,
        );
      },
    );
  }
}
