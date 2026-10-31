/// Agora tile selection for a group video call. Local camera state must not
/// hide remote streams. UID 0 represents the local Flutter AgoraVideoView.
List<int> groupCallVisibleCameraUids(
  Iterable<int> remoteAgoraUids, {
  required bool isVideoCall,
  required bool isConnected,
  required bool localCameraOn,
  int maxTiles = 4,
}) {
  if (!isVideoCall || !isConnected || maxTiles < 1) {
    return const <int>[];
  }
  final remote = remoteAgoraUids.where((uid) => uid > 0).toSet();
  final limit = localCameraOn ? maxTiles - 1 : maxTiles;
  final selected = remote.take(limit).toList(growable: true);
  if (localCameraOn) selected.add(0);
  return List<int>.unmodifiable(selected);
}

int groupCallVideoColumnCount(int tileCount) => tileCount <= 1 ? 1 : 2;
