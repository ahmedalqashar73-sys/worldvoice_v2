import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/room_moderation_models.dart';

class RoomAdminService {
  RoomAdminService({required this.roomId});

  final String roomId;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  User? get _user => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>> get _room =>
      _db.collection('rooms').doc(roomId);

  CollectionReference<Map<String, dynamic>> get _participants =>
      _room.collection('participants');

  CollectionReference<Map<String, dynamic>> get _modLog =>
      _room.collection('mod_log');

  CollectionReference<Map<String, dynamic>> _globalModerators(String ownerId) =>
      _db.collection('users').doc(ownerId).collection('moderators');

  static int maxModeratorsForLevel(int level) {
    if (level < 6) return 3;
    return 4 + ((level - 6) ~/ 3);
  }

  Stream<List<Map<String, dynamic>>> watchModLog() {
    return _modLog
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => <String, dynamic>{
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList(growable: false),
        );
  }

  Future<int> _roomLevel() async {
    final snap = await _room.get();
    return (snap.data()?['roomLevel'] as num?)?.toInt() ?? 1;
  }

  // Reports are available to every signed-in room member, including
  // listeners. The collection is write-once and not readable by clients.
  // A trusted moderation backend can review these records later.
  Future<void> reportMember({
    required String targetUserId,
    required String reason,
    String detail = '',
    String messageId = '',
  }) async {
    final reporter = _user;
    if (reporter == null) {
      throw StateError('Sign in to report inappropriate behavior.');
    }
    if (targetUserId.isEmpty || targetUserId == reporter.uid) {
      throw StateError('Choose another participant to report.');
    }
    const validReasons = <String>{
      'harassment', 'offensive', 'spam', 'impersonation', 'other',
    };
    if (!validReasons.contains(reason)) {
      throw StateError('Invalid report reason.');
    }
    final explanation = detail.trim();
    if (explanation.length > 500 || messageId.length > 150) {
      throw StateError('Report details are too long.');
    }
    await _room.collection('reports').add({
      'reporterId': reporter.uid,
      'targetUserId': targetUserId,
      'reason': reason,
      'detail': explanation,
      'messageId': messageId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setModerator({
    required RoomParticipant participant,
    required bool value,
  }) async {
    final actor = _user;
    if (actor == null) return;

    if (value) {
      final level = await _roomLevel();
      final maxModerators = maxModeratorsForLevel(level);
      final current = await _participants
          .where('isModerator', isEqualTo: true)
          .get();
      if (current.docs.length >= maxModerators) {
        throw StateError(
          'Moderator limit reached for room level $level.',
        );
      }
    }

    final room = await _room.get();
    final ownerId = room.data()?['hostId']?.toString() ?? '';
    if (ownerId.isEmpty || ownerId != actor.uid) {
      throw StateError('Only the host can manage global moderators.');
    }

    final batch = _db.batch();
    batch.set(
      _participants.doc(participant.userId),
      {
        'isModerator': value,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final globalRef = _globalModerators(ownerId).doc(participant.userId);
    if (value) {
      batch.set(
        globalRef,
        {
          'uid': participant.userId,
          'displayName': participant.displayName,
          'photoUrl': participant.photoUrl ?? '',
          'assignedBy': actor.uid,
          'assignedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } else {
      batch.delete(globalRef);
    }

    await batch.commit();

    await _writeLog(
      action: value ? 'global_moderator_assigned' : 'global_moderator_removed',
      target: participant,
    );
  }

  Future<void> setForcedMute({
    required RoomParticipant participant,
    required bool value,
  }) async {
    await _participants.doc(participant.userId).set(
      {
        'forcedMuted': value,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await _writeLog(
      action: value ? 'muted' : 'unmuted',
      target: participant,
    );
  }

  Future<void> moveDown(RoomParticipant participant) async {
    await _participants.doc(participant.userId).set(
      {
        'role': 'listener',
        'seatIndex': FieldValue.delete(),
        'handRaised': false,
        'requestedSeatIndex': FieldValue.delete(),
        'forcedMuted': false,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await _writeLog(
      action: 'moved_to_listeners',
      target: participant,
    );
  }

  Future<void> warn(RoomParticipant participant) async {
    final ref = _participants.doc(participant.userId);

    final shouldKick = await _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return false;

      final current = (snap.data()?['warningCount'] as num?)?.toInt() ?? 0;
      final next = current + 1;

      if (next >= 3) {
        tx.delete(ref);
        return true;
      }

      tx.update(ref, {
        'warningCount': next,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return false;
    });

    await _writeLog(
      action: shouldKick ? 'auto_kicked_after_3_warnings' : 'warning',
      target: participant,
      metadata: {
        'warningCount': shouldKick ? 3 : participant.warningCount + 1,
      },
    );
  }

  Future<void> kick(RoomParticipant participant) async {
    await _participants.doc(participant.userId).delete();
    await _writeLog(
      action: 'kicked',
      target: participant,
    );
  }

  Future<void> _writeLog({
    required String action,
    required RoomParticipant target,
    Map<String, dynamic>? metadata,
  }) async {
    final actor = _user;
    if (actor == null) return;

    final actorDoc = await _participants.doc(actor.uid).get();
    final actorName =
        (actorDoc.data()?['displayName'] ?? actor.displayName ?? 'Moderator')
            .toString();

    await _modLog.add({
      'action': action,
      'actorId': actor.uid,
      'actorName': actorName,
      'targetId': target.userId,
      'targetName': target.displayName,
      'metadata': metadata ?? const <String, dynamic>{},
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
