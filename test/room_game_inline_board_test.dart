import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/data/room_chat_message.dart';
import 'package:worldvoice/features/rooms/presentation/room_conversation_panel.dart';
import 'package:worldvoice/features/rooms/presentation/room_game_inline_board.dart';

void main() {
  testWidgets('question is visible under stage, above listeners without a modal',
      (tester) async {
    final status = <String, dynamic>{
      'active': true, 'finished': false, 'mode': 'vocabulary',
      'language': 'en', 'questionIndex': 1, 'secondsLeft': 24,
      'canAnswer': true, 'answered': false,
      'question': {'clue': 'A place where people borrow books.'},
      'leaderboard': <Map<String, dynamic>>[],
    };
    await tester.pumpWidget(MaterialApp(home: Scaffold(body:
      Column(children: [
        const SizedBox(height: 80, child: Text('Eight speaker seats')),
        RoomGameInlineBoard(status: status, isArabic: true),
        const SizedBox(height: 40, child: Text('Listener avatars')),
        const Expanded(child: SizedBox()),
      ]),
    )));
    await tester.pump();
    final stage = tester.getTopLeft(find.text('Eight speaker seats'));
    final board = tester.getTopLeft(find.byKey(
      const ValueKey<String>('room-inline-games-board')));
    final listeners = tester.getTopLeft(find.text('Listener avatars'));
    expect(stage.dy, lessThan(board.dy));
    expect(board.dy, lessThan(listeners.dy));
    expect(find.text('A place where people borrow books.'), findsOneWidget);
    expect(find.textContaining('24s'), findsOneWidget);
    expect(find.textContaining('library'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
  });

  testWidgets('finished session has only the three podium places',
      (tester) async {
    final status = <String, dynamic>{
      'active': false, 'finished': true, 'mode': 'guess',
      'questionIndex': 5, 'secondsLeft': 0,
      'leaderboard': [
        {'name': 'Amira', 'points': 50},
        {'name': 'Hassan', 'points': 40},
        {'name': 'Sara', 'points': 30},
        {'name': 'Fourth user', 'points': 20},
      ],
    };
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: RoomGameInlineBoard(status: status, isArabic: false),
    )));
    await tester.pump();
    expect(find.text('Amira'), findsOneWidget);
    expect(find.text('Hassan'), findsOneWidget);
    expect(find.text('Sara'), findsOneWidget);
    expect(find.text('Fourth user'), findsNothing);
    expect(find.text('🥇'), findsOneWidget);
    expect(find.text('🥈'), findsOneWidget);
    expect(find.text('🥉'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('room chat composer sends game answers privately, not into chat',
      (tester) async {
    final publicMessages = <String>[];
    final privateAnswers = <String>[];
    Widget conversation({bool submitted = false}) =>
      MaterialApp(home: Scaffold(body: RoomConversationPanel(
        messages: const Stream<List<RoomChatMessage>>.empty(),
        isArabic: false,
        onSend: (text) async => publicMessages.add(text),
        onGameAnswer: (word) async => privateAnswers.add(word),
        gameAnswerEnabled: true,
        gameAnswerSubmitted: submitted,
        onGifts: () {}, onShop: () {}, onTools: () {},
        onCaptions: () {}, onMic: () {},
        micIcon: Icons.mic, micLabel: 'Mic',
      )));
    await tester.pumpWidget(conversation());
    await tester.tap(find.byKey(const ValueKey<String>('worldvoice-room-chat-input')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'library');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
    expect(privateAnswers, ['library']);
    expect(publicMessages, isEmpty);

    await tester.pumpWidget(conversation(submitted: true));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('worldvoice-room-chat-input')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Hello friends');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
    expect(publicMessages, ['Hello friends']);
    expect(privateAnswers, ['library']);
    expect(tester.takeException(), isNull);
  });
}
