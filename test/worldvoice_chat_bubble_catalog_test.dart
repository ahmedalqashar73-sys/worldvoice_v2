import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/data/chat_bubble_catalog.dart';

void main() {
  test('WorldVoice has 15 unique designs: 12 coin and 3 VIP', () {
    expect(WorldVoiceChatBubbles.designs.length, 15);
    expect(WorldVoiceChatBubbles.designs.map((b) => b.id).toSet().length, 15);
    expect(WorldVoiceChatBubbles.designs.where((b) => b.isVip).length, 3);
  });

  test('Approved coin prices match the three durations', () {
    for (final tier in <ChatBubbleTier, List<int>>{
      ChatBubbleTier.classic: [25, 80, 600],
      ChatBubbleTier.premium: [60, 180, 1500],
      ChatBubbleTier.royal: [120, 360, 3000],
    }.entries) {
      final designs = WorldVoiceChatBubbles.designs
          .where((b) => b.tier == tier.key).toList();
      expect(designs.length, 4);
      for (final design in designs) {
        expect(design.price(7), tier.value[0]);
        expect(design.price(30), tier.value[1]);
        expect(design.price(null), tier.value[2]);
        expect(design.storeId(7), 'bubble__${design.id}__7');
        expect(design.storeId(30), 'bubble__${design.id}__30');
        expect(design.storeId(null), 'bubble__${design.id}__permanent');
      }
    }
  });

  test('invalid designs never render as paid cosmetics', () {
    expect(WorldVoiceChatBubbles.find(null), isNull);
    expect(WorldVoiceChatBubbles.find('free'), isNull);
    expect(WorldVoiceChatBubbles.find('made_up'), isNull);
  });
}
