import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../data/room_backend_config.dart';
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
          'backgroundUrl': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

  Future<void> setPurchasedBackground({
    required String themeId,
    required String? backgroundUrl,
  }) =>
      _room.set(
        {
          'themeId': themeId,
          'backgroundUrl': backgroundUrl?.trim().isNotEmpty == true
              ? backgroundUrl!.trim()
              : FieldValue.delete(),
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

  Future<void> finishQuiz() async {
    final user = _user;
    if (user == null) {
      throw StateError('Sign in is required.');
    }

    final endpoint = RoomBackendConfig.endpoint('/quiz/finish');
    if (endpoint.isEmpty) {
      await revealQuiz();
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
      throw StateError(message);
    }
  }

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
    if (recipientId == user.uid) {
      throw StateError('CANNOT_GIFT_SELF');
    }

    final visual = await _db.collection('room_gift_catalog').doc(giftId).get();
    final animationUrl =
        (visual.data()?['animationUrl'] as String?)?.trim();

    final senderRef = _db.collection('users').doc(user.uid);
    final recipientRef = recipientId == 'teacher_ai'
        ? null
        : _db.collection('users').doc(recipientId);
    final giftRef = _room.collection('gifts').doc();

    await _db.runTransaction((tx) async {
      final sender = await tx.get(senderRef);
      final senderData = sender.data() ?? const <String, dynamic>{};
      final balance = (senderData['coins'] as num?)?.toInt() ?? 0;

      if (balance < points) {
        throw StateError('NOT_ENOUGH_COINS');
      }

      final senderName =
          (senderData['displayName'] ?? user.displayName ?? 'WorldVoice user')
              .toString();

      tx.set(
        senderRef,
        {
          'coins': balance - points,
          'giftSentPoints': FieldValue.increment(points),
          'giftLevelPoints': FieldValue.increment(points),
          'lastGiftRoomId': roomId,
          'lastGiftEventId': giftRef.id,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (recipientRef != null && recipientId != user.uid) {
        tx.set(
          recipientRef,
          {
            'giftReceivedPoints': FieldValue.increment(points),
            'giftLevelPoints': FieldValue.increment(points),
            'lastGiftRoomId': roomId,
            'lastGiftEventId': giftRef.id,
          },
          SetOptions(merge: true),
        );
      }

      tx.set(giftRef, {
        'senderId': user.uid,
        'senderName': senderName,
        'recipientId': recipientId,
        'recipientName': recipientName,
        'giftId': giftId,
        'points': points,
        if (animationUrl?.isNotEmpty == true)
          'animationUrl': animationUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
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

    int? unlockedLevel;

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
          'lastTaskCompletionId': taskRef.id,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (newLevel > ((oldXp ~/ 100) + 1)) {
        unlockedLevel = newLevel;
        final rewardRef = _room.collection('rewards').doc('level_$newLevel');
        tx.set(
          rewardRef,
          {
            'level': newLevel,
            'type': newLevel == 5 ? 'background_month' : 'gift_pack',
            'unlockedBy': user.uid,
            'sourceTaskId': taskRef.id,
            'unlockedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    });

    final level = unlockedLevel;
    if (level != null) {
      await _grantLevelRewardToPresentMembers(level);
    }
  }

  Future<void> _grantLevelRewardToPresentMembers(int level) async {
    final participants = await _room.collection('participants').get();
    if (participants.docs.isEmpty) return;

    final rewardType = level == 5 ? 'background_month' : 'gift_pack';
    final expiresAt = level == 5
        ? Timestamp.fromDate(DateTime.now().add(const Duration(days: 30)))
        : null;

    final batch = _db.batch();
    for (final participant in participants.docs) {
      final rewardId = '${roomId}_level_$level';
      final rewardRef = _db
          .collection('users')
          .doc(participant.id)
          .collection('room_rewards')
          .doc(rewardId);

      batch.set(
        rewardRef,
        {
          'userId': participant.id,
          'roomId': roomId,
          'level': level,
          'type': rewardType,
          'sourceRewardId': 'level_$level',
          ?'expiresAt': expiresAt,
          'grantedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<void> recordSpeakerActivity({
    int seconds = 30,
  }) async {
    final user = _user;
    if (user == null || seconds <= 0 || seconds > 60) return;

    final profile = await _db.collection('users').doc(user.uid).get();
    final data = profile.data() ?? const <String, dynamic>{};
    final name =
        (data['displayName'] ?? user.displayName ?? 'WorldVoice user')
            .toString();

    await _room.collection('speaker_stats').doc(user.uid).set(
      {
        'userId': user.uid,
        'displayName': name,
        'seconds': FieldValue.increment(seconds),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchSpeakerStats() {
    return _room
        .collection('speaker_stats')
        .orderBy('seconds', descending: true)
        .limit(50)
        .snapshots();
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
