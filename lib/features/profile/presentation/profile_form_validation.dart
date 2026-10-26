abstract final class ProfileFormValidation {
  static String normalizeUsername(String value) {
    return value.trim().toLowerCase().replaceFirst('@', '');
  }

  static bool isValidUsername(String value) {
    return RegExp(r'^[a-z0-9_]{1,20}$').hasMatch(normalizeUsername(value));
  }

  static bool hasName(String value) => value.trim().isNotEmpty;
}
