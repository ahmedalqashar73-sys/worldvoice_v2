import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/core/widgets/worldvoice_avatar_frame.dart';
import 'package:worldvoice/features/rooms/presentation/room_stage_grid.dart';
import 'package:worldvoice/features/rooms/data/room_stage_models.dart';

void main() {
  testWidgets('larger room frames fit narrow and wide stages', (tester) async {
    for (final width in [296.0, 404.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                height: 294,
                child: RoomStageGrid(
                  seats: List.generate(
                    8,
                    (i) => RoomSeatState(
                      index: i,
                      role: RoomMemberRole.speaker,
                      displayName: 'Speaker $i',
                      frameId: 'free_clean_white',
                      isActiveSpeaker: i == 0,
                    ),
                  ),
                  onSeatTap: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      expect(find.byType(WorldVoiceAvatarFrame), findsNWidgets(8));
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('four bundled frames are free and the remaining 29 require coins', () {
    expect(WorldVoiceAvatarFrame.freeFrameIds, hasLength(4));
    expect(WorldVoiceAvatarFrame.premiumArtworkFrameIds, hasLength(29));
    const freeIndices = <int>{0, 8, 14, 24};
    for (var i = 0; i < 33; i++) {
      final id = WorldVoiceAvatarFrame.artworkId(i);
      expect(WorldVoiceAvatarFrame.artworkIndex(id), i);
      expect(WorldVoiceAvatarFrame.isArtworkFrame(id), isTrue);
      expect(WorldVoiceAvatarFrame.isFree(id), freeIndices.contains(i));
      if (!freeIndices.contains(i)) {
        expect(WorldVoiceAvatarFrame.isPremium(id), isTrue);
        expect(WorldVoiceAvatarFrame.artworkPrice(id), greaterThan(0));
      } else {
        expect(WorldVoiceAvatarFrame.artworkPrice(id), 0);
      }
    }
    expect(WorldVoiceAvatarFrame.artworkPrice('frame__wv_frame_02'), 360);
    expect(WorldVoiceAvatarFrame.artworkPrice('frame__wv_frame_33'), 590);
  });

  test('rejects IDs with the wrong free or paid prefix', () {
    for (final id in [
      'frame__wv_frame_01',
      'frame__wv_frame_09',
      'frame__wv_frame_34',
      'frame__wv_frame_-1',
      'frame__wv_frame_99',
      'unknown',
    ]) {
      expect(
        WorldVoiceAvatarFrame.artworkIndex(id),
        isNull,
        reason: '$id must not bypass catalog validation',
      );
    }
    // Existing accounts keep their previously selected free frames.
    expect(WorldVoiceAvatarFrame.isFree('free_soft_green'), isTrue);
    expect(WorldVoiceAvatarFrame.isFree('frame__wv_frame_02'), isFalse);
  });

  testWidgets('free artwork frame accepts an avatar child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: WorldVoiceAvatarFrame(
              frameId: 'free_clean_white',
              size: 88,
              animate: false,
              child: ColoredBox(color: Color(0xFF187E60)),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(WorldVoiceAvatarFrame), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('Frame mask protects the whole portrait at every display size', () {
    for (final diameter in [32.0, 42.0, 88.0, 160.0]) {
      final size = Size.square(diameter);
      final mask = const WorldVoiceFrameRingClipper().getClip(size);
      final center = size.center(Offset.zero);
      expect(mask.contains(center), isFalse);
      for (final offset in [
        Offset(diameter * .37, 0),
        Offset(0, diameter * .37),
        Offset(-diameter * .37, 0),
        Offset(0, -diameter * .37),
      ]) {
        expect(mask.contains(center + offset), isFalse);
      }
      expect(mask.contains(center + Offset(diameter * .44, 0)), isTrue);
    }
  });

  testWidgets('Portrait stays large and still while the rim animates', (
    tester,
  ) async {
    const portrait = Key('portrait');
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: WorldVoiceAvatarFrame(
              size: 100,
              frameId: 'frame__wv_frame_02',
              child: ColoredBox(key: portrait, color: Colors.blue),
            ),
          ),
        ),
      ),
    );
    final before = tester.getRect(find.byKey(portrait));
    expect(before.size, const Size(76, 76));
    await tester.pump(const Duration(milliseconds: 1800));
    expect(tester.getRect(find.byKey(portrait)), before);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Reduced motion stops frame animation', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Center(
            child: WorldVoiceAvatarFrame(
              size: 88,
              frameId: 'frame__wv_frame_02',
              child: ColoredBox(color: Colors.blue),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });
}
