import 'package:cloud_firestore/cloud_firestore.dart';

/// Read-only catalog data. Billing prices shown in-app always come from the
/// Google Play / App Store product details, never from a client-supplied value.
class CoinProductConfig {
  const CoinProductConfig({
    required this.id,
    required this.priceUsd,
    required this.coins,
    required this.active,
    this.androidProductId,
    this.iosProductId,
    this.webPriceId,
  });

  final String id;
  final double? priceUsd;
  final int coins;
  final bool active;
  final String? androidProductId;
  final String? iosProductId;
  final String? webPriceId;

  bool get hasApprovedWebPrice =>
      active && priceUsd != null && priceUsd! > 0 &&
      webPriceId?.trim().isNotEmpty == true;

  factory CoinProductConfig.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return CoinProductConfig(
      id: doc.id,
      priceUsd: (data['priceUsd'] as num?)?.toDouble(),
      coins: (data['coins'] as num?)?.toInt() ?? 0,
      active: data['active'] == true,
      androidProductId: data['androidProductId']?.toString(),
      iosProductId: data['iosProductId']?.toString(),
      webPriceId: data['webPriceId']?.toString(),
    );
  }
}
