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

  Future<http.Response> _postSecure(
    String route,
    Map<String, Object?> payload,
  ) async {
    final url = RoomBackendConfig.endpoint(route);
    if (url.isEmpty) {
      throw StateError('The secure quiz backend is not configured.');
    }
    final user = _user;
    if (user == null) throw StateError('Sign in is required.');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Could not authenticate this quiz request.');
    }
    return http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 25));
  }

  String _serverError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded['error']?.toString() ?? 'Quiz request failed.';
      }
    } catch (_) {
      // Return a safe generic error for non-JSON gateway failures.
    }
    return 'Quiz request failed (${response.statusCode}).';
  }

  bool _tokenOnlyWorker(http.Response response) =>
      response.statusCode == 503 &&
      _serverError(response).contains('not yet enabled on the free test backend');

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

    if (RoomBackendConfig.endpoint('/quiz/start').isNotEmpty) {
      final response = await _postSecure('/quiz/start', {
        'roomId': roomId,
        'question': question.trim(),
        'options': options,
        'correctIndex': correctIndex,
      });
      if (response.statusCode >= 200 && response.statusCode < 300) return;
      if (!_tokenOnlyWorker(response)) {
        throw StateError(_serverError(response));
      }
    }
    // Token-only workers support free practice, not monetary prizes.
    await _startPracticeQuiz(
      question: question, options: options, correctIndex: correctIndex,
    );
  }

  Future<void> _startPracticeQuiz({
    required String question,
    required List<String> options,
    required int correctIndex,
  }) async {
    // Public correctness is acceptable ONLY for explicitly non-monetary
    // practice quizzes. Secure rounds never expose the private answer key.
    final answers = await _room.collection('quiz_answers').get();
    final batch = _db.batch();
    for (final doc in answers.docs) {
      batch.delete(doc.reference);
    }
    batch.update(_room, {
      'quiz': {
        'roundId': DateTime.now().microsecondsSinceEpoch.toString(),
        'secure': false, 'practiceOnly': true,
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
    if (user == null) throw StateError('Sign in is required.');
    final room = await _room.get();
    final raw = room.data()?['quiz'];
    final quiz = raw is Map
        ? Map<String, dynamic>.from(raw)
        : const <String, dynamic>{};
    if (quiz['revealed'] == true || quiz['closed'] == true) {
      throw StateError('The quiz is already closed.');
    }
    final roundId = quiz['roundId']?.toString() ?? '';
    if (quiz['secure'] == true) {
      if (roundId.isEmpty) throw StateError('Invalid secure quiz round.');
      final response = await _postSecure('/quiz/answer', {
        'roomId': roomId, 'roundId': roundId, 'selectedIndex': optionIndex,
      });
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(_serverError(response));
      }
      return;
    }
    final profile = await _db.collection('users').doc(user.uid).get();
    final data = profile.data() ?? const <String, dynamic>{};
    await _room.collection('quiz_answers').doc(user.uid).set({
      'roundId': roundId,
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
    if (quiz['secure'] == true || quiz['practiceOnly'] != true) {
      throw StateError('Secure rounds require server-side scoring.');
    }
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
    if (user == null) throw StateError('Sign in is required.');
    final snap = await _room.get();
    final raw = snap.data()?['quiz'];
    final quiz = raw is Map
        ? Map<String, dynamic>.from(raw)
        : const <String, dynamic>{};
    if (quiz['secure'] != true) {
      await _finishPracticeQuiz();
      return;
    }

    // No downgrade of a secure round: if the trusted backend is down, do
    // not substitute client-calculated winners or credit a fake prize.
    final response = await _postSecure('/quiz/finish', {'roomId': roomId});
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(_serverError(response));
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchQuizAnswers() =>
      _room.collection('quiz_answers').snapshots();

}
