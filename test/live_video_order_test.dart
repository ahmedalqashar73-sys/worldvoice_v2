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
}
