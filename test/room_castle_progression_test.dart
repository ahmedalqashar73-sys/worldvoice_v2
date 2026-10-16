import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/data/room_feature_models.dart';
import 'package:worldvoice/features/rooms/presentation/room_extras_sheet.dart';

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
  test('all ten WebP assets decode at the approved size', () async {
    final paths = <String>{};
    for (var level = 1; level <= 50; level++) {
      final path = roomCastleWebpAssetForLevel(level);
      expect(path, roomCastleWebpAssetForLevel(((level - 1) ~/ 5) * 5 + 1));
      paths.add(path);
    }
    expect(paths, hasLength(10));
    for (final path in paths) {
      final bytes = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List(
        bytes.offsetInBytes, bytes.lengthInBytes));
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 512);
      expect(frame.image.height, 512);
      frame.image.dispose();
      codec.dispose();
    }
  });

  testWidgets('actual castle widget opens and closes enlarged preview', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body:
      SizedBox(width: 100, height: 110, child: RoomCastleArtwork(level: 50)))));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    await tester.tap(find.byType(RoomCastleArtwork));
    await tester.pumpAndSettle();
    expect(find.text('Lv. 46–50'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('every XP threshold and legacy roomPoints use the same curve', () {
    for (var level = 1; level <= 50; level++) {
      final start = roomXpThresholdForLevel(level);
      expect(roomLevelFromXp(start), level);
      if (level < 50) {
        expect(roomLevelFromXp(start + roomXpRequiredForLevel(level) - 1), level);
        expect(roomLevelFromXp(start + roomXpRequiredForLevel(level)), level + 1);
      }
    }
    expect(roomCastleDisplayXp({'roomPoints': 100}), 300);
  });

  test('Flutter matches the shared backend progression contract', () {
    final rows = jsonDecode(File('test/fixtures/room_castle_progression.json').readAsStringSync()) as List;
    for (final row in rows.cast<Map<String, dynamic>>()) {
      final level = row['level'] as int;
      expect(roomXpThresholdForLevel(level), row['threshold']);
      expect(roomCastleTierForLevel(level), row['tier']);
      if (level < 50) expect(roomXpRequiredForLevel(level), row['required']);
    }
  });

  testWidgets('castle badge fits a narrow RTL header and opens missions', (tester) async {
    var opened = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Directionality(
      textDirection: TextDirection.rtl,
      child: MediaQuery(data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: SizedBox(width: 160, child: Align(alignment: Alignment.topRight,
          child: RoomCastleBadge(level: 50, onTap: () => opened = true)))),
    ))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('LEVEL 50'));
    expect(opened, isTrue);
  });

}
