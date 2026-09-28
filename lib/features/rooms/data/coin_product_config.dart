import 'package:cloud_firestore/cloud_firestore.dart';

class CoinProductConfig {
  const CoinProductConfig({
    required this.id,
    required this.coins,
    required this.active,
    required this.priceUsd,
    this.webPriceId,
    this.androidProductId,
    this.iosProductId,
  });

  final String id;
  final int coins;
  final bool active;
  final double priceUsd;
  final String? webPriceId;
  final String? androidProductId;
  final String? iosProductId;

  factory CoinProductConfig.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return CoinProductConfig(
      id: doc.id,
      coins: (data['coins'] as num?)?.toInt() ?? 0,
      active: data['active'] == true,
      priceUsd: (data['priceUsd'] as num?)?.toDouble() ?? 0,
      webPriceId: data['webPriceId']?.toString(),
      androidProductId: data['androidProductId']?.toString(),
      iosProductId: data['iosProductId']?.toString(),
    );
  }
}
