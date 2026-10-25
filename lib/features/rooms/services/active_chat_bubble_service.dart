import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/chat_bubble_catalog.dart';

/// Resolve a verified equip into the currently usable design for NEW messages.
/// Existing message snapshots keep their historical bubble ID after expiry.
abstract final class ActiveChatBubbleService {
  static bool isAllowed({
    required ChatBubbleDesign design,
    required Map<String, dynamic>? profile,
    required Map<String, dynamic>? owned,
    required DateTime now,
  }) {
    if (design.isVip) {
      if (profile?['isVip'] != true) return false;
      final expiry = profile?['vipExpiresAt'];
      if (expiry == null) return true;
      if (expiry is Timestamp) return expiry.toDate().isAfter(now);
      if (expiry is DateTime) return expiry.isAfter(now);
      return false;
    }
    if (owned?['type'] != 'bubble' ||
        owned?['bubbleId'] != design.id ||
        (owned?['quantity'] as num? ?? 0) <= 0) return false;
    final expiry = owned?['expiresAt'];
    if (expiry == null) return true;
    if (expiry is Timestamp) return expiry.toDate().isAfter(now);
    if (expiry is DateTime) return expiry.isAfter(now);
    return false;
  }

  static Future<String> fromProfile({
    required FirebaseFirestore firestore,
    required String uid,
    required Map<String, dynamic>? profile,
  }) async {
    final selected = profile?['chatBubbleId']?.toString() ?? 'free';
    final design = WorldVoiceChatBubbles.find(selected);
    if (design == null) return WorldVoiceChatBubbles.freeId;
    if (design.isVip) {
      return isAllowed(design: design, profile: profile,
          owned: null, now: DateTime.now())
          ? selected : WorldVoiceChatBubbles.freeId;
    }
    try {
      final owned = await firestore.collection('users').doc(uid)
        .collection('inventory').doc(design.inventoryId).get()
        .timeout(const Duration(seconds: 4));
      return isAllowed(design: design, profile: profile,
        owned: owned.data(), now: DateTime.now())
          ? selected : WorldVoiceChatBubbles.freeId;
    } catch (_) {
      // Never claim paid entitlement if the inventory cannot be verified.
      return WorldVoiceChatBubbles.freeId;
    }
  }
}
