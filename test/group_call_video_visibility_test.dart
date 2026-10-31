import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/chat/presentation/group_call_video_policy.dart';

void main() {
  test('local camera off never hides connected remote group video', () {
    expect(showGroupRemoteVideo(
      isVideoCall: true, agoraJoined: true, remoteVideoStreams: 3,
    ), isTrue);
  });

  test('audio-only calls do not allocate remote camera tiles', () {
    expect(showGroupRemoteVideo(
      isVideoCall: false, agoraJoined: true, remoteVideoStreams: 3,
    ), isFalse);
  });

  test('a disconnected user or empty camera roster shows no video', () {
    expect(showGroupRemoteVideo(
      isVideoCall: true, agoraJoined: false, remoteVideoStreams: 3,
    ), isFalse);
    expect(showGroupRemoteVideo(
      isVideoCall: true, agoraJoined: true, remoteVideoStreams: 0,
    ), isFalse);
  });
}
