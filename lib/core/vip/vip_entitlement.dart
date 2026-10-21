import 'package:cloud_firestore/cloud_firestore.dart';

/// Consistent client-side VIP display/feature gating.
/// Paid entitlements must also be verified by the backend for protected APIs.
class VipEntitlement {
  const VipEntitlement._();

  static bool isActive(Map<String, dynamic>? profile, {DateTime? now}) {
    if (profile?['isVip'] != true) return false;

    final rawExpiry = profile?['vipExpiresAt'];
    // Legacy/admin grants without an expiry remain supported.
    if (rawExpiry == null) return true;

    final DateTime? expiry;
    if (rawExpiry is Timestamp) {
      expiry = rawExpiry.toDate();
    } else if (rawExpiry is DateTime) {
      expiry = rawExpiry;
    } else if (rawExpiry is String) {
      expiry = DateTime.tryParse(rawExpiry);
    } else {
      return false; // Fail closed on invalid or unrecognized expiry values.
    }

    return expiry != null && expiry.isAfter(now ?? DateTime.now());
  }
}
