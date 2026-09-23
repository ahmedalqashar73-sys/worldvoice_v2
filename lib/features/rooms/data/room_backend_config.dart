class RoomBackendConfig {
  RoomBackendConfig._();

  static const String baseUrl =
      String.fromEnvironment('WORLDVOICE_ROOM_BACKEND_URL');

  static String endpoint(String path) {
    final base = baseUrl.trim();
    if (base.isEmpty) return '';
    final normalizedBase =
        base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$normalizedBase$normalizedPath';
  }
}
