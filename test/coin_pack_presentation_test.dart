import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/data/coin_product_config.dart';

void main() {
  test('previews the nine approved coin pack sizes only', () {
    expect(CoinProductConfig.proposedPackSizes,
        [10, 50, 100, 500, 1000, 2000, 3000, 5000, 10000]);
    expect(CoinProductConfig.proposedPackSizes.toSet(), hasLength(9));
  });
  test('a planned pack cannot launch card checkout before approval', () {
    for (final coins in CoinProductConfig.proposedPackSizes) {
      final pack = CoinProductConfig(id: 'coins_$coins',
          coins: coins, priceUsd: null, active: false);
      expect(pack.hasApprovedWebPrice, isFalse);
    }
  });
}
