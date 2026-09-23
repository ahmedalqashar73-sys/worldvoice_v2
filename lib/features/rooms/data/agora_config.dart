class AgoraConfig {
  AgoraConfig._();

  static const String appId =
      String.fromEnvironment('AGORA_APP_ID');

  static const String tempToken =
      String.fromEnvironment('AGORA_TEMP_TOKEN');

  static const String tokenEndpoint =
      String.fromEnvironment('AGORA_TOKEN_ENDPOINT');

  static bool get isConfigured => appId.trim().isNotEmpty;
}
