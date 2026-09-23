import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomQuizQuestion {
  const RoomQuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.status,
    required this.correctIndex,
  });

  final String id;
  final String question;
  final List<String> options;
  final String status;
  final int correctIndex;

  bool get isOpen => status == 'open';

  factory RoomQuizQuestion.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return RoomQuizQuestion(
      id: doc.id,
      question: (data['question'] ?? '').toString(),
      options: (data['options'] as List?)
              ?.map((value) => value.toString())
              .toList() ??
          const <String>[],
      status: (data['status'] ?? 'closed').toString(),
      correctIndex: (data['correctIndex'] as num?)?.toInt() ?? -1,
    );
  }
}

class RoomQuizAnswer {
  const RoomQuizAnswer({
    required this.userId,
    required this.displayName,
    required this.selectedIndex,
    required this.isCorrect,
    required this.answeredAt,
  });

  final String userId;
  final String displayName;
  final int selectedIndex;
  final bool isCorrect;
  final DateTime? answeredAt;
}

class RoomQuizService {
  RoomQuizService({required this.roomId});

  final String roomId;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  User? get _user => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>> get _current =>
      _db.collection('rooms').doc(roomId).collection('quiz').doc('current');

  CollectionReference<Map<String, dynamic>> get _answers =>
      _db.collection('rooms').doc(roomId).collection('quiz_answers');

  Stream<RoomQuizQuestion?> watchQuestion() {
    return _current.snapshots().map(
      (doc) => doc.exists ? RoomQuizQuestion.fromDoc(doc) : null,
    );
  }

  Stream<List<RoomQuizAnswer>> watchAnswers() {
    return _answers.snapshots().map((snapshot) {
      final answers = snapshot.docs.map((doc) {
        final data = doc.data();
        final raw = data['answeredAt'];
        return RoomQuizAnswer(
          userId: doc.id,
          displayName: (data['displayName'] ?? 'WorldVoice user').toString(),
          selectedIndex: (data['selectedIndex'] as num?)?.toInt() ?? -1,
          isCorrect: data['isCorrect'] == true,
          answeredAt: raw is Timestamp ? raw.toDate() : null,
        );
      }).toList();

      answers.sort((a, b) {
        final at = a.answeredAt;
        final bt = b.answeredAt;
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return at.compareTo(bt);
      });
      return answers;
    });
  }

  Future<void> createQuestion({
    required String question,
    required List<String> options,
    required int correctIndex,
  }) async {
    final user = _user;
    if (user == null) return;

    final cleaned = options.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (question.trim().isEmpty || cleaned.length < 2) {
      throw StateError('Quiz needs a question and at least two options.');
    }
    if (correctIndex < 0 || correctIndex >= cleaned.length) {
      throw StateError('Choose the correct answer.');
    }

    final oldAnswers = await _answers.get();
    final batch = _db.batch();
    for (final answer in oldAnswers.docs) {
      batch.delete(answer.reference);
    }

    batch.set(_current, {
      'question': question.trim(),
      'options': cleaned,
      'correctIndex': correctIndex,
      'status': 'open',
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> answer(RoomQuizQuestion question, int selectedIndex) async {
    final user = _user;
    if (user == null || !question.isOpen) return;

    final participant = await _db
        .collection('rooms')
        .doc(roomId)
        .collection('participants')
        .doc(user.uid)
        .get();
    final displayName =
        (participant.data()?['displayName'] ?? user.displayName ?? 'WorldVoice user')
            .toString();

    await _answers.doc(user.uid).set({
      'userId': user.uid,
      'displayName': displayName,
      'selectedIndex': selectedIndex,
      'isCorrect': selectedIndex == question.correctIndex,
      'answeredAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> closeQuestion() async {
    await _current.set({
      'status': 'closed',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
