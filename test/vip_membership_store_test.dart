import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/profile/presentation/vip_membership_screen.dart';

void main() {
  testWidgets('Free membership is clearly displayed without pretending VIP is active',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: SingleChildScrollView(
        child: VipMembershipHighlights(isVip:false, arabic:true)),
    )));
    expect(find.text('عضويتك الحالية: Free'), findsOneWidget);
    expect(find.text('مميزات VIP الحالية'), findsOneWidget);
    expect(find.text('دروس أكاديمية غير محدودة'), findsOneWidget);
    expect(find.text('بدون إعلانات'), findsOneWidget);
    expect(find.text('إخفاء زيارات البروفايل'), findsOneWidget);
    expect(find.text('عضويتك VIP مفعّلة'), findsNothing);
  });

  testWidgets('VIP status is shown only when the server-provided flag is true',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: SingleChildScrollView(
        child: VipMembershipHighlights(isVip:true, arabic:false)),
    )));
    expect(find.text('Your VIP membership is active'), findsOneWidget);
    expect(find.text('Your current plan: Free'), findsNothing);
    expect(find.text('Unlimited Academy lessons'), findsOneWidget);
  });

  test('Subscription identifiers default to unconfigured in test builds', () {
    expect(VipStoreConfiguration.monthlyProductId, isNull);
  });
}
