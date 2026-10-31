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

  testWidgets('WorldBond gift prices are exclusive and open the real gift page',
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
    for (final level in [1, 2, 3, 4]) {
      expect(find.byKey(ValueKey('room-worldbond-gift-$level')),
          findsOneWidget);
    }
    for (final price in [100, 200, 500, 1000]) {
      expect(find.textContaining('$price كوين'), findsOneWidget);
    }
    await tester.ensureVisible(
      find.byKey(const ValueKey('room-worldbond-gift-4')),
    );
    await tester.tap(find.byKey(const ValueKey('room-worldbond-gift-4')));
    expect(openings, ['gifts']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('self preview cannot invoke a paid send operation',
      (tester) async {
    final openings = <String?>[];
    await tester.pumpWidget(scene(self: true, onOpen: openings.add));
    await tester.pumpAndSettle();
    expect(find.textContaining('لا يمكن إرسال هدية لنفسك'), findsOneWidget);
    expect(find.text('إهداء'), findsNothing);
    await tester.ensureVisible(
      find.byKey(const ValueKey('room-worldbond-open-full')),
    );
    await tester.tap(find.byKey(const ValueKey('room-worldbond-open-full')));
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
