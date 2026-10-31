import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/presentation/room_bond_chat_marks.dart';

void main() {
  Widget screen(Future<Map<String, dynamic>> Function(String) loader) =>
      MaterialApp(
        home: Scaffold(
          body: RoomBondChatMarks(
            userId: 'sample-user',
            badgeLoader: loader,
          ),
        ),
      );

  testWidgets('only active WorldBond achievements decorate room messages',
      (tester) async {
    final loadedIds = <String>[];
    await tester.pumpWidget(screen((id) async {
      loadedIds.add(id);
      return {
        'ok': true,
        'badges': <String, int>{
          'learning': 1,
          'language': 3,
          'friend': 5,
          'duo': 2,
        },
      };
    }));
    await tester.pumpAndSettle();

    expect(loadedIds, ['sample-user']);
    for (final kind in ['learning', 'language', 'friend', 'duo']) {
      expect(find.byKey(ValueKey('room-chat-bond-$kind')), findsOneWidget);
    }
    expect(find.text('LV1'), findsOneWidget);
    expect(find.text('LV3'), findsOneWidget);
    expect(find.text('LV5'), findsOneWidget);
    expect(find.text('LV2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('inactive relationships do not display badges in the room chat',
      (tester) async {
    await tester.pumpWidget(screen((_) async => {
      'ok': true,
      'badges': <String, int>{
        'learning': 0, 'language': 0, 'friend': 0, 'duo': 0,
      },
    }));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('room-chat-bond-learning')), findsNothing);
    expect(find.byKey(const ValueKey('room-chat-bond-language')), findsNothing);
    expect(find.byKey(const ValueKey('room-chat-bond-friend')), findsNothing);
    expect(find.byKey(const ValueKey('room-chat-bond-duo')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('temporary badge endpoint failure leaves chat usable',
      (tester) async {
    await tester.pumpWidget(screen((_) async {
      throw StateError('network unavailable');
    }));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('room-chat-worldbond-badges')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
