import 'room_backend_config.dart';

class AgoraConfig {
  AgoraConfig._();

  static const String appId =
      String.fromEnvironment('AGORA_APP_ID');

  static const String tempToken =
      String.fromEnvironment('AGORA_TEMP_TOKEN');

  static const String _explicitTokenEndpoint =
      String.fromEnvironment('AGORA_TOKEN_ENDPOINT');

  static String get tokenEndpoint {
    final explicit = _explicitTokenEndpoint.trim();
    return explicit.isNotEmpty
        ? explicit
        : RoomBackendConfig.endpoint('/agora/token');
  }

  static bool get isConfigured => appId.trim().isNotEmpty;
}
