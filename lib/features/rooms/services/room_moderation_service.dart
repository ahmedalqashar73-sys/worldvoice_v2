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
  });

  final String channelId;
  final String roomName;
  final String? roomLanguageCode;

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
    } else if (existingRoom.exists &&
        existingData?['isOpen'] == true &&
        existingData?['hostId'] != user.uid) {
      throw StateError('This room already has an active host.');
    }

    final batch = _db.batch();

    if (asHost) {
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
        'joinedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Stream<bool> watchRoomOpen() {
    return _roomRef.snapshots().map(
      (snapshot) => snapshot.exists && snapshot.data()?['isOpen'] == true,
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

  Future<void> setHandRaised(bool raised) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _participantsRef.doc(uid).set(
      {
        'handRaised': raised,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> rejectHand(String userId) async {
    await _participantsRef.doc(userId).set(
      {
        'handRaised': false,
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

  Future<void> leave() async {
    final uid = currentUserId;
    if (uid == null) return;

    final room = await _roomRef.get();
    final isCurrentHost =
        room.exists && room.data()?['hostId']?.toString() == uid;

    final batch = _db.batch();
    batch.delete(_participantsRef.doc(uid));

    if (isCurrentHost) {
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
  }
}
