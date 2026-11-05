import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/profile/presentation/world_bond_gift_art.dart';

void main() {
  testWidgets('all relationships reuse the same four gift assets with their own tint', (tester) async {
    for (final type in ['learning', 'language', 'friend', 'duo']) {
      for (var level = 1; level <= 4; level++) {
        await tester.pumpWidget(MaterialApp(home: Scaffold(
          body: WorldBondGiftArt(level: level, relationshipType: type, size: 96),
        )));
        final image = tester.widget<Image>(find.byType(Image));
        expect(((image.image as ResizeImage).imageProvider as AssetImage).assetName,
          'assets/world_bond/gift_0$level.webp');
        expect(tester.widget<ShaderMask>(find.byType(ShaderMask)).blendMode,
          BlendMode.modulate);
        expect(tester.takeException(), isNull);
      }
    }
  });
}
