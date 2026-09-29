import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/data/classic_gift_catalog.dart';
import 'package:worldvoice/features/rooms/presentation/classic_gift_visual.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first-tier gift is borderless and animates for preview',
      (tester) async {
    final designs = await ClassicGiftCatalog.load();
    final butterfly = designs.firstWhere(
        (gift) => gift.id == 'classic_luminous_butterfly');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: ClassicGiftVisual(gift: butterfly, animate: true),
        ),
      ),
    ));
    expect(find.byType(Card), findsNothing);
    expect(find.text('🦋'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 180));
    expect(tester.takeException(), isNull);
  });
}
