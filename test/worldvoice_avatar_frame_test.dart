import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/core/widgets/worldvoice_avatar_frame.dart';

void main() {
  test('four bundled frames are free and the remaining 29 require coins', () {
    expect(WorldVoiceAvatarFrame.freeFrameIds, hasLength(4));
    expect(WorldVoiceAvatarFrame.premiumArtworkFrameIds, hasLength(29));
    for (var i = 0; i < 33; i++) {
      final id = WorldVoiceAvatarFrame.artworkId(i);
      expect(WorldVoiceAvatarFrame.artworkIndex(id), i);
      expect(WorldVoiceAvatarFrame.isArtworkFrame(id), isTrue);
      expect(WorldVoiceAvatarFrame.isFree(id), i < 4);
      if (i >= 4) {
        expect(WorldVoiceAvatarFrame.isPremium(id), isTrue);
        expect(WorldVoiceAvatarFrame.artworkPrice(id), greaterThan(0));
      } else {
        expect(WorldVoiceAvatarFrame.artworkPrice(id), 0);
      }
    }
    expect(WorldVoiceAvatarFrame.artworkPrice('frame__art_05'), 180);
    expect(WorldVoiceAvatarFrame.artworkPrice('frame__art_33'), 850);
  });

  test('rejects IDs with the wrong free or paid prefix', () {
    for (final id in ['free_art_05', 'frame__art_04',
      'frame__art_34', 'frame__art_-1', 'frame__art_99', 'unknown']) {
      expect(WorldVoiceAvatarFrame.artworkIndex(id), isNull,
          reason: '$id must not bypass catalog validation');
    }
    // Existing accounts keep their previously selected free frames.
    expect(WorldVoiceAvatarFrame.isFree('free_soft_green'), isTrue);
    expect(WorldVoiceAvatarFrame.isFree('frame__art_05'), isFalse);
  });

  testWidgets('free artwork frame accepts an avatar child', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: WorldVoiceAvatarFrame(
            frameId: 'free_art_01',
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
