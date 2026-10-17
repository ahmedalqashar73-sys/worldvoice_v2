import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/engagement/presentation/creative_progress_screen.dart';

void main() {
  testWidgets('Creative is a compact linked profile entry with verified count',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: CreativeProfileLink(
        userId: 'test-user',
        badgeLoader: (uid) async {
          expect(uid, 'test-user');
          return {'creativeCycles': 3, 'completedCycles': 8};
        },
        onOpen: () => taps++,
      ),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Creative achievements'), findsOneWidget);
    expect(find.text('Achievements and daily check-in'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Daily activity'), findsNothing);
    expect(find.text('Attendance gifts'), findsNothing);
    await tester.tap(find.text('Creative achievements'));
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('never invents a streak when the verified count is zero',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: CreativeProfileLink(
        userId: 'new-user',
        badgeLoader: (_) async => {'creativeCycles': 0},
        onOpen: () {},
      ),
    )));
    await tester.pumpAndSettle();
    expect(find.text('0'), findsOneWidget);
    expect(find.text('413'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
