import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/live/data/live_video_order.dart';

void main() {
  test('Host is always first even when Agora reports a guest first', () {
    expect(
      orderLiveRemoteVideoUids([22, 33, 11], hostAgoraUid: 11),
      [11, 22, 33],
    );
  });

  test('Local host sees the guests without invented host video', () {
    expect(
      orderLiveRemoteVideoUids([22, 33], hostAgoraUid: 11),
      [22, 33],
    );
  });

  test('Ignore duplicates, invalid IDs, keep at most four cameras', () {
    expect(
      orderLiveRemoteVideoUids([3, 0, 3, -1, 2, 1, 5, 4],
          hostAgoraUid: 4),
      [4, 3, 2, 1],
    );
  });

  test('Empty roster remains empty without pretending someone is on video', () {
    expect(orderLiveRemoteVideoUids([], hostAgoraUid: 8), isEmpty);
  });

  test('Live roster excludes normal audience users even though Agora lists them', () {
    expect(
      orderActiveLiveStageUids(
        [80, 21, 90, 22, 23],
        hostAgoraUid: 80,
        acceptedGuestAgoraUids: [21, 22],
      ),
      [80, 21, 22],
    );
  });

  test('Live roster puts host first and never shows over four cameras', () {
    expect(
      orderActiveLiveStageUids(
        [101, 102, 103, 104, 105, 99],
        hostAgoraUid: 99,
        acceptedGuestAgoraUids: [101, 102, 103, 104, 105],
      ),
      [99, 101, 102, 103],
    );
  });

  test('Do not invent a guest tile while stage identities are still loading', () {
    expect(
      orderActiveLiveStageUids(
        [7, 8, 9],
        hostAgoraUid: 7,
        acceptedGuestAgoraUids: const [],
      ),
      [7],
    );
  });
}
