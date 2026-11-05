import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/profile/presentation/world_bond_level_badge.dart';
import 'package:worldvoice/features/profile/presentation/world_bond_identity.dart';

void main() {
  testWidgets('relationship emblem stays the same as the level advances', (tester) async {
    for (final type in ['learning', 'language', 'friend', 'duo']) {
      for (final level in [1, 2, 4, 5]) {
        await tester.pumpWidget(MaterialApp(home: Scaffold(
          body: WorldBondLevelBadge(level: level, relationshipType: type),
        )));
        expect(find.text('Level $level'), findsOneWidget);
        final art = tester.widget<WorldBondBadgeArt>(find.byType(WorldBondBadgeArt));
        expect(art.relationshipType, type);
        final image = tester.widget<Image>(find.byType(Image));
        expect(((image.image as ResizeImage).imageProvider as AssetImage).assetName,
          'assets/world_bond/badge_$type.webp');
        expect(tester.takeException(), isNull);
      }
    }
    expect(['learning', 'language', 'friend', 'duo']
      .map(WorldBondIdentity.accent).toSet().length, 4);
  });
}
