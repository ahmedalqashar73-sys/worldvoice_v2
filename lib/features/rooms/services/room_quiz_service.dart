import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../data/room_backend_config.dart';
import '../data/room_feature_models.dart';

/// The canonical room quiz uses rooms/{roomId}.quiz and quiz_answers.
/// Keep reads, lifecycle updates and trusted reward finalization here so the
/// widget and other room features use the same Firestore representation.
class RoomQuizService {
  RoomQuizService({required this.roomId});

  final String roomId;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  User? get _user => FirebaseAuth.instance.currentUser;
  DocumentReference<Map<String, dynamic>> get _room =>
      _db.collection('rooms').doc(roomId);

  /// Reindex the host's selected answer after blank answer fields are removed.
  /// Do not silently switch a blank selected answer to another option.
  static int normalizedCorrectIndex(List<String> rawOptions, int chosenIndex) {
    if (chosenIndex < 0 || chosenIndex >= rawOptions.length) {
      throw StateError('Choose a correct answer.');
    }
    if (rawOptions[chosenIndex].trim().isEmpty) {
      throw StateError('The correct answer cannot be empty.');
    }
    return rawOptions
            .take(chosenIndex + 1)
            .where((value) => value.trim().isNotEmpty)
            .length -
        1;
  }

  Stream<RoomFeatureState> watchState() => _room.snapshots().map(
        (snapshot) => RoomFeatureState.fromData(
          snapshot.data() ?? const <String, dynamic>{},
        ),
      );

  Future<void> startQuiz({
    required String question,
    required List<String> options,
    required int correctIndex,
  }) async {
    // Mirror the backend validation before touching Firestore. The chosen
    // answer must refer to an actual non-empty visible option.
    final cleanQuestion = question.trim();
    final cleanOptions = options.map((value) => value.trim()).toList();
    if (cleanQuestion.isEmpty || cleanQuestion.length > 500 ||
        cleanOptions.length < 2 || cleanOptions.length > 4 ||
        cleanOptions.any((value) => value.isEmpty || value.length > 220) ||
        correctIndex < 0 || correctIndex >= cleanOptions.length) {
      throw StateError('Enter a valid question and 2–4 non-empty answers.');
    }

    final user = _user;
    if (user == null) throw StateError('Sign in is required.');
    final startEndpoint = RoomBackendConfig.endpoint('/quiz/start');
    if (startEndpoint.isNotEmpty) {
      final token = await user.getIdToken();
      if (token == null || token.isEmpty) {
        throw StateError('Could not authorize quiz creation.');
      }
      final response = await http.post(
        Uri.parse(startEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'roomId': roomId,
          'question': cleanQuestion,
          'options': cleanOptions,
          'correctIndex': correctIndex,
        }),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return; // Server holds the secret correct answer privately.
      }
      var message = 'Could not create quiz.';
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          message = body['error']?.toString() ?? message;
        }
      } catch (_) {
        // Preserve the generic error.
      }
      if (response.statusCode != 503 ||
          !message.contains('not yet enabled on the free test backend')) {
        throw StateError(message);
      }
    }
    // Free local room: validate host and room first. Practice has no coins,
    // and cannot replace a verified round if its secure backend is offline.
    final roomSnap = await _room.get();
    final roomData = roomSnap.data() ?? const <String, dynamic>{};
    if (!roomSnap.exists || roomData['isOpen'] != true ||
        roomData['hostId'] != user.uid) {
      throw StateError('Only the host of an open room can start a quiz.');
    }
    final currentQuiz = roomData['quiz'];
    if (currentQuiz is Map &&
        currentQuiz['roundId']?.toString().trim().isNotEmpty == true) {
      throw StateError(
        'A verified quiz needs the full backend to reset its answers.',
      );
    }
    final answers = await _room.collection('quiz_answers').get();
    // Firestore batches allow at most 500 writes: include one room update.
    if (answers.docs.length > 450) {
      throw StateError('Too many prior votes to reset safely in one round.');
    }
    final batch = _db.batch();
    for (final doc in answers.docs) {
      batch.delete(doc.reference);
    }
    batch.update(_room, {
      'quiz': {
        'question': cleanQuestion,
        'options': cleanOptions,
        'correctIndex': correctIndex,
        'revealed': false,
        'practiceOnly': true,
        'startedAt': FieldValue.serverTimestamp(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> answerQuiz(int optionIndex) async {
    final user = _user;
    if (user == null) return;
    if (optionIndex < 0) throw StateError('Choose a valid answer.');
    final profile = await _db.collection('users').doc(user.uid).get();
    final data = profile.data() ?? const <String, dynamic>{};

    final room = await _room.get();
    final quiz = room.data()?['quiz'];
    if (quiz is! Map || quiz['revealed'] == true) {
      throw StateError('There is no open quiz.');
    }
    final visibleOptions = quiz['options'];
    if (visibleOptions is! List || optionIndex >= visibleOptions.length) {
      throw StateError('Choose one of the displayed answers.');
    }
    final roundId = quiz['roundId']?.toString().trim() ?? '';
    await _room.collection('quiz_answers').doc(user.uid).set({
      'userId': user.uid,
      if (roundId.isNotEmpty) 'roundId': roundId,
      'displayName':
          (data['displayName'] ?? user.displayName ?? 'WorldVoice user')
              .toString(),
      'optionIndex': optionIndex,
      'answeredAt': FieldValue.serverTimestamp(),
    });
  }

  /// Use the same trusted/practice finalizer for every caller. A direct
  /// Firestore reveal could close a verified round without ranking votes.
  Future<void> revealQuiz() => finishQuiz();

  /// Free-room fallback when the Agora-only worker has no optional quiz
  /// backend. This displays practice winners but NEVER credits coins.
  Future<void> _finishPracticeQuiz() async {
    final user = _user;
    if (user == null) throw StateError('Sign in is required.');
    final room = await _room.get();
    final data = room.data() ?? const <String, dynamic>{};
    if (data['hostId'] != user.uid) {
      throw StateError('Only the host can reveal quiz results.');
    }
    final rawQuiz = data['quiz'];
    final quiz = rawQuiz is Map
        ? Map<String, dynamic>.from(rawQuiz)
        : const <String, dynamic>{};
    if (quiz['revealed'] == true) return;
    if (quiz['roundId']?.toString().trim().isNotEmpty == true) {
      throw StateError('Verified quiz results require the trusted backend.');
    }
    final originalStart = quiz['startedAt'];
    final correctIndex = (quiz['correctIndex'] as num?)?.toInt();
    if (correctIndex == null) throw StateError('No quiz to reveal.');

    final votes = await _room.collection('quiz_answers').get();
    final correct = votes.docs
        .where((doc) =>
            (doc.data()['optionIndex'] as num?)?.toInt() == correctIndex)
        .toList(growable: false);
    correct.sort((a, b) {
      final first = a.data()['answeredAt'];
      final second = b.data()['answeredAt'];
      final firstMs =
          first is Timestamp ? first.millisecondsSinceEpoch : 0x7fffffffffffffff;
      final secondMs =
          second is Timestamp ? second.millisecondsSinceEpoch : 0x7fffffffffffffff;
      final comparison = firstMs.compareTo(secondMs);
      return comparison != 0 ? comparison : a.id.compareTo(b.id);
    });

    final winners = <Map<String, dynamic>>[
      for (var i = 0; i < correct.length && i < 3; i++)
        {
          'place': i + 1,
          'userId': correct[i].id,
          'displayName':
              (correct[i].data()['displayName'] ?? 'WorldVoice user').toString(),
          'prizeCoins': 0,
        },
    ];
    await _db.runTransaction((tx) async {
      final latest = await tx.get(_room);
      final latestQuiz = latest.data()?['quiz'];
      if (latestQuiz is! Map ||
          latestQuiz['roundId']?.toString().trim().isNotEmpty == true) {
        throw StateError('The quiz changed while results were calculated.');
      }
      final latestStart = latestQuiz['startedAt'];
      if (originalStart is Timestamp && latestStart is Timestamp &&
          originalStart != latestStart) {
        throw StateError('A newer quiz started. Refresh and try again.');
      }
      if (latestQuiz['revealed'] == true ||
          latestQuiz['rewardedAt'] != null) {
        return;
      }
      tx.update(_room, {
        'quiz.revealed': true,
        'quiz.practiceOnly': true,
        'quiz.winners': winners,
        'quiz.firstPrizeCoins': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> finishQuiz() async {
    final user = _user;
    if (user == null) {
      throw StateError('Sign in is required.');
    }

    final endpoint = RoomBackendConfig.endpoint('/quiz/finish');
    if (endpoint.isEmpty) {
      await _finishPracticeQuiz();
      return;
    }

    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Could not authorize quiz finalization.');
    }

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'roomId': roomId}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Could not finish quiz.';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          message = decoded['error']?.toString() ?? message;
        }
      } catch (_) {
        // Keep the generic message.
      }
      // The free token-only worker intentionally returns this exact error
      // until a trusted auxiliary backend is configured. Practice results
      // must not award coins or falsely claim a paid prize.
      if ((response.statusCode == 503 &&
              message.contains('not yet enabled on the free test backend')) ||
          (response.statusCode == 409 &&
              message.contains('no verified private answer'))) {
        await _finishPracticeQuiz();
        return;
      }
      throw StateError(message);
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchQuizAnswers() =>
      _room.collection('quiz_answers').snapshots();

}
