import 'package:flutter/foundation.dart';

/// One token backend for every room feature.
/// Local loopback belongs to USB-only debug sessions, never a published APK.
class RoomBackendConfig {
  RoomBackendConfig._();

  // The Groq-enabled unified backend is the single default for new builds.
  // Other deployed URLs can still be selected explicitly during migration.
  static const String configuredBaseUrl = String.fromEnvironment(
    'WORLDVOICE_ROOM_BACKEND_URL',
    defaultValue: 'https://worldvoice-teacher-ai.onrender.com',
  );

  static String get baseUrl => configuredBaseUrl.trim();

  // AI and speech may be deployed separately from the legacy rooms/economy
  // backend. Keep Agora, gifts, and purchases on their existing endpoint.
  static const String configuredAiBaseUrl = String.fromEnvironment(
    'WORLDVOICE_AI_BACKEND_URL',
    defaultValue: 'https://worldvoice-teacher-ai.onrender.com',
  );

  static String aiEndpoint(String path) {
    final base = configuredAiBaseUrl.trim();
    if (base.isEmpty) return endpoint(path);
    final uri = Uri.tryParse(base);
    if (uri == null || !uri.hasAuthority ||
        uri.scheme != 'https' || uri.userInfo.isNotEmpty ||
        uri.hasQuery || uri.hasFragment) {
      return '';
    }
    final normalized = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    return '$normalized${path.startsWith('/') ? path : '/$path'}';
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
