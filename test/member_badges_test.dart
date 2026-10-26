import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/profile/presentation/member_badges.dart';

void main() {
  testWidgets(
    'Every VIP design stays compact alongside a gift level and message',
    (tester) async {
      for (final id in [
        ...MemberBadgeCatalog.plans,
        ...MemberBadgeCatalog.extras,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 280,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: VipSignatureBadge(design: id),
                        ),
                        const WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: GiftLevelBadge(level: 50),
                        ),
                        const TextSpan(text: ' Ahmed: مرحبًا بكم'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(VipSignatureBadge)).height, 20);
        expect(
          tester.getSize(find.byType(VipSignatureBadge)).width,
          lessThan(90),
        );
      }
    },
  );
  testWidgets('Large design previews fit narrow shop cards', (tester) async {
    for (final id in MemberBadgeCatalog.plans) {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 180,
              child: VipSignatureBadge(design: id, large: true),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });
}
