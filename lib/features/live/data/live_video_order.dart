/// Deterministic Agora participant ordering for the WorldVoice Live UI.
///
/// Agora join callbacks may list guests before the host. Keep the real host UID
/// first when connected; preserve arrival order for guests without duplicating
/// a stream. This function does not change audio/video routing or permissions.
List<int> orderLiveRemoteVideoUids(
  Iterable<int> remoteUids, {
  int? hostAgoraUid,
}) {
  final remote = remoteUids.where((uid) => uid > 0).toSet();
  final result = <int>[];
  if (hostAgoraUid != null && remote.remove(hostAgoraUid)) {
    result.add(hostAgoraUid);
  }
  result.addAll(remote);
  return result.take(4).toList(growable: false);
}

/// Live camera roster: Agora reports all connected users, including audience.
/// Only the host and guests who have accepted stage requests may get a tile.
List<int> orderActiveLiveStageUids(
  Iterable<int> connectedAgoraUids, {
  required Iterable<int> acceptedGuestAgoraUids,
  int? hostAgoraUid,
}) {
  final acceptedGuests = acceptedGuestAgoraUids
      .where((uid) => uid > 0 && uid != hostAgoraUid)
      .toSet();
  final connected = connectedAgoraUids.where((uid) => uid > 0).toSet();
  final ordered = <int>[];
  if (hostAgoraUid != null && connected.remove(hostAgoraUid)) {
    ordered.add(hostAgoraUid);
  }
  for (final uid in connected) {
    if (!acceptedGuests.contains(uid)) continue;
    ordered.add(uid);
    if (ordered.length >= 4) break;
  }
  return List<int>.unmodifiable(ordered);
}
