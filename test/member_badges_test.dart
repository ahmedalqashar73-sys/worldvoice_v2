import 'dart:async';
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
  testWidgets('Unearned level stays hidden while active VIP remains visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: MemberBadgeMarks(level: 0)),
    );
    expect(find.byType(GiftLevelBadge), findsNothing);
    expect(find.byType(VipSignatureBadge), findsNothing);
    await tester.pumpWidget(
      const MaterialApp(home: MemberBadgeMarks(level: 0, vip: 'annual')),
    );
    expect(find.byType(GiftLevelBadge), findsNothing);
    expect(find.byType(VipSignatureBadge), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(home: MemberBadgeMarks(level: 1)),
    );
    expect(find.byType(GiftLevelBadge), findsOneWidget);
  });

  testWidgets(
    'Slow server never hides the badge catalog or invents a gift level',
    (tester) async {
      final pending = Completer<Map<String, dynamic>>();
      await tester.pumpWidget(
        MaterialApp(home: MemberBadgeShop(loadStyle: () => pending.future)),
      );
      expect(find.text('Included with your VIP plan'), findsOneWidget);
      expect(find.byType(VipSignatureBadge), findsWidgets);
      expect(find.byType(GiftLevelBadge), findsNothing);
      await tester.pump(const Duration(seconds: 20));
      expect(find.text('Included with your VIP plan'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Failed account lookup keeps previews visible and retry recovers',
    (tester) async {
      var attempt = 0;
      Future<Map<String, dynamic>> load() async {
        if (attempt++ == 0) throw TimeoutException('cold server');
        return {
          'automatic': 'monthly',
          'progress': {'level': 1, 'points': 20, 'next': 50, 'remaining': 30},
          'owned': <String>[],
          'catalog': {'aurora': 120},
        };
      }

      await tester.pumpWidget(
        MaterialApp(home: MemberBadgeShop(loadStyle: load)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(VipSignatureBadge), findsWidgets);
      expect(find.byType(GiftLevelBadge), findsNothing);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Gift level 1 / 50'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
