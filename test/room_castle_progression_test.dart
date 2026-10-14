import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/data/room_feature_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
  test('legacy 60-level rooms preserve visible castle levels', () {
    final oldLevelTwo = RoomFeatureState.fromData(const {
      'roomXp': 100, 'roomLevel': 2,
    });
    expect(oldLevelTwo.roomLevel, 2);
    expect(oldLevelTwo.roomXp, 300);

    final oldLevelThirty = RoomFeatureState.fromData(const {
      'roomXp': 2900, 'roomLevel': 30,
    });
    expect(oldLevelThirty.roomLevel, 30);
    expect(oldLevelThirty.roomXp, roomXpThresholdForLevel(30));

    final oldLevelSixty = RoomFeatureState.fromData(const {
      'roomXp': 5900, 'roomLevel': 60,
    });
    expect(oldLevelSixty.roomLevel, 50);
    expect(oldLevelSixty.roomXp, roomXpThresholdForLevel(50));

    final newRoom = RoomFeatureState.fromData(const {
      'roomXp': 0, 'roomLevel': 1,
    });
    expect(newRoom.roomLevel, 1);
    expect(newRoom.roomXp, 0);
  });

  test('versioned castle XP reads approved graduated curve as-is', () {
    final current = RoomFeatureState.fromData(const {
      'roomCastleXpVersion': 2, 'roomXp': 450, 'roomLevel': 2,
    });
    expect(current.roomLevel, 2);
    expect(current.roomXp, 450);
    expect(roomXpRequiredForLevel(1), 300);
    expect(roomXpRequiredForLevel(2), 400);
    expect(roomXpRequiredForLevel(3), 700);
    expect(roomXpRequiredForLevel(4), 1000);
  });

  test('all ten castle SVG assets are bundled and readable', () async {
    for (var level = 1; level <= roomCastleMaxLevel; level += 5) {
      final path = roomCastleAssetForLevel(level);
      final text = await rootBundle.loadString(path);
      expect(text, contains('<svg'));
      expect(text, contains('</svg>'));
    }
    expect(roomCastleAssetForLevel(60),
      'assets/castles/castle_tier_10.svg');
  });
  testWidgets('castle illustrations decode in the Flutter widget tree',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Column(children: [
        for (var tier = 1; tier <= roomCastleMaxTier; tier++)
          SizedBox(width: 48, height: 48,
            child: SvgPicture.asset(roomCastleAssetForLevel((tier - 1) * 5 + 1))),
      ])),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
