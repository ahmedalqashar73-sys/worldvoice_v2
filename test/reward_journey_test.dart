import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/engagement/presentation/reward_journey_card.dart';
import 'package:worldvoice/features/engagement/presentation/creative_badge.dart';

void main() {
  testWidgets('claim refreshes from server and does not grant locally', (tester) async {
    var claimed = false;
    var calls = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(
      child: RewardJourneyCard(loadStatus: () async => {
        'startDay': 100, 'day': 1, 'claimedDays': claimed ? 1 : 0,
        'canClaim': !claimed, 'phase': claimed ? 'claimed' : 'ready',
        'nextAtMs': 86400000, 'serverNowMs': 0,
      }, claimReward: (body) async {
        expect(body, {'startDay': 100, 'day': 1}); calls++; claimed = true;
      }),
    ))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Claim gift'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('Claim gift'), findsNothing);
    expect(find.textContaining('Claimed ·'), findsOneWidget);
  });
  testWidgets('rest has no claim and small screen does not overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(
      child: RewardJourneyCard(loadStatus: () async => {
        'day': 4, 'claimedDays': 3, 'canClaim': false, 'phase': 'rest',
        'nextAtMs': 86400000, 'serverNowMs': 0,
      }),
    ))));
    await tester.pumpAndSettle();
    expect(find.text('Claim gift'), findsNothing);
    expect(find.textContaining('Rest day ·'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('earned creative badge describes its evidence', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body:
      AchievementMark(creativeCycles: 2, completedCycles: 3))));
    await tester.tap(find.text('Complete Creative · 2'));
    await tester.pumpAndSettle();
    expect(find.textContaining('60 minutes'), findsOneWidget);
  });
  testWidgets('unavailable rewards stay compact and retry uses server', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(
      child: RewardJourneyCard(loadStatus: () async {
        attempts++;
        throw Exception('offline');
      }),
    ))));
    await tester.pumpAndSettle();
    expect(find.text('Claim gift'), findsNothing);
    expect(tester.getSize(find.byType(Card)).height, lessThan(130));
    await tester.tap(find.byTooltip('Retry'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
  });

}
