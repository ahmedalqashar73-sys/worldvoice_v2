import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/data/chat_bubble_catalog.dart';
import 'package:worldvoice/features/rooms/services/active_chat_bubble_service.dart';

void main() {
  final bought = WorldVoiceChatBubbles.find('emerald')!;
  final vip = WorldVoiceChatBubbles.find('vip_gold')!;
  final now = DateTime.utc(2026, 10, 25, 4);

  test('An owned paid design cannot be worn after expiration', () {
    expect(ActiveChatBubbleService.isAllowed(
      design: bought, profile: const {},
      owned: {
        'type': 'bubble', 'bubbleId': 'emerald', 'quantity': 1,
        'expiresAt': Timestamp.fromDate(now.subtract(const Duration(seconds: 1))),
      },
      now: now,
    ), isFalse);
    expect(ActiveChatBubbleService.isAllowed(
      design: bought, profile: const {},
      owned: {
        'type': 'bubble', 'bubbleId': 'emerald', 'quantity': 1,
        'expiresAt': Timestamp.fromDate(now.add(const Duration(days: 30))),
      },
      now: now,
    ), isTrue);
  });

  test('Lifetime ownership is allowed; unowned or malformed is rejected', () {
    expect(ActiveChatBubbleService.isAllowed(
      design: bought, profile: const {},
      owned: {'type':'bubble','bubbleId':'emerald','quantity':1,'expiresAt':null},
      now: now,
    ), isTrue);
    expect(ActiveChatBubbleService.isAllowed(
      design: bought, profile: const {},
      owned: {'type':'bubble','bubbleId':'dragon','quantity':1,'expiresAt':null},
      now: now,
    ), isFalse);
    expect(ActiveChatBubbleService.isAllowed(
      design: bought, profile: const {},
      owned: {'type':'bubble','bubbleId':'emerald','quantity':0,'expiresAt':null},
      now: now,
    ), isFalse);
  });

  test('Three exclusive cosmetics are valid only with active VIP', () {
    expect(ActiveChatBubbleService.isAllowed(
      design: vip, profile: {'isVip': true,
        'vipExpiresAt': Timestamp.fromDate(now.add(const Duration(days: 2)))},
      owned: null, now: now), isTrue);
    expect(ActiveChatBubbleService.isAllowed(
      design: vip, profile: {'isVip': true,
        'vipExpiresAt': Timestamp.fromDate(now.subtract(const Duration(days: 1)))},
      owned: null, now: now), isFalse);
    expect(ActiveChatBubbleService.isAllowed(
      design: vip, profile: {'isVip': false},
      owned: null, now: now), isFalse);
  });
}
