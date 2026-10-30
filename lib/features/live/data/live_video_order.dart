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
