import 'dart:async';

/// Bounds a single network-dependent Live startup step without changing
/// shared voice-room transport behavior.
Future<T> guardLiveStartup<T>(
  Future<T> work, {
  required String phase,
  required Duration timeout,
}) => work.timeout(timeout, onTimeout: () {
  throw TimeoutException('Live startup timeout: $phase', timeout);
});
