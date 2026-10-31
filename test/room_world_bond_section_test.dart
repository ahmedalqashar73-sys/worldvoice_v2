import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/presentation/room_world_bond_section.dart';

void main() {
  Widget scene({
    required bool self,
    required ValueChanged<String?> onOpen,
    Future<Map<String, dynamic>> Function()? overviewLoader,
  }) => MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: SizedBox(
      width: 390,
      child: RoomWorldBondSection(
        userId: self ? 'owner' : 'friend',
        isSelf: self,
        isArabic: true,
        onOpen: onOpen,
        overviewLoader: overviewLoader ??
            () async => {'bonds': <Map<String, dynamic>>[]},
      ),
    ))),
  );

  testWidgets('host and listeners have the same four WorldBond entry points',
      (tester) async {
    final openings = <String?>[];
    await tester.pumpWidget(scene(
      self: true,
      onOpen: openings.add,
    ));
    await tester.pumpAndSettle();
    for (final type in ['learning', 'language', 'friend', 'duo']) {
      expect(find.byKey(ValueKey('room-worldbond-$type')), findsOneWidget);
    }
    expect(find.byIcon(Icons.add_circle_rounded), findsNWidgets(4));
    expect(find.text('رفيق التعلّم'), findsOneWidget);
    expect(find.text('رفيق اللغة'), findsOneWidget);
    expect(find.text('صديق مميز'), findsOneWidget);
    expect(find.text('ثنائي WorldVoice'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('room-worldbond-learning')),
    );
    await tester.tap(find.byKey(const ValueKey('room-worldbond-learning')));
    expect(openings, ['learning']);
  });

  testWidgets('four slots stay compact and open only the selected gallery',
      (tester) async {
    final openings = <String?>[];
    await tester.pumpWidget(scene(
      self: false,
      onOpen: openings.add,
      overviewLoader: () async => {
        'bonds': [
          {'type': 'friend', 'status': 'active', 'members': ['owner', 'friend']}
        ],
      },
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('worldbond-level-badge-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('room-worldbond-section')), findsOneWidget);
    expect(find.byKey(const ValueKey('room-worldbond-gift-1')), findsNothing);
    expect(find.textContaining('100 كوين'), findsNothing);
    expect(find.text('إهداء'), findsNothing);
    expect(find.byKey(const ValueKey('room-worldbond-learning')),
      findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('room-worldbond-friend')));
    expect(openings, ['friend']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('owner sees the same four categories without self-gifting',
      (tester) async {
    final openings = <String?>[];
    await tester.pumpWidget(scene(self: true, onOpen: openings.add));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('room-worldbond-gift-1')), findsNothing);
    expect(find.text('إهداء'), findsNothing);
    await tester.tap(find.text('التفاصيل'));
    expect(openings, [null]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('occupied partner type does not offer a second invitation',
      (tester) async {
    final openings = <String?>[];
    await tester.pumpWidget(scene(
      self: false,
      onOpen: openings.add,
      overviewLoader: () async => {
        'bonds': [
          {
            'type': 'friend', 'status': 'active',
            'members': ['owner', 'another-partner'], 'level': 3,
          }
        ],
      },
    ));
    await tester.pumpAndSettle();
    expect(find.text('لديك شريك'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('room-worldbond-friend')));
    await tester.pump();
    expect(openings, isEmpty);
    expect(find.textContaining('أنهِ العلاقة الحالية'), findsOneWidget);
  });
}
