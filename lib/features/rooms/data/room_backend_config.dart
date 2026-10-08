import 'package:flutter/foundation.dart';

/// One token backend for every room feature.
/// Local loopback belongs to USB-only debug sessions, never a published APK.
class RoomBackendConfig {
  RoomBackendConfig._();

  // The deployed unified WorldVoice backend is now the default for plain
  // `flutter run`. A dart-define can still override it per environment.
  static const String configuredBaseUrl = String.fromEnvironment(
    'WORLDVOICE_ROOM_BACKEND_URL',
    defaultValue: 'https://worldvoice-v2.onrender.com',
  );

  static String get baseUrl => configuredBaseUrl.trim();

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
