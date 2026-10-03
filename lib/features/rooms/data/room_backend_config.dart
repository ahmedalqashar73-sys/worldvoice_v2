import 'package:flutter/foundation.dart';

/// One token backend for every room feature.
/// Local loopback belongs to USB-only debug sessions, never a published APK.
class RoomBackendConfig {
  RoomBackendConfig._();

  // Keep plain `flutter run` working with the existing Agora worker, while
  // exposing whether a full WorldVoice backend was explicitly configured.
  static const String configuredBaseUrl =
      String.fromEnvironment('WORLDVOICE_ROOM_BACKEND_URL');

  static const String _agoraWorkerFallback =
      'https://worldvoice-agora-token.worldvoice.workers.dev';

  static String get baseUrl {
    final configured = configuredBaseUrl.trim();
    return configured.isNotEmpty ? configured : _agoraWorkerFallback;
  }

  static String get configurationError {
    final base = baseUrl.trim();
    if (base.isEmpty) {
      return 'WorldVoice room server URL is missing. Build with '
          '--dart-define=WORLDVOICE_ROOM_BACKEND_URL=https://YOUR_BACKEND';
    }
    final uri = Uri.tryParse(base);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return 'Invalid WorldVoice room server URL. Use the HTTPS service URL.';
    }
    if (kReleaseMode && uri.scheme != 'https') {
      return 'The published WorldVoice app requires an HTTPS room server. '
          '127.0.0.1 and local HTTP can only be used in debug mode.';
    }
    return '';
  }

  static String endpoint(String path) {
    if (configurationError.isNotEmpty) return '';
    final base = baseUrl.trim();
    final normalizedBase =
        base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$normalizedBase$normalizedPath';
  }
}
