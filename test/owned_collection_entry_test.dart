import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/profile/data/owned_collection_entry.dart';

void main() {
  test('received visual gift remains a receipt, not a usable asset', () {
    final gift = OwnedCollectionEntry.fromReceived('operation1', {
      'type': 'gift', 'itemId': 'wv_gift_001',
      'nameAr': 'هيبة منتصف الليل', 'senderName': 'Other user',
      'quantity': 2,
    });
    expect(gift.id, 'received:operation1');
    expect(gift.type, 'gift');
    expect(gift.isUsable, false);
    expect(gift.quantity, 2);
    expect(gift.senderName, 'Other user');
  });

  test('gifted frame is usable until its expiry', () {
    final frame = OwnedCollectionEntry.fromInventory('frame__crown', {
      'type': 'frame', 'itemId': 'frame__crown',
      'name': 'Royal Crown', 'source': 'gift', 'giftedBy': 'sender',
      'expiresAt': DateTime.now().add(const Duration(days: 2)),
    });
    expect(frame.isUsable, true);
    expect(frame.source, 'gift');
    expect(frame.senderName, 'sender');
  });

  test('expired bubble remains historical but cannot be equipped', () {
    final bubble = OwnedCollectionEntry.fromInventory('bubble__emerald', {
      'type': 'bubble', 'bubbleId': 'emerald',
      'expiresAt': DateTime.now().subtract(const Duration(hours: 1)),
    });
    expect(bubble.isExpired, true);
    expect(bubble.isUsable, false);
  });

  test('room task reward is not usable until claimed', () {
    final roomReward = OwnedCollectionEntry.fromRoomReward(
      'room_level_5', {'level': 5, 'type': 'background_month'});
    expect(roomReward.pendingReward, true);
    expect(roomReward.isUsable, false);
    expect(roomReward.source, 'room_level_reward');
  });

  test('legacy claimed room background remains visible with expiry', () {
    final reward = OwnedCollectionEntry.fromLegacyBackground(
      'wv_premium_04', {
      'themeId': 'wv_premium_04',
      'name': 'Riverside Mill',
      'source': 'room_level_reward',
      'expiresAt': DateTime.now().add(const Duration(days: 3)),
    });
    expect(reward.type, 'background');
    expect(reward.isUsable, true);
    expect(reward.themeId, 'wv_premium_04');
  });

  test('future video box reward is grouped by its authoritative inventory type', () {
    final item = OwnedCollectionEntry.fromInventory('entrance__spark', {
      'type': 'entrance', 'source': 'video_box',
      'name': 'Spark entrance', 'quantity': 1,
    });
    expect(item.type, 'entrance');
    expect(item.source, 'video_box');
    expect(item.isUsable, true);
  });
  test('castle milestone is earned, never an unclaimed consumable gift', () {
    final milestone = OwnedCollectionEntry.fromRoomReward(
      'castle_level_10', {'level': 10, 'type': 'castle_milestone'});
    expect(milestone.type, 'achievement');
    expect(milestone.pendingReward, false);
    expect(milestone.source, 'room_level_reward');
  });

  test('visual gift with empty Arabic name falls back to its English name', () {
    final receipt = OwnedCollectionEntry.fromReceived('g1', {
      'type': 'gift', 'nameAr': '', 'name': 'Midnight gift',
    });
    expect(receipt.name, 'Midnight gift');
  });

  test('claimable room background reward stays pending before activation', () {
    final eligible = OwnedCollectionEntry.fromRoomReward('reward5', {
      'level': 5, 'type': 'background_month',
    });
    expect(eligible.type, 'reward');
    expect(eligible.pendingReward, true);
    expect(eligible.isUsable, false);
  });

  test('free room gift balance is authoritative for owned gift count', () {
    final available = OwnedCollectionEntry.fromInventory(
      'gift__wv_gift_001', {
        'itemId': 'wv_gift_001',
        'type': 'gift',
        'source': 'room_reward',
        'quantity': 1,
        'freeGiftBalance': 3,
      },
    );
    expect(available.quantity, 3);
    expect(available.isUsable, true);

    final spent = OwnedCollectionEntry.fromInventory(
      'gift__wv_gift_001', {
        'type': 'gift',
        'source': 'room_reward',
        'quantity': 1,
        'freeGiftBalance': 0,
      },
    );
    expect(spent.quantity, 0);
    expect(spent.isUsable, false);
  });

  test('reward document ID resolves to the catalog image and name key', () {
    final gift = OwnedCollectionEntry.fromInventory('gift__wv_gift_001', {
      'type': 'gift', 'freeGiftBalance': 6,
    });
    expect(gift.itemId, 'wv_gift_001');
    expect(gift.quantity, 6);
    expect(gift.isUsable, true);
  });

}
