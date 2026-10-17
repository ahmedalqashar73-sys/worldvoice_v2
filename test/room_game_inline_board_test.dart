import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/data/room_chat_message.dart';
import 'package:worldvoice/features/rooms/presentation/room_conversation_panel.dart';
import 'package:worldvoice/features/rooms/presentation/room_game_inline_board.dart';
import 'package:worldvoice/features/rooms/presentation/room_stage_grid.dart';
import 'package:worldvoice/features/rooms/data/room_stage_models.dart';

void main() {
  testWidgets('question sits between first and second seat row without a modal',
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
        SizedBox(height: 420, child: RoomStageGrid(
          seats: [
            for (var i = 1; i <= 8; i++)
              RoomSeatState(index: i, role: RoomMemberRole.listener),
          ],
          onSeatTap: (_) {},
          betweenRows: RoomGameInlineBoard(status: status, isArabic: true),
        )),
        const SizedBox(height: 40, child: Text('Listener avatars')),
        const Expanded(child: SizedBox()),
      ]),
    )));
    await tester.pump();
    final firstRow = tester.getTopLeft(find.text('4'));
    final board = tester.getTopLeft(find.byKey(
      const ValueKey<String>('room-inline-games-board')));
    final secondRow = tester.getTopLeft(find.text('8'));
    final listeners = tester.getTopLeft(find.text('Listener avatars'));
    expect(firstRow.dy, lessThan(board.dy));
    expect(board.dy, lessThan(secondRow.dy));
    expect(secondRow.dy, lessThan(listeners.dy));
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
        {'name': 'Amira', 'points': 50, 'correctCount': 5},
        {'name': 'Hassan', 'points': 40, 'correctCount': 4},
        {'name': 'Sara', 'points': 30, 'correctCount': 3},
        {'name': 'Fourth user', 'points': 20, 'correctCount': 2},
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
    expect(find.text('5 correct'), findsOneWidget);
    expect(find.text('4 correct'), findsOneWidget);
    expect(find.text('3 correct'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('host can leave game mode while listeners cannot',
      (tester) async {
    var exitCount = 0;
    final status = <String, dynamic>{
      'active': false, 'finished': true, 'mode': 'guess',
      'questionIndex': 5, 'secondsLeft': 0,
      'leaderboard': <Map<String, dynamic>>[],
    };
    Widget board(bool host) => MaterialApp(home: Scaffold(
      body: RoomGameInlineBoard(status: status, isArabic: true,
        onEndGame: host ? () => exitCount++ : null),
    ));
    await tester.pumpWidget(board(true));
    await tester.pump();
    expect(find.text('إنهاء اللعبة والعودة للوضع العادي'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('room-games-return-button')));
    await tester.pump();
    expect(exitCount, 1);
    await tester.pumpWidget(board(false));
    await tester.pump();
    expect(find.byKey(const ValueKey('room-games-return-button')), findsNothing);
    expect(find.byKey(const ValueKey('room-games-exit-button')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fastest correct player locks the question and reveals answer',
      (tester) async {
    final status = <String, dynamic>{
      'active': true, 'finished': false, 'mode': 'vocabulary',
      'language': 'en', 'questionIndex': 0, 'secondsLeft': 16,
      'canAnswer': false, 'answered': false, 'roundLocked': true,
      'winner': {'name': 'Amira', 'answer': 'library'},
      'question': {'clue': 'A place where people borrow books.'},
      'leaderboard': <Map<String, dynamic>>[],
    };
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: RoomGameInlineBoard(status: status, isArabic: false),
    )));
    await tester.pump();
    expect(find.text('First correct: Amira'), findsOneWidget);
    expect(find.text('Answer: library'), findsOneWidget);
    expect(find.byKey(const ValueKey('room-game-fastest-winner')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('first-correct winner appears in chat for everyone, but no answer is posted',
      (tester) async {
    final publicPosts = <String>[];
    Widget chat(String? announcement) => MaterialApp(home: Scaffold(
      body: RoomConversationPanel(
        messages: const Stream<List<RoomChatMessage>>.empty(),
        gameRoundClosed: announcement != null,
        gameAnnouncement: announcement,
        isArabic: true,
        onSend: (value) async => publicPosts.add(value),
        onGifts: () {}, onShop: () {}, onTools: () {},
        onCaptions: () {}, onMic: () {},
        micIcon: Icons.mic, micLabel: 'مايك',
      ),
    ));
    await tester.pumpWidget(chat(null));
    await tester.pump();
    expect(find.byKey(const ValueKey(
        'room-chat-game-winner-announcement')), findsNothing);
    await tester.pumpWidget(chat('🏆 أحمد أجاب أولًا! الإجابة: مكتبة'));
    await tester.pump();
    expect(find.byKey(const ValueKey(
        'room-chat-game-winner-announcement')), findsOneWidget);
    expect(find.textContaining('أحمد أجاب أولًا'), findsOneWidget);
    expect(find.textContaining('مكتبة'), findsOneWidget);
    expect(publicPosts, isEmpty);
    await tester.pumpWidget(chat(null));
    await tester.pump();
    expect(find.byKey(const ValueKey(
        'room-chat-game-winner-announcement')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all players see server-verified right and wrong guesses in chat',
      (tester) async {
    final publicChat = <String>[];
    final events = <Map<String, dynamic>>[
      {'id': 'winner-0', 'name': 'Amira', 'answer': 'market',
       'correct': true, 'wordIndex': 0},
      {'id': 'wrong-0', 'name': 'Ahmed', 'answer': 'marcet',
       'correct': false, 'wordIndex': 0},
    ];
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: RoomConversationPanel(
        messages: const Stream<List<RoomChatMessage>>.empty(),
        isArabic: true,
        gameAnswerEvents: events,
        gameRoundClosed: true,
        gameAnnouncement: '🏆 Amira أجابت أولًا',
        onSend: (text) async => publicChat.add(text),
        onGifts: () {}, onShop: () {}, onTools: () {},
        onCaptions: () {}, onMic: () {},
        micIcon: Icons.mic, micLabel: 'Mic',
      ),
    )));
    await tester.pump();
    expect(find.byKey(const ValueKey('room-chat-game-attempt-winner-0')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('room-chat-game-attempt-wrong-0')),
        findsOneWidget);
    expect(find.textContaining('Amira: market'), findsOneWidget);
    expect(find.textContaining('✅ صح'), findsOneWidget);
    expect(find.textContaining('Ahmed: marcet'), findsOneWidget);
    expect(find.textContaining('❌ خطأ'), findsOneWidget);
    // The separate legacy "first winner" announcement should not duplicate
    // a correctly scored attempt in the verified feed.
    expect(find.byKey(const ValueKey('room-chat-game-winner-announcement')),
        findsNothing);
    expect(publicChat, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('locked answer input cannot leak into public chat',
      (tester) async {
    final privateAnswers = <String>[];
    final publicMessages = <String>[];
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: RoomConversationPanel(
        messages: const Stream<List<RoomChatMessage>>.empty(),
        isArabic: true,
        onSend: (text) async => publicMessages.add(text),
        onGameAnswer: (text) async => privateAnswers.add(text),
        gameRoundClosed: true,
        gameAnswerEnabled: false,
        onGifts: () {}, onShop: () {}, onTools: () {},
        onCaptions: () {}, onMic: () {},
        micIcon: Icons.mic, micLabel: 'Mic',
      ),
    )));
    await tester.tap(find.byKey(
      const ValueKey<String>('worldvoice-room-chat-input')));
    await tester.pump();
    expect(find.textContaining('سبقك لاعب'), findsOneWidget);
    expect(privateAnswers, isEmpty);
    expect(publicMessages, isEmpty);
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
