import 'package:cloud_firestore/cloud_firestore.dart';

/// Normalised, read-only entry for the owner's inventory and gift receipts.
/// A received visual gift is a receipt, not a reusable spendable asset.
class OwnedCollectionEntry {
  const OwnedCollectionEntry({
    required this.id,
    required this.type,
    required this.name,
    required this.source,
    this.itemId = '',
    this.bubbleId = '',
    this.themeId = '',
    this.senderName = '',
    this.quantity = 1,
    this.expiresAt,
    this.pendingReward = false,
  });

  final String id;
  final String type;
  final String name;
  final String source;
  final String itemId;
  final String bubbleId;
  final String themeId;
  final String senderName;
  final int quantity;
  final DateTime? expiresAt;
  final bool pendingReward;

  bool get isExpired =>
      expiresAt != null && !expiresAt!.isAfter(DateTime.now());
  bool get isUsable => !pendingReward && !isExpired && source != 'received_gift';

  static DateTime? expiryOf(Map<String, dynamic> data) {
    final raw = data['expiresAt'];
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  factory OwnedCollectionEntry.fromInventory(
    String documentId, Map<String, dynamic> data,
  ) {
    final type = (data['type'] ?? '').toString();
    final itemId = (data['itemId'] ?? documentId).toString();
    return OwnedCollectionEntry(
      id: 'inventory:$documentId',
      type: type,
      itemId: itemId,
      bubbleId: (data['bubbleId'] ?? '').toString(),
      themeId: (data['themeId'] ?? '').toString(),
      name: (data['name'] ?? itemId).toString(),
      source: (data['source'] ?? 'inventory').toString(),
      senderName: (data['giftedBy'] ?? '').toString(),
      expiresAt: expiryOf(data),
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  factory OwnedCollectionEntry.fromReceived(
    String documentId, Map<String, dynamic> data,
  ) => OwnedCollectionEntry(
    id: 'received:$documentId',
    type: (data['type'] ?? 'gift').toString(),
    itemId: (data['itemId'] ?? data['giftId'] ?? '').toString(),
    name: (data['nameAr'] ?? data['name'] ?? data['giftId'] ?? 'Gift').toString(),
    source: 'received_gift',
    senderName: (data['senderName'] ?? '').toString(),
    expiresAt: expiryOf(data),
    quantity: (data['quantity'] as num?)?.toInt() ?? 1,
  );

  factory OwnedCollectionEntry.fromRoomReward(
    String documentId, Map<String, dynamic> data,
  ) => OwnedCollectionEntry(
    id: 'reward:$documentId',
    type: 'reward',
    itemId: (data['claimedItemId'] ?? documentId).toString(),
    name: (data['level'] is num)
        ? 'Room level ${data['level']}'
        : 'Room reward',
    source: 'room_level_reward',
    expiresAt: expiryOf(data),
    pendingReward: data['claimedAt'] == null,
  );

  factory OwnedCollectionEntry.fromLegacyBackground(
    String documentId, Map<String, dynamic> data,
  ) => OwnedCollectionEntry(
    id: 'legacy:$documentId',
    type: 'background',
    itemId: (data['itemId'] ?? documentId).toString(),
    themeId: (data['themeId'] ?? documentId).toString(),
    name: (data['name'] ?? documentId).toString(),
    source: (data['source'] ?? 'room_level_reward').toString(),
    expiresAt: expiryOf(data),
  );
}
