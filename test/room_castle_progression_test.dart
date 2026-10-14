import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/data/room_feature_models.dart';

void main() {
  test('room castles have exactly ten five-level tiers', () {
    expect(roomCastleMaxLevel, 50);
    expect(roomCastleMaxTier, 10);
    expect(roomCastleTierForLevel(1), 1);
    expect(roomCastleTierForLevel(5), 1);
    expect(roomCastleTierForLevel(6), 2);
    expect(roomCastleTierForLevel(25), 5);
    expect(roomCastleTierForLevel(26), 6);
    expect(roomCastleTierForLevel(50), 10);
    for (var level = 1; level <= roomCastleMaxLevel; level++) {
      expect(roomCastleTierForLevel(level), ((level - 1) ~/ 5) + 1);
    }
  });

  test('older rooms above the new cap display the final castle', () {
    expect(roomCastleTierForLevel(60), 10);
    expect(roomCastleTierForLevel(100), 10);
    expect(roomCastleTierForLevel(0), 1);
  });
}
