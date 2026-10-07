import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/data/room_feature_models.dart';
import 'package:worldvoice/features/rooms/services/room_feature_service.dart';

void main() {
  test('ordinary app builds never enable free friend previews', () async {
    expect(RoomFeatureService.friendPreviewEnabled, isFalse);
    await expectLater(
      RoomFeatureService.sendFriendGiftPreview(
        context: 'room',
        contextId: 'demo',
        recipientId: 'friend',
        recipientName: 'Friend',
        giftId: 'wv_gift_001',
      ),
      throwsA(isA<StateError>().having(
        (error) => error.message,
        'message',
        'TEST_PREVIEWS_DISABLED',
      )),
    );
  });

  test('free preview has zero paid gift value and preserves names', () {
    final sentAt = DateTime.utc(2026, 9, 29, 12);
    final demo = RoomGiftPreview(
      id: 'ahmed',
      nonce: 'abcdefabcdefabcdefabcdef',
      senderId: 'ahmed',
      senderName: 'Ahmed',
      recipientId: 'friend',
      recipientName: 'Friend',
      giftId: 'wv_gift_010',
      sentAt: sentAt,
    );
    final visual = demo.toVisualEvent();
    expect(demo.eventKey, 'ahmed:abcdefabcdefabcdefabcdef');
    expect(visual.points, 0);
    expect(visual.senderName, 'Ahmed');
    expect(visual.recipientName, 'Friend');
    expect(visual.giftId, 'wv_gift_010');
    expect(visual.createdAt, sentAt);
  });

  test('preview chat marker only accepts approved WorldVoice ids', () {
    final marker = RoomGiftPreviewChatCodec.encode(
      giftId: 'wv_gift_054',
      recipientId: 'friend_123',
      nonce: 'abcdefabcdefabcdefabcdef',
    );
    final decoded = RoomGiftPreviewChatCodec.decode(marker);
    expect(decoded?.giftId, 'wv_gift_054');
    expect(
      () => RoomGiftPreviewChatCodec.encode(
        giftId: 'classic_old_gift',
        recipientId: 'friend_123',
        nonce: 'abcdefabcdefabcdefabcdef',
      ),
      throwsArgumentError,
    );
  });
}
