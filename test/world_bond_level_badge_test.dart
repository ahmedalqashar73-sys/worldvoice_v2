import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/profile/presentation/world_bond_level_badge.dart';

void main() {
  testWidgets('five distinctive badges follow server WorldBond levels',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              WorldBondLevelBadge(level: 1),
              WorldBondLevelBadge(level: 2),
              WorldBondLevelBadge(level: 3),
              WorldBondLevelBadge(level: 4),
              WorldBondLevelBadge(level: 5),
            ],
          ),
        ),
      ),
    ));
    for (var level = 1; level <= 5; level++) {
      expect(find.byKey(ValueKey('worldbond-level-badge-$level')),
          findsOneWidget);
    }
    expect(find.text('زمرد · LV1'), findsOneWidget);
    expect(find.text('سماوي · LV2'), findsOneWidget);
    expect(find.text('بنفسجي · LV3'), findsOneWidget);
    expect(find.text('ذهبي · LV4'), findsOneWidget);
    expect(find.text('ملكي · LV5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
