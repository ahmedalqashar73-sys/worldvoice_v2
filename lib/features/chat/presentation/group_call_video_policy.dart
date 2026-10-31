/// Visibility of remote Agora video is independent of the local camera.
/// Turning off your own camera must not hide other group participants.
bool showGroupRemoteVideo({
  required bool isVideoCall,
  required bool agoraJoined,
  required int remoteVideoStreams,
}) {
  return isVideoCall && agoraJoined && remoteVideoStreams > 0;
}
