import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice_v2/features/chat/presentation/worldvoice_chat_gift_card.dart';

void main() {
  test('approved gift keeps its original asset identifier', () {
    const event = <String, dynamic>{
      'type': 'gift', 'giftId': 'wv_gift_076',
      'senderName': 'Ahmed', 'recipientName': 'Mimi',
      'points': 180,
    };
    expect(WorldVoiceChatGiftCard.itemIdOf(event), 'wv_gift_076');
    expect(WorldVoiceChatGiftCard.kindOf(event), 'gift');
  });

  test('cosmetic gifts resolve to actual catalog artwork', () {
    expect(WorldVoiceChatGiftCard.kindOf({
      'type': 'cosmetic_gift', 'itemId': 'frame__wv_frame_03',
    }), 'frame');
    expect(WorldVoiceChatGiftCard.kindOf({
      'type': 'cosmetic_gift', 'itemId': 'bubble__emerald',
    }), 'bubble');
    expect(WorldVoiceChatGiftCard.kindOf({
      'type': 'cosmetic_gift', 'itemId': 'background__wv_premium_04',
    }), 'background');
    expect(WorldVoiceChatGiftCard.localBackgroundAsset({
      'itemId': 'background__wv_premium_04',
    }), 'assets/backgrounds/wv_premium_04.webp');
  });

  test('retired or unknown backgrounds do not render arbitrary assets', () {
    expect(WorldVoiceChatGiftCard.localBackgroundAsset({
      'itemId': 'background__not_found',
    }), isNull);
    expect(WorldVoiceChatGiftCard.localBackgroundAsset({
      'itemId': 'gift__something',
    }), isNull);
  });
}
