import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/profile/presentation/world_bond_gift_gallery_tile.dart';

void main() {
  testWidgets('exclusive relationship gift uses verified price and disabled send',
      (tester) async {
    var count = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(
      child: SizedBox(width: 180,
        child: WorldBondGiftGalleryTile(
          level: 2,
          name: 'جسر الصداقة الذهبي',
          priceCoins: 200,
          isArabic: true,
          canSend: false,
          onSend: () => count++,
        ),
      ),
    ))));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('worldbond-gallery-gift-2')),
      findsOneWidget);
    expect(find.text('200 كوين'), findsOneWidget);
    final disabled = tester.widget<FilledButton>(
      find.byKey(const ValueKey('worldbond-gallery-send-2')));
    expect(disabled.onPressed, isNull);
    expect(count, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the gallery delegates sending to the existing guarded handler',
      (tester) async {
    var count = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(
      child: SizedBox(width: 180,
        child: WorldBondGiftGalleryTile(
          level: 4,
          name: 'رابطة التاج الملكي',
          priceCoins: 1000,
          isArabic: true,
          canSend: true,
          onSend: () => count++,
        ),
      ),
    ))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('worldbond-gallery-send-4')));
    expect(count, 1);
    expect(tester.takeException(), isNull);
  });
}
