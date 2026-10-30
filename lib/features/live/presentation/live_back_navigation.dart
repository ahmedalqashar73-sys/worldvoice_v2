/// Viewer navigation policy: returning from the phone's Back button must
/// preserve an active Agora session. Explicit Leave Live and a real end
/// event are the only ways to exit a connected broadcast.
enum ViewerLiveBackAction { minimize, pop }

ViewerLiveBackAction viewerLiveBackAction({
  required bool joining,
  required bool joinFailed,
  required bool leaving,
  required bool liveEnded,
}) {
  if (joining || joinFailed || leaving || liveEnded) {
    return ViewerLiveBackAction.pop;
  }
  return ViewerLiveBackAction.minimize;
}
