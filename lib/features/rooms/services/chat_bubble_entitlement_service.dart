import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/chat_bubble_catalog.dart';

/// Resolve the bubble at send time. The equipped profile field by itself is
/// not proof of entitlement: VIP can lapse and temporary purchases can expire.
/// On a failed/offline read we fail closed to the free cosmetic, never block
/// someone's message from being sent.
abstract final class ChatBubbleEntitlementService {
  static bool validInventory(
    Map<String, dynamic>? item, String bubbleId, DateTime now,
  ) {
    if (item == null || item['type'] != 'bubble' ||
        item['bubbleId'] != bubbleId ||
        (item['quantity'] is! num) ||
        (item['quantity'] as num) <= 0) {
      return false;
    }
    final expires = item['expiresAt'];
    return expires == null ||
        (expires is Timestamp && expires.toDate().isAfter(now));
  }

  static bool activeVip(
    Map<String, dynamic>? profile, DateTime now,
  ) {
    if (profile?['isVip'] != true) return false;
    final expiry = profile?['vipExpiresAt'];
    if (expiry == null) return true;
    return expiry is Timestamp && expiry.toDate().isAfter(now) ||
        expiry is DateTime && expiry.isAfter(now);
  }

  static Future<String> validSelectedId({
    required String userId,
    Map<String, dynamic>? profile,
    FirebaseFirestore? firestore,
  }) async {
    if (userId.isEmpty) return WorldVoiceChatBubbles.freeId;
    try {
      final db = firestore ?? FirebaseFirestore.instance;
      final data = profile ?? (await db.collection('users')
          .doc(userId).get().timeout(const Duration(seconds: 4))).data();
      final id = (data?['chatBubbleId'] ?? 'free').toString();
      final design = WorldVoiceChatBubbles.find(id);
      if (design == null) return WorldVoiceChatBubbles.freeId;
      final now = DateTime.now();
      if (design.isVip) {
        return activeVip(data, now) ? id : WorldVoiceChatBubbles.freeId;
      }
      final item = (await db.collection('users').doc(userId)
        .collection('inventory').doc(design.inventoryId)
        .get().timeout(const Duration(seconds: 4))).data();
      return validInventory(item, id, now)
          ? id : WorldVoiceChatBubbles.freeId;
    } catch (_) {
      return WorldVoiceChatBubbles.freeId;
    }
  }
}
