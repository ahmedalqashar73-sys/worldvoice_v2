class AgoraConfig {
  AgoraConfig._();

  // These project identifiers are public (already used by the existing
  // Android CI). Runtime --dart-define values still override them. The
  // private Agora App Certificate stays exclusively on the server.
  static const String appId = String.fromEnvironment(
    'AGORA_APP_ID',
    defaultValue: 'fa41476c6813471eb45c059bcb4a0e19',
  );

  static const String tempToken =
      String.fromEnvironment('AGORA_TEMP_TOKEN');

  static const String _explicitTokenEndpoint =
      String.fromEnvironment('AGORA_TOKEN_ENDPOINT');

  static const String stableTokenEndpoint =
      'https://worldvoice-agora-token.worldvoice.workers.dev/agora/token';

  static String get tokenEndpoint {
    final explicit = _explicitTokenEndpoint.trim();
    return explicit.isNotEmpty ? explicit : stableTokenEndpoint;
  }

  static List<String> get tokenEndpoints {
    final explicit = _explicitTokenEndpoint.trim();
    return <String>[
      stableTokenEndpoint,
      if (explicit.isNotEmpty && explicit != stableTokenEndpoint) explicit,
    ];
  }

  static bool get isConfigured => appId.trim().isNotEmpty;
}
