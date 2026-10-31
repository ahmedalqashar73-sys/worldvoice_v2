import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/profile/presentation/world_bond_gift_art.dart';

void main() {
  testWidgets('four exclusive WorldBond illustrations are bundled as vectors',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              WorldBondGiftArt(level: 1, size: 96),
              WorldBondGiftArt(level: 2, size: 96),
              WorldBondGiftArt(level: 3, size: 96),
              WorldBondGiftArt(level: 4, size: 96),
            ],
          ),
        ),
      ),
    ));
    expect(find.byType(SvgPicture), findsNWidgets(4));
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
