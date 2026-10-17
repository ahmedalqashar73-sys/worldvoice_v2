import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/presentation/room_games_sheet.dart';
import 'package:worldvoice/features/rooms/services/room_quiz_service.dart';

class FakeGames extends RoomGamesService {
  FakeGames(this.data) : super(roomId: 'test-room');
  Map<String, dynamic> data;
  String? chosenLevel, chosenMode, chosenLanguage;
  int answers = 0;
  @override
  Future<Map<String, dynamic>> status() async => data;

  @override
  Future<Map<String, dynamic>> start({
    required String mode, required String level, required String language,
  }) async {
    chosenMode = mode;
    chosenLevel = level;
    chosenLanguage = language;
    return {'ok': true};
  }

  @override
  Future<Map<String, dynamic>> answer({
    required String sessionId, required int wordIndex, required String answer,
  }) async {
    answers++;
    return {'ok': true, 'correct': true, 'pointsAwarded': 10};
  }
}

Map<String, dynamic> lobby() => {
  'ok': true, 'languages': ['en'], 'remaining': {
    'vocabulary': 5, 'guess': 5,
  }, 'active': false, 'hostId': 'host',
};

Map<String, dynamic> live({required String mode, required bool canAnswer}) => {
  ...lobby(), 'active': true, 'finished': false,
  'sessionId': 'r1', 'mode': mode, 'level': 'beginner', 'language': 'en',
  'questionIndex': 0, 'secondsLeft': 30, 'canAnswer': canAnswer,
  'answered': false, 'question': {
    'clue': mode == 'guess' ? 'L P P A E'
      : 'A round fruit that is often red or green.',
  },
  'leaderboard': [],
};

void main() {
  testWidgets('host selects the difficulty for the shared room session',
      (tester) async {
    final fake = FakeGames(lobby());
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: RoomGamesSheet(roomId: 'test-room', isHost: true, service: fake))));
    await tester.pumpAndSettle();
    expect(find.text('Host chooses the game and level'), findsOneWidget);
    expect(find.text('5 words, 30 seconds per word · 5 of 5 free starts left'),
        findsOneWidget);
    await tester.tap(find.text('Beginner').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Advanced').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start session'));
    await tester.pump();
    expect(fake.chosenMode, 'vocabulary');
    expect(fake.chosenLevel, 'advanced');
    expect(fake.chosenLanguage, 'en');
    expect(tester.takeException(), isNull);
  });

  testWidgets('listener can submit Vocabulary but cannot play Guess the Word',
      (tester) async {
    final fake = FakeGames(live(mode: 'vocabulary', canAnswer: true));
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: RoomGamesSheet(roomId: 'test-room', isHost: false, service: fake))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Word 1/5'), findsOneWidget);
    expect(find.text('Your answer'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'apple');
    await tester.tap(find.text('Submit'));
    await tester.pump();
    expect(fake.answers, 1);
    fake.data = live(mode: 'guess', canAnswer: false);
    await tester.pump(const Duration(seconds: 5));
    expect(find.textContaining('stage-only'), findsWidgets);
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
