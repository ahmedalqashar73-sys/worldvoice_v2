import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/room_moderation_models.dart';
import '../data/room_stage_models.dart';
import '../data/room_mode.dart';

class RoomModerationService {
  RoomModerationService({
    required this.channelId,
    required this.roomName,
    this.roomLanguageCode,
    this.initialShowTeacherAiSeat = false,
    this.initialIsPrivate = false,
    this.initialVipOnly = false,
    this.initialMode = RoomMode.chat,
    this.privateAccessCode,
  });

  final String channelId;
  final String roomName;
  final String? roomLanguageCode;
  final bool initialShowTeacherAiSeat;
  final bool initialIsPrivate;
  final bool initialVipOnly;
  final RoomMode initialMode;
  final String? privateAccessCode;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  User? get _user => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>> get _roomRef =>
      _db.collection('rooms').doc(channelId);

  CollectionReference<Map<String, dynamic>> get _participantsRef =>
      _roomRef.collection('participants');

  CollectionReference<Map<String, dynamic>> get _stageInvitesRef =>
      _roomRef.collection('stage_invites');

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
    final frameId = (data['profileFrameId'] as String?)?.trim();
    final profileLanguageCode =
        (data['nativeLanguageCode'] ?? 'en').toString().trim();
    final languageCode = (roomLanguageCode?.trim().isNotEmpty == true
            ? roomLanguageCode!.trim()
            : profileLanguageCode)
        .toLowerCase();
    final country = (data['country'] ?? '').toString().trim();

    final existingRoom = await _roomRef.get();
    final existingData = existingRoom.data();
    var isGlobalModerator = false;
    if (!asHost) {
      final hostId = existingData?['hostId']?.toString() ?? '';
      if (hostId.isNotEmpty) {
        final moderator = await _db
            .collection('users')
            .doc(hostId)
            .collection('moderators')
            .doc(user.uid)
            .get();
        isGlobalModerator = moderator.exists;
      }
    }
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
          'themeId': existingData?['themeId'] ?? 'emerald',
          'mode': initialMode.name,
          'boardWriteEnabled': initialMode != RoomMode.lesson,
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
        'frameId': frameId,
        'role': asHost ? 'host' : 'listener',
        'handRaised': false,
        'seatIndex': asHost ? 1 : FieldValue.delete(),
        'agoraUid': FieldValue.delete(),
        'requestedSeatIndex': FieldValue.delete(),
        'isModerator': asHost ? false : isGlobalModerator,
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
            frameId: data['frameId'] as String?,
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

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchMyStageInvite() {
    final uid = currentUserId;
    if (uid == null) {
      return const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty();
    }
    return _stageInvitesRef.doc(uid).snapshots();
  }

  Future<void> sendStageInvite({
    required String userId,
    required RoomMemberRole role,
    required int seatIndex,
  }) async {
    final inviter = _user;
    if (inviter == null) throw StateError('Sign in is required.');
    if (role != RoomMemberRole.speaker &&
        role != RoomMemberRole.coHost &&
        role != RoomMemberRole.vipSeat) {
      throw StateError('Unsupported stage role.');
    }
    if (seatIndex < 2 || seatIndex > 8) {
      throw StateError('Stage invitation must use seats 2 to 8.');
    }

    final participant = await _participantsRef.doc(userId).get();
    if (!participant.exists ||
        participant.data()?['role']?.toString() != 'listener') {
      throw StateError('Only current listeners can be invited to the stage.');
    }

    final occupied = await _participantsRef
        .where('seatIndex', isEqualTo: seatIndex)
        .limit(1)
        .get();
    if (occupied.docs.isNotEmpty) {
      throw StateError('That speaker seat is already occupied.');
    }

    await _stageInvitesRef.doc(userId).set({
      'recipientId': userId,
      'invitedBy': inviter.uid,
      'role': RoomParticipant.roleToString(role),
      'seatIndex': seatIndex,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'respondedAt': FieldValue.delete(),
    });
  }

  Future<void> respondToStageInvite({required bool accept}) async {
    final user = _user;
    if (user == null) throw StateError('Sign in is required.');

    final inviteRef = _stageInvitesRef.doc(user.uid);
    final participantRef = _participantsRef.doc(user.uid);

    if (!accept) {
      await inviteRef.update({
        'status': 'declined',
        'respondedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final invite = await inviteRef.get();
    final inviteData = invite.data();
    if (!invite.exists || inviteData?['status']?.toString() != 'pending') {
      throw StateError('This stage invitation is no longer active.');
    }

    final seatIndex = (inviteData?['seatIndex'] as num?)?.toInt();
    final role = RoomParticipant.roleFromString(
      inviteData?['role']?.toString(),
    );
    if (seatIndex == null ||
        seatIndex < 2 ||
        seatIndex > 8 ||
        role == RoomMemberRole.listener ||
        role == RoomMemberRole.host ||
        role == RoomMemberRole.teacherAi) {
      throw StateError('This stage invitation is invalid.');
    }

    final occupied = await _participantsRef
        .where('seatIndex', isEqualTo: seatIndex)
        .limit(1)
        .get();
    if (occupied.docs.any((doc) => doc.id != user.uid)) {
      throw StateError('That speaker seat was taken. Ask for a new invite.');
    }

    final batch = _db.batch();
    batch.update(participantRef, {
      'role': RoomParticipant.roleToString(role),
      'seatIndex': seatIndex,
      'handRaised': false,
      'requestedSeatIndex': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(inviteRef, {
      'status': 'accepted',
      'respondedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
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

  Future<void> closeRoom() async {
    final uid = currentUserId;
    if (uid == null) {
      throw StateError('Sign in is required to close the room.');
    }

    final room = await _roomRef.get();
    if (!room.exists) {
      throw StateError('Room not found.');
    }

    final data = room.data() ?? const <String, dynamic>{};
    if (data['hostId']?.toString() != uid) {
      throw StateError('Only the host can close the room.');