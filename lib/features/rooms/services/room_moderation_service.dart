import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/room_moderation_models.dart';
import '../data/room_stage_models.dart';

class RoomModerationService {
  RoomModerationService({
    required this.channelId,
    required this.roomName,
    this.roomLanguageCode,
    this.initialShowTeacherAiSeat = false,
    this.initialIsPrivate = false,
    this.initialVipOnly = false,
    this.privateAccessCode,
  });

  final String channelId;
  final String roomName;
  final String? roomLanguageCode;
  final bool initialShowTeacherAiSeat;
  final bool initialIsPrivate;
  final bool initialVipOnly;
  final String? privateAccessCode;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  User? get _user => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>> get _roomRef =>
      _db.collection('rooms').doc(channelId);

  CollectionReference<Map<String, dynamic>> get _participantsRef =>
      _roomRef.collection('participants');

  String? get currentUserId => _user?.uid;

  Future<void> enter({
    required bool asHost,
  }) async {
    final user = _user;
    if (user == null) return;

    final profile =
        await _db.collection('users').doc(user.uid).get();
    final data = profile.data() ?? const <String, dynamic>{};
    final displayName =
        (data['displayName'] ?? user.displayName ?? 'WorldVoice user')
            .toString()
            .trim();
    final photoUrl = (data['photoUrl'] as String?)?.trim();
    final profileLanguageCode =
        (data['nativeLanguageCode'] ?? 'en').toString().trim();
    final languageCode = (roomLanguageCode?.trim().isNotEmpty == true
            ? roomLanguageCode!.trim()
            : profileLanguageCode)
        .toLowerCase();
    final country = (data['country'] ?? '').toString().trim();

    final existingRoom = await _roomRef.get();
    final existingData = existingRoom.data();
    if (!asHost) {
      if (!existingRoom.exists || existingData?['isOpen'] != true) {
        throw StateError('This room is no longer open.');
      }

      if (existingData?['vipOnly'] == true && data['isVip'] != true) {
        throw StateError('This room is available to VIP members only.');
      }

      if (existingData?['isPrivate'] == true) {
        final code = privateAccessCode?.trim() ?? '';
        if (code.isEmpty) {
          throw StateError('A private room code is required.');
        }
        final codeDoc =
            await _db.collection('private_room_codes').doc(code).get();
        if (!codeDoc.exists ||
            codeDoc.data()?['roomId']?.toString() != channelId) {
          throw StateError('The private room code is invalid.');
        }

        await _roomRef.collection('access_grants').doc(user.uid).set({
          'uid': user.uid,
          'code': code,
          'grantedAt': FieldValue.serverTimestamp(),
        });
      }
    } else if (existingRoom.exists &&
        existingData?['isOpen'] == true &&
        existingData?['hostId'] != user.uid) {
      throw StateError('This room already has an active host.');
    }

    final batch = _db.batch();

    if (asHost) {
      if (initialIsPrivate) {
        final giftLevel = (data['giftLevel'] as num?)?.toInt() ?? 0;
        if (giftLevel < 14) {
          throw StateError(
            'Gift Level 14 is required to create a private room.',
          );
        }

        final code = privateAccessCode?.trim() ?? '';
        if (code.isEmpty) {
          throw StateError('Private room code is missing.');
        }

        batch.set(
          _db.collection('private_room_codes').doc(code),
          {
            'roomId': channelId,
            'hostId': user.uid,
            'isOpen': true,
            'createdAt': FieldValue.serverTimestamp(),
          },
        );
      }

      batch.set(
        _roomRef,
        {
          'channelId': channelId,
          'name': roomName,
          'hostId': user.uid,
          'hostName': displayName.isEmpty ? 'WorldVoice user' : displayName,
          'hostPhotoUrl': photoUrl,
          'hostCountry': country,
          'languageCode': languageCode.isEmpty ? 'en' : languageCode,
          'showTeacherAiSeat': initialShowTeacherAiSeat,
          'isPrivate': initialIsPrivate,
          'vipOnly': initialVipOnly,
          'roomLevel': existingData?['roomLevel'] ?? 1,
          'roomXp': existingData?['roomXp'] ?? existingData?['roomPoints'] ?? 0,
          'themeId': existingData?['themeId'] ?? 'royalPurple',
          'boardWriteEnabled': existingData?['boardWriteEnabled'] ?? true,
          'musicPlaying': existingData?['musicPlaying'] ?? false,
          'isOpen': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    batch.set(
      _participantsRef.doc(user.uid),
      {
        'uid': user.uid,
        'displayName': displayName.isEmpty ? 'WorldVoice user' : displayName,
        'photoUrl': photoUrl,
        'role': asHost ? 'host' : 'listener',
        'handRaised': false,
        'seatIndex': asHost ? 1 : FieldValue.delete(),
        'agoraUid': FieldValue.delete(),
        'requestedSeatIndex': FieldValue.delete(),
        'isModerator': false,
        'warningCount': 0,
        'forcedMuted': false,
        'kicked': false,
        'joinedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<int> roomLevel() async {
    final snap = await _roomRef.get();
    return (snap.data()?['roomLevel'] as num?)?.toInt() ?? 1;
  }

  Stream<bool> watchRoomOpen() {
    return _roomRef.snapshots().map(
      (snapshot) => snapshot.exists && snapshot.data()?['isOpen'] == true,
    );
  }

  Stream<bool> watchTeacherAiSeatVisible() {
    return _roomRef.snapshots().map(
      (snapshot) => snapshot.data()?['showTeacherAiSeat'] == true,
    );
  }

  Future<void> setTeacherAiSeatVisible(bool value) async {
    await _roomRef.set(
      {
        'showTeacherAiSeat': value,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Stream<List<RoomParticipant>> watchParticipants() {
    return _participantsRef.snapshots().map((snapshot) {
      final result = <RoomParticipant>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        result.add(
          RoomParticipant(
            userId: doc.id,
            displayName:
                (data['displayName'] ?? 'WorldVoice user').toString(),
            photoUrl: data['photoUrl'] as String?,
            role: RoomParticipant.roleFromString(
              data['role']?.toString(),
            ),
            handRaised: data['handRaised'] == true,
            agoraUid: (data['agoraUid'] as num?)?.toInt(),
            seatIndex: (data['seatIndex'] as num?)?.toInt(),
            requestedSeatIndex:
                (data['requestedSeatIndex'] as num?)?.toInt(),
            isModerator: data['isModerator'] == true,
            warningCount: (data['warningCount'] as num?)?.toInt() ?? 0,
            forcedMuted: data['forcedMuted'] == true,
            kicked: data['kicked'] == true,
          ),
        );
      }

      result.sort((a, b) {
        final aSeat = a.seatIndex ?? 999;
        final bSeat = b.seatIndex ?? 999;
        final bySeat = aSeat.compareTo(bSeat);
        if (bySeat != 0) return bySeat;
        return a.displayName.compareTo(b.displayName);
      });
      return result;
    });
  }

  Stream<RoomParticipant?> watchMe() {
    final uid = currentUserId;
    if (uid == null) return const Stream<RoomParticipant?>.empty();

    return _participantsRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() ?? const <String, dynamic>{};
      return RoomParticipant(
        userId: doc.id,
        displayName: (data['displayName'] ?? 'WorldVoice user').toString(),
        photoUrl: data['photoUrl'] as String?,
        role: RoomParticipant.roleFromString(data['role']?.toString()),
        handRaised: data['handRaised'] == true,
        agoraUid: (data['agoraUid'] as num?)?.toInt(),
        seatIndex: (data['seatIndex'] as num?)?.toInt(),
        requestedSeatIndex:
            (data['requestedSeatIndex'] as num?)?.toInt(),
        isModerator: data['isModerator'] == true,
        warningCount: (data['warningCount'] as num?)?.toInt() ?? 0,
        forcedMuted: data['forcedMuted'] == true,
        kicked: data['kicked'] == true,
      );
    });
  }

  Future<void> syncAgoraUid(int uid) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _participantsRef.doc(userId).set(
      {
        'agoraUid': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> setHandRaised(
    bool raised, {
    int? requestedSeatIndex,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _participantsRef.doc(uid).set(
      {
        'handRaised': raised,
        'requestedSeatIndex': raised && requestedSeatIndex != null
            ? requestedSeatIndex
            : FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> rejectHand(String userId) async {
    await _participantsRef.doc(userId).set(
      {
        'handRaised': false,
        'requestedSeatIndex': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> assignSeat({
    required String userId,
    required RoomMemberRole role,
    required int seatIndex,
  }) async {
    if (role == RoomMemberRole.listener ||
        role == RoomMemberRole.teacherAi ||
        role == RoomMemberRole.host) {
      return;
    }

    await _participantsRef.doc(userId).set(
      {
        'role': RoomParticipant.roleToString(role),
        'seatIndex': seatIndex,
        'handRaised': false,
        'requestedSeatIndex': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> moveToListener(String userId) async {
    await _participantsRef.doc(userId).set(
      {
        'role': 'listener',
        'seatIndex': FieldValue.delete(),
        'handRaised': false,
        'requestedSeatIndex': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> changeStageRole({
    required String userId,
    required RoomMemberRole role,
  }) async {
    if (role != RoomMemberRole.coHost &&
        role != RoomMemberRole.speaker &&
        role != RoomMemberRole.vipSeat) {
      return;
    }

    await _participantsRef.doc(userId).set(
      {
        'role': RoomParticipant.roleToString(role),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  int moderatorLimitForRoomLevel(int roomLevel) {
    if (roomLevel < 6) return 3;
    return 3 + ((roomLevel - 3) ~/ 3);
  }

  Future<bool> canAssignModerator({
    required String userId,
    required int roomLevel,
  }) async {
    final participantDocs = await _participantsRef.get();
    final currentModerators = participantDocs.docs
        .where((doc) => doc.data()['isModerator'] == true)
        .length;
    if (currentModerators >= moderatorLimitForRoomLevel(roomLevel)) {
      return false;
    }

    final profile = await _db.collection('users').doc(userId).get();
    final data = profile.data() ?? const <String, dynamic>{};
    final personalLevel = (data['level'] as num?)?.toInt() ?? 0;
    final createdAt = data['createdAt'];
    final created = createdAt is Timestamp ? createdAt.toDate() : null;
    final accountOldEnough = created != null &&
        DateTime.now().difference(created).inDays >= 7;

    return personalLevel >= 3 && accountOldEnough;
  }

  Future<void> setModerator({
    required String userId,
    required bool value,
    required int roomLevel,
  }) async {
    if (value) {
      final allowed = await canAssignModerator(
        userId: userId,
        roomLevel: roomLevel,
      );
      if (!allowed) {
        throw StateError(
          'Moderator limit reached or user does not meet eligibility.',
        );
      }
    }

    await _participantsRef.doc(userId).set(
      {
        'isModerator': value,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await _logModeration(
      action: value ? 'assign_moderator' : 'remove_moderator',
      targetUserId: userId,
    );
  }

  Future<void> setForcedMuted({
    required String userId,
    required bool value,
  }) async {
    await _participantsRef.doc(userId).set(
      {
        'forcedMuted': value,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await _logModeration(
      action: value ? 'mute' : 'unmute',
      targetUserId: userId,
    );
  }

  Future<void> warn(String userId) async {
    final ref = _participantsRef.doc(userId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() ?? const <String, dynamic>{};
      final current = (data['warningCount'] as num?)?.toInt() ?? 0;
      final next = current + 1;
      tx.set(
        ref,
        {
          'warningCount': next,
          'kicked': next >= 3,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
    await _logModeration(action: 'warning', targetUserId: userId);
  }

  Future<void> kick(String userId) async {
    await _participantsRef.doc(userId).set(
      {
        'kicked': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await _logModeration(action: 'kick', targetUserId: userId);
  }

  Future<void> _logModeration({
    required String action,
    required String targetUserId,
  }) async {
    final actor = _user;
    if (actor == null) return;
    await _roomRef.collection('mod_logs').add({
      'action': action,
      'actorId': actor.uid,
      'targetUserId': targetUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchModerationLog() {
    return _roomRef
        .collection('mod_logs')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots();
  }

  Future<void> leave() async {
    final uid = currentUserId;
    if (uid == null) return;

    final room = await _roomRef.get();
    if (!room.exists) return;

    final roomData = room.data() ?? const <String, dynamic>{};
    final isCurrentHost = roomData['hostId']?.toString() == uid;

    if (!isCurrentHost) {
      await _participantsRef.doc(uid).delete();
      return;
    }

    final participants = await _participantsRef.get();
    QueryDocumentSnapshot<Map<String, dynamic>>? nextHostDoc;

    for (final doc in participants.docs) {
      if (doc.id == uid) continue;
      final data = doc.data();
      if (data['isModerator'] != true) continue;

      if (nextHostDoc == null) {
        nextHostDoc = doc;
        continue;
      }

      final currentJoined = nextHostDoc.data()['joinedAt'];
      final candidateJoined = data['joinedAt'];
      if (candidateJoined is Timestamp &&
          currentJoined is Timestamp &&
          candidateJoined.compareTo(currentJoined) < 0) {
        nextHostDoc = doc;
      }
    }

    final batch = _db.batch();
    batch.delete(_participantsRef.doc(uid));

    if (nextHostDoc != null) {
      final nextHostId = nextHostDoc.id;
      final nextData = nextHostDoc.data();
      final nextProfile =
          await _db.collection('users').doc(nextHostId).get();
      final nextCountry =
          (nextProfile.data()?['country'] ?? '').toString().trim();

      batch.set(
        nextHostDoc.reference,
        {
          'role': 'host',
          'seatIndex': 1,
          'isModerator': false,
          'handRaised': false,
          'requestedSeatIndex': FieldValue.delete(),
          'forcedMuted': false,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      batch.set(
        _roomRef,
        {
          'hostId': nextHostId,
          'hostName':
              (nextData['displayName'] ?? 'WorldVoice host').toString(),
          'hostPhotoUrl': nextData['photoUrl'],
          'hostCountry': nextCountry,
          'isOpen': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (roomData['isPrivate'] == true) {
        final code = privateAccessCode?.trim() ?? '';
        if (code.isNotEmpty) {
          batch.set(
            _db.collection('private_room_codes').doc(code),
            {
              'hostId': nextHostId,
              'isOpen': true,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      }
    } else {
      if (roomData['isPrivate'] == true) {
        final code = privateAccessCode?.trim() ?? '';
        if (code.isNotEmpty) {
          batch.set(
            _db.collection('private_room_codes').doc(code),
            {
              'isOpen': false,
              'endedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      }

      batch.set(
        _roomRef,
        {
          'isOpen': false,
          'endedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }}
