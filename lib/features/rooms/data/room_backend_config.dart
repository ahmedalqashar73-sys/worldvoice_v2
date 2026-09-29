import 'package:flutter/foundation.dart';

/// One token backend for every room feature.
/// Local loopback belongs to USB-only debug sessions, never a published APK.
class RoomBackendConfig {
  RoomBackendConfig._();

  // The existing public, persistent WorldVoice token Worker. Having the
  // same fallback as the Android test build makes plain `flutter run` work
  // without fragile per-terminal launch flags. Override for other environments.
  static const String baseUrl = String.fromEnvironment(
    'WORLDVOICE_ROOM_BACKEND_URL',
    defaultValue: 'https://worldvoice-agora-token.worldvoice.workers.dev',
  );

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
