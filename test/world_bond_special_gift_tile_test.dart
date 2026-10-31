import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/profile/presentation/world_bond_special_gift_tile.dart';

void main() {
  final gifts = <(int, String, int)>[
    (1, 'وعد الزمرد', 100),
    (2, 'جسر الصداقة الذهبي', 200),
    (3, 'انسجام الكريستال', 500),
    (4, 'رابطة التاج الملكي', 1000),
  ];

  for (final gift in gifts) {
    testWidgets('WorldBond level ${gift.$1} gift is visually isolated',
        (tester) async {
      var sends = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Center(child: SizedBox(
          width: 360,
          child: WorldBondSpecialGiftTile(
            level: gift.$1,
            name: gift.$2,
            priceCoins: gift.$3,
            isArabic: true,
            canSend: true,
            onSend: () => sends += 1,
          ),
        ))),
      ));
      expect(find.text(gift.$2), findsOneWidget);
      expect(find.text('${gift.$3}'), findsOneWidget);
      expect(find.text('LV ${gift.$1}'), findsOneWidget);
      await tester.tap(find.text('إهداء'));
      expect(sends, 1);
    });
  }

  testWidgets('No accepting relationship means paid button disabled',
      (tester) async {
    var sends = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(
        width: 360,
        child: WorldBondSpecialGiftTile(
          level: 4,
          name: 'Royal Bond',
          priceCoins: 1000,
          isArabic: false,
          canSend: false,
          onSend: () => sends += 1,
        ),
      ))),
    ));
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    expect(sends, 0);
  });
}
