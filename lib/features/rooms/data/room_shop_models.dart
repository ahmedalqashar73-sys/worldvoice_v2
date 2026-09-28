import 'package:cloud_firestore/cloud_firestore.dart';

class RoomShopBackground {
  const RoomShopBackground({
    required this.id,
    required this.name,
    required this.themeId,
    required this.priceCoins,
    required this.active,
    this.previewUrl,
    this.durationDays,
  });

  final String id;
  final String name;
  final String themeId;
  final int priceCoins;
  final bool active;
  final String? previewUrl;
  final int? durationDays;

  factory RoomShopBackground.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return RoomShopBackground(
      id: doc.id,
      name: (data['name'] ?? 'WorldVoice Background').toString(),
      themeId: (data['themeId'] ?? doc.id).toString(),
      priceCoins: (data['priceCoins'] as num?)?.toInt() ?? 0,
      active: data['active'] == true,
      previewUrl: data['previewUrl']?.toString(),
      durationDays: (data['durationDays'] as num?)?.toInt(),
    );
  }
}

class RoomBackgroundEntitlement {
  const RoomBackgroundEntitlement({
    required this.themeId,
    required this.name,
    this.backgroundUrl,
    this.expiresAt,
  });

  final String themeId;
  final String name;
  final String? backgroundUrl;
  final DateTime? expiresAt;

  bool get isActive =>
      expiresAt == null || expiresAt!.isAfter(DateTime.now());

  factory RoomBackgroundEntitlement.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final rawExpires = data['expiresAt'];
    return RoomBackgroundEntitlement(
      themeId: (data['themeId'] ?? doc.id).toString(),
      name: (data['name'] ?? 'WorldVoice Background').toString(),
      backgroundUrl: data['backgroundUrl']?.toString(),
      expiresAt: rawExpires is Timestamp ? rawExpires.toDate() : null,
    );
  }
}

class RoomBackgroundReward {
  const RoomBackgroundReward({
    required this.id,
    required this.roomId,
    required this.claimed,
    this.expiresAt,
  });

  final String id;
  final String roomId;
  final bool claimed;
  final DateTime? expiresAt;

  bool get isAvailable =>
      !claimed &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  factory RoomBackgroundReward.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final rawExpires = data['expiresAt'];
    return RoomBackgroundReward(
      id: doc.id,
      roomId: (data['roomId'] ?? '').toString(),
      claimed: data['claimedAt'] != null,
      expiresAt: rawExpires is Timestamp ? rawExpires.toDate() : null,
    );
  }
}

/** Unified catalog view for frames, entrance effects and VIP gifts. */
class RoomStoreItem {
  const RoomStoreItem({
    required this.id, required this.type, required this.name,
    required this.priceCoins, required this.requiredGiftLevel,
    required this.active, this.durationDays, this.animationUrl,
  });

  final String id;
  final String type;
  final String name;
  final int priceCoins;
  final int requiredGiftLevel;
  final bool active;
  final int? durationDays;
  final String? animationUrl;

  factory RoomStoreItem.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return RoomStoreItem(
      id: doc.id,
      type: data['type']?.toString() ?? '',
      name: data['name']?.toString() ?? doc.id,
      priceCoins: (data['priceCoins'] as num?)?.toInt() ?? 0,
      requiredGiftLevel: (data['requiredGiftLevel'] as num?)?.toInt() ?? 0,
      active: data['active'] == true,
      durationDays: (data['durationDays'] as num?)?.toInt(),
      animationUrl: data['animationUrl']?.toString(),
    );
  }
}
