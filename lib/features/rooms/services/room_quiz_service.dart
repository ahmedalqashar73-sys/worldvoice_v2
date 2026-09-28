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
    if (question.trim().isEmpty ||
        options.length < 2 ||
        correctIndex < 0 ||
        correctIndex >= options.length) {
      throw StateError('Invalid quiz');
    }

    // Publish the new question and clear previous votes in one atomic batch.
    // A full replacement of the quiz map also clears stale winners and
    // rewardedAt from earlier rounds instead of merging nested fields.
    final answers = await _room.collection('quiz_answers').get();
    final batch = _db.batch();
    for (final doc in answers.docs) {
      batch.delete(doc.reference);
    }
    batch.update(_room, {
      'quiz': {
        'question': question.trim(),
        'options': options,
        'correctIndex': correctIndex,
        'revealed': false,
        'startedAt': FieldValue.serverTimestamp(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> answerQuiz(int optionIndex) async {
    final user = _user;
    if (user == null) return;
    final profile = await _db.collection('users').doc(user.uid).get();
    final data = profile.data() ?? const <String, dynamic>{};

    await _room.collection('quiz_answers').doc(user.uid).set({
      'userId': user.uid,
      'displayName':
          (data['displayName'] ?? user.displayName ?? 'WorldVoice user')
              .toString(),
      'optionIndex': optionIndex,
      'answeredAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> revealQuiz() => _room.update({
        // update interprets the dot as a nested field path. set(merge: true)
        // would create a literal 'quiz.revealed' key and leave the quiz open.
        'quiz.revealed': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

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
      if (latestQuiz is Map &&
          (latestQuiz['revealed'] == true || latestQuiz['rewardedAt'] != null)) {
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
      if (response.statusCode == 503 &&
          message.contains('not yet enabled on the free test backend')) {
        await _finishPracticeQuiz();
        return;
      }
      throw StateError(message);
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchQuizAnswers() =>
      _room.collection('quiz_answers').snapshots();

}
