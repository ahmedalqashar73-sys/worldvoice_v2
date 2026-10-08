import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/core/widgets/worldvoice_avatar_frame.dart';

void main() {
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
    for (final id in ['frame__wv_frame_01', 'frame__wv_frame_09',
      'frame__wv_frame_34', 'frame__wv_frame_-1', 'frame__wv_frame_99', 'unknown']) {
      expect(WorldVoiceAvatarFrame.artworkIndex(id), isNull,
          reason: '$id must not bypass catalog validation');
    }
    // Existing accounts keep their previously selected free frames.
    expect(WorldVoiceAvatarFrame.isFree('free_soft_green'), isTrue);
    expect(WorldVoiceAvatarFrame.isFree('frame__wv_frame_02'), isFalse);
  });

  testWidgets('free artwork frame accepts an avatar child', (tester) async {
    await tester.pumpWidget(const MaterialApp(
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
    ));
    await tester.pump();
    expect(find.byType(WorldVoiceAvatarFrame), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
