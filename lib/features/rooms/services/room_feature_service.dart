import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/room_feature_models.dart';

class RoomFeatureService {
  RoomFeatureService({required this.roomId});

  final String roomId;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  User? get _user => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>> get _room =>
      _db.collection('rooms').doc(roomId);

  Stream<RoomFeatureState> watchState() {
    return _room.snapshots().map(
      (snapshot) => RoomFeatureState.fromData(
        snapshot.data() ?? const <String, dynamic>{},
      ),
    );
  }

  Future<void> initializeDefaults() async {
    await _room.set(
      {
        'roomLevel': 1,
        'roomXp': 0,
        'themeId': 'royalPurple',
        'boardWriteEnabled': true,
        'isPrivate': false,
        'vipOnly': false,
        'musicPlaying': false,
        'screenShareActive': false,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> setTheme(String themeId) => _room.set(
        {
          'themeId': themeId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

  Future<void> setBoardWriteEnabled(bool value) => _room.set(
        {
          'boardWriteEnabled': value,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

  Future<void> setAccess({
    required bool isPrivate,
    required bool vipOnly,
  }) =>
      _room.set(
        {
          'isPrivate': isPrivate,
          'vipOnly': vipOnly,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

  Future<void> setScreenSharing({
    required bool active,
    int? sharerUid,
  }) =>
      _room.set(
        {
          'screenShareActive': active,
          'screenSharerUid':
              active && sharerUid != null ? sharerUid : FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

  Future<void> setMusic({
    required String? title,
    required String? url,
    required bool playing,
  }) =>
      _room.set(
        {
          'musicTitle': title,
          'musicUrl': url,
          'musicPlaying': playing,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
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

    await _room.set(
      {
        'quiz': {
          'question': question.trim(),
          'options': options,
          'correctIndex': correctIndex,
          'revealed': false,
          'startedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final answers = await _room.collection('quiz_answers').get();
    final batch = _db.batch();
    for (final doc in answers.docs) {
      batch.delete(doc.reference);
    }
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

  Future<void> revealQuiz() => _room.set(
        {
          'quiz.revealed': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

  Stream<QuerySnapshot<Map<String, dynamic>>> watchQuizAnswers() =>
      _room.collection('quiz_answers').snapshots();

  Future<void> sendGift({
    required String recipientId,
    required String recipientName,
    required String giftId,
    required int points,
  }) async {
    final user = _user;
    if (user == null || points <= 0) return;
    final profile = await _db.collection('users').doc(user.uid).get();
    final data = profile.data() ?? const <String, dynamic>{};
    final senderName =
        (data['displayName'] ?? user.displayName ?? 'WorldVoice user')
            .toString();

    await _room.collection('gifts').add({
      'senderId': user.uid,
      'senderName': senderName,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'giftId': giftId,
      'points': points,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<RoomGiftEvent>> watchGifts() {
    return _room
        .collection('gifts')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(RoomGiftEvent.fromDoc).toList(growable: false),
        );
  }

  Future<void> completeTask({
    required String taskKey,
    required int points,
    required String periodKey,
  }) async {
    final user = _user;
    if (user == null) return;

    final taskRef = _room
        .collection('task_completions')
        .doc('${periodKey}_${taskKey}_${user.uid}');

    await _db.runTransaction((tx) async {
      final task = await tx.get(taskRef);
      if (task.exists) return;

      final roomSnapshot = await tx.get(_room);
      final roomData =
          roomSnapshot.data() ?? const <String, dynamic>{};
      final oldXp = (roomData['roomXp'] as num?)?.toInt() ?? 0;
      final newXp = oldXp + points;
      final newLevel = 1 + (newXp ~/ 100);

      tx.set(taskRef, {
        'taskKey': taskKey,
        'userId': user.uid,
        'points': points,
        'periodKey': periodKey,
        'completedAt': FieldValue.serverTimestamp(),
      });
      tx.set(
        _room,
        {
          'roomXp': newXp,
          'roomLevel': newLevel,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (newLevel > ((oldXp ~/ 100) + 1)) {
        final rewardRef = _room.collection('rewards').doc('level_$newLevel');
        tx.set(
          rewardRef,
          {
            'level': newLevel,
            'type': newLevel == 5 ? 'background_month' : 'gift_pack',
            'unlockedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    });
  }

  Future<void> recordHistoryEnter(String roomName) async {
    final user = _user;
    if (user == null) return;
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('room_history')
        .doc(roomId)
        .set(
      {
        'roomId': roomId,
        'roomName': roomName,
        'lastEnteredAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> submitRating({
    required String targetUserId,
    required int stars,
  }) async {
    final user = _user;
    if (user == null || stars < 1 || stars > 5) return;
    await _room.collection('ratings').doc('${user.uid}_$targetUserId').set({
      'fromUserId': user.uid,
      'targetUserId': targetUserId,
      'stars': stars,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
