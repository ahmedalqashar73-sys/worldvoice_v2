import 'package:cloud_firestore/cloud_firestore.dart';

/// Consistent client-side VIP display/feature gating.
/// Paid entitlements must also be verified by the backend for protected APIs.
class VipEntitlement {
  const VipEntitlement._();

  static DateTime? expiryDate(Map<String, dynamic>? profile) {
    final rawExpiry = profile?['vipExpiresAt'];
    if (rawExpiry is Timestamp) return rawExpiry.toDate();
    if (rawExpiry is DateTime) return rawExpiry;
    if (rawExpiry is String) return DateTime.tryParse(rawExpiry);
    return null;
  }

  static bool isActive(Map<String, dynamic>? profile, {DateTime? now}) {
    if (profile?['isVip'] != true) return false;

    // Legacy/admin grants without an expiry remain supported.
    if (profile?['vipExpiresAt'] == null) return true;

    final expiry = expiryDate(profile);
    return expiry != null && expiry.isAfter(now ?? DateTime.now());
  }
}
