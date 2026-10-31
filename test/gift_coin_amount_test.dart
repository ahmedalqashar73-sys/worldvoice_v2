import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/presentation/gift_coin_amount.dart';

void main() {
  testWidgets('gift coin shows W and preserves the price in RTL', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: GiftCoinAmount(amount: 1000)),
        ),
      ),
    );
    expect(find.text('W'), findsOneWidget);
    expect(find.textContaining('1000', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
