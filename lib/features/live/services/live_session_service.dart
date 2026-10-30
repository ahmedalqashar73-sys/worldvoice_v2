import 'dart:async';
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import '../../chat/services/worldvoice_notification_service.dart';
import '../../rooms/services/active_chat_bubble_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Identity shown on a Live camera, keyed by the Agora UID issued from
/// the participant's authenticated Firebase UID (never by join order).
class LiveStageParticipant {
  const LiveStageParticipant({
    required this.userId,
    required this.agoraUid,
    required this.displayName,
    required this.photoUrl,
    required this.hostMuted,
  });

  final String userId;
  final int agoraUid;
  final String displayName;
  final String photoUrl;
  final bool hostMuted;
}

/// Firestore coordination for video Live.
///
/// Agora carries media; Firestore carries discovery, viewers and guest
/// requests. Money/gifts remain backend-authoritative and are not written here.
class LiveSessionService {
  LiveSessionService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  /// Agora token services both derive the RTC UID from the first four bytes
  /// of SHA-256(firebaseUid), interpreted as a big-endian unsigned integer.
  /// Pre-registering this value allows the authenticated worker to verify
  /// Live ownership before Agora joins. No certificate is stored in Flutter.
  static Future<int> hostAgoraUidForUser(String firebaseUid) async {
    if (firebaseUid.trim().isEmpty) throw StateError('SIGN_IN_REQUIRED');
    final digest = await Sha256().hash(utf8.encode(firebaseUid));
    final b = digest.bytes;
    final uid = (b[0] << 24) | (b[1] << 16) | (b[2] << 8) | b[3];
    return uid == 0 ? 1 : uid;
  }

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _db.collection('live_sessions');

  User get _user {
    final value = _auth.currentUser;
    if (value == null) throw StateError('SIGN_IN_REQUIRED');
    return value;
  }

  Future<String> create({
    required String channelId,
    required String languageCode,
    required int hostAgoraUid,
    String topic = '',
    bool announce = true,
  }) async {
    final user = _user;
    // Use the completed WorldVoice profile, not only the Google/Firebase
    // sign-in photo. A missing or slow profile fetch must not block Live.
    Map<String, dynamic> hostProfile = const <String, dynamic>{};
    try {
      final profile = await _db
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 3));
      hostProfile = profile.data() ?? const <String, dynamic>{};
    } catch (_) {
      // The Auth metadata still provides a safe fallback.
    }
    final savedPhoto = (hostProfile['photoUrl'] ?? '').toString().trim();
    final savedCover = (hostProfile['coverUrl'] ?? '').toString().trim();
    final savedName = (hostProfile['displayName'] ?? hostProfile['name'] ?? '')
        .toString()
        .trim();
    final ref = _sessions.doc(channelId);
    await ref.set({
      'channelId': channelId,
      'hostId': user.uid,
      'hostName': savedName.isNotEmpty
          ? savedName
          : (user.displayName ?? 'WorldVoice host'),
      'hostPhotoUrl': savedPhoto.isNotEmpty
          ? savedPhoto
          : (user.photoURL ?? ''),
      'hostCoverUrl': savedCover,
      'hostAgoraUid': hostAgoraUid,
      'languageCode': languageCode,
      'topic': topic.trim(),
      'isLive': true,
      'isReady': announce,
      'viewerCount': 0,
      'guestCount': 0,
      'boardWriteEnabled': true,
      'startedAt': FieldValue.serverTimestamp(),
      'hostHeartbeatAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // Never announce a host before the camera has joined Agora successfully.
    if (announce) {
      unawaited(WorldVoiceNotificationService.publishActivity(
        kind: 'live', sessionId: ref.id));
    }
    return ref.id;
  }

  Future<void> announceStarted(String liveId) async {
    final session = _sessions.doc(liveId);
    final snap = await session.get();
    if (snap.data()?['hostId'] != _user.uid ||
        snap.data()?['isLive'] != true) {
      throw StateError('LIVE_NOT_OWNED_OR_ENDED');
    }
    await session.update({
      'isReady': true,
      'hostHeartbeatAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // Notification delivery is optional and does not gate the connected Live.
    unawaited(WorldVoiceNotificationService.publishActivity(
      kind: 'live', sessionId: liveId));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchOpen() =>
      _sessions.where('isLive', isEqualTo: true).limit(100).snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> watch(String liveId) =>
      _sessions.doc(liveId).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchViewers(String liveId) =>
      _sessions.doc(liveId).collection('viewers').snapshots();

  Stream<bool> watchMyModeratorStatus(String hostId) {
    final user = _auth.currentUser;
    if (user == null || hostId.isEmpty || user.uid == hostId) {
      return Stream<bool>.value(false);
    }
    return _db
        .collection('users')
        .doc(hostId)
        .collection('moderators')
        .doc(user.uid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.exists &&
              (snapshot.data()?['status'] ?? 'accepted') == 'accepted',
        );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchGlobalModerators(
    String hostId,
  ) => _db.collection('users').doc(hostId).collection('moderators').snapshots();

  Future<void> setGlobalModerator({
    required String liveId,
    required String targetUserId,
    required String displayName,
    required String photoUrl,
    required bool value,
  }) async {
    final user = _user;
    final session = await _sessions.doc(liveId).get();
    final hostId = session.data()?['hostId']?.toString() ?? '';
    if (hostId != user.uid) {
      throw StateError('HOST_ONLY');
    }
    if (targetUserId.isEmpty || targetUserId == user.uid) return;

    final ref = _db
        .collection('users')
        .doc(user.uid)
        .collection('moderators')
        .doc(targetUserId);
    if (value) {
      await ref.set({
        'uid': targetUserId,
        'displayName': displayName.trim().isEmpty
            ? 'WorldVoice user'
            : displayName.trim(),
        'photoUrl': photoUrl.trim(),
        'assignedBy': user.uid,
        'status': 'pending',
        'respondedAt': FieldValue.delete(),
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await ref.delete();
    }
  }

  Stream<Map<String, dynamic>?> watchMyModeratorInvite(String hostId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid == hostId) return Stream.value(null);
    return _db
        .collection('users')
        .doc(hostId)
        .collection('moderators')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data());
  }

  Future<void> answerModeratorInvite(String hostId, bool accepted) async {
    final uid = _user.uid;
    final ref = _db
        .collection('users')
        .doc(hostId)
        .collection('moderators')
        .doc(uid);
    await _db.runTransaction((tx) async {
      final invite = await tx.get(ref);
      if (!invite.exists) throw StateError('INVITATION_EXPIRED');
      final status = accepted ? 'accepted' : 'declined';
      if (invite.data()?['status'] == status) return;
      if (invite.data()?['status'] != 'pending') {
        throw StateError('INVITATION_EXPIRED');
      }
      tx.update(ref, {
        'status': status,
        'respondedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> touchHostHeartbeat(String liveId) async {
    await _sessions.doc(liveId).update({
      'hostHeartbeatAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static bool isFresh(Map<String, dynamic>? data, {DateTime? now}) {
    if (data == null || data['isLive'] != true || data['isReady'] == false) return false;
    final heartbeat = data['hostHeartbeatAt'];
    if (heartbeat is! Timestamp) {
      // Backward compatibility for sessions created before heartbeats existed.
      final started = data['startedAt'];
      if (started is! Timestamp) return true;
      return (now ?? DateTime.now()).difference(started.toDate()).inSeconds <
          60;
    }
    return (now ?? DateTime.now()).difference(heartbeat.toDate()).inSeconds <
        45;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchJoinRequests(
    String liveId,
  ) => _sessions
      .doc(liveId)
      .collection('join_requests')
      .where('status', isEqualTo: 'pending')
      .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchActiveGuests(
    String liveId,
  ) => _sessions
      .doc(liveId)
      .collection('join_requests')
      .where('status', isEqualTo: 'accepted')
      .snapshots();

  /// Resolve the actual identity behind each remote Agora camera.
  /// Firestore request fields are only fallbacks: the source of truth for
  /// names and photos is the original WorldVoice user profile. Never use
  /// "Guest 1" to infer a Firebase UID or trust a user-supplied Agora UID.
  Stream<List<LiveStageParticipant>> watchStageIdentities(String liveId) =>
      watchActiveGuests(liveId).asyncMap((snapshot) async {
        final participants = await Future.wait(
          snapshot.docs.take(3).map((doc) async {
            final uid = doc.id;
            final agoraUid = await hostAgoraUidForUser(uid);
            Map<String, dynamic> profile = const <String, dynamic>{};
            try {
              final userDoc = await _db
                  .collection('users')
                  .doc(uid)
                  .get()
                  .timeout(const Duration(seconds: 3));
              profile = userDoc.data() ?? const <String, dynamic>{};
            } catch (_) {
              // Older rules/offline profile: use the verified guest request.
            }
            final fallback = doc.data();
            final name = (profile['displayName'] ??
                    profile['name'] ??
                    fallback['displayName'] ??
                    '')
                .toString().trim();
            final photo = (profile['photoUrl'] ??
                    profile['avatarUrl'] ??
                    fallback['photoUrl'] ??
                    '')
                .toString().trim();
            return LiveStageParticipant(
              userId: uid,
              agoraUid: agoraUid,
              displayName: name.isEmpty ? 'WorldVoice user' : name,
              photoUrl: photo,
              hostMuted: fallback['hostMuted'] == true,
            );
          }),
        );
        return List<LiveStageParticipant>.unmodifiable(participants);
      });

  Future<void> enterViewer(String liveId) async {
    final user = _user;
    final session = _sessions.doc(liveId);
    final viewer = session.collection('viewers').doc(user.uid);
    var newlyJoined = false;

    await _db.runTransaction((tx) async {
      final sessionSnap = await tx.get(session);
      if (!isFresh(sessionSnap.data())) {
        throw StateError('LIVE_ENDED');
      }
      final existing = await tx.get(viewer);
      if (!existing.exists) {
        newlyJoined = true;
        tx.set(viewer, {
          'uid': user.uid,
          'displayName': user.displayName ?? 'WorldVoice user',
          'photoUrl': user.photoURL ?? '',
          'joinedAt': FieldValue.serverTimestamp(),
        });
        tx.update(session, {
          'viewerCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });

    if (newlyJoined) {
      try {
        await session.collection('messages').add({
          'type': 'join',
          'senderId': user.uid,
          'senderName': user.displayName ?? 'WorldVoice user',
          'senderPhotoUrl': user.photoURL ?? '',
          'text': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } on FirebaseException catch (error) {
        // Older deployed rules reject join notices with an empty text body.
        // Joining the Live already succeeded; don't make guests fail to enter.
        if (error.code != 'permission-denied') rethrow;
      }
    }
  }

  Future<void> leaveViewer(String liveId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final session = _sessions.doc(liveId);
    final viewer = session.collection('viewers').doc(user.uid);
    await _db.runTransaction((tx) async {
      final existing = await tx.get(viewer);
      if (existing.exists) {
        tx.delete(viewer);
        tx.update(session, {
          'viewerCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> inviteViewer({
    required String liveId,
    required String userId,
  }) async {
    final currentUser = _user;
    final session = _sessions.doc(liveId);
    final viewer = session.collection('viewers').doc(userId);
    final request = session.collection('join_requests').doc(userId);

    await _db.runTransaction((tx) async {
      final sessionSnap = await tx.get(session);
      if (!isFresh(sessionSnap.data())) {
        throw StateError('LIVE_ENDED');
      }
      final hostId = sessionSnap.data()?['hostId']?.toString() ?? '';
      if (hostId != currentUser.uid) {
        final moderatorRef = _db
            .collection('users')
            .doc(hostId)
            .collection('moderators')
            .doc(currentUser.uid);
        final moderatorSnap = await tx.get(moderatorRef);
        if (!moderatorSnap.exists ||
            (moderatorSnap.data()?['status'] ?? 'accepted') != 'accepted') {
          throw StateError('MODERATOR_ONLY');
        }
      }

      final viewerSnap = await tx.get(viewer);
      if (!viewerSnap.exists) {
        throw StateError('VIEWER_NOT_AVAILABLE');
      }
      final requestSnap = await tx.get(request);
      if (requestSnap.data()?['status']?.toString() == 'accepted') {
        throw StateError('ALREADY_ON_STAGE');
      }
      final guestCount =
          (sessionSnap.data()?['guestCount'] as num?)?.toInt() ?? 0;
      if (guestCount >= 3) {
        throw StateError('LIVE_GUEST_LIMIT_REACHED');
      }

      final viewerData = viewerSnap.data() ?? const <String, dynamic>{};
      tx.set(request, {
        'uid': userId,
        'displayName': (viewerData['displayName'] ?? 'WorldVoice user')
            .toString(),
        'photoUrl': (viewerData['photoUrl'] ?? '').toString(),
        'status': 'invited',
        'hostMuted': false,
        'invitedBy': currentUser.uid,
        'invitedAt': FieldValue.serverTimestamp(),
        'requestedAt': FieldValue.delete(),
        'decidedAt': FieldValue.delete(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> respondToInvite({
    required String liveId,
    required bool accept,
  }) async {
    final user = _user;
    final session = _sessions.doc(liveId);
    final request = session.collection('join_requests').doc(user.uid);

    await _db.runTransaction((tx) async {
      final sessionSnap = await tx.get(session);
      final requestSnap = await tx.get(request);
      if (!isFresh(sessionSnap.data())) {
        throw StateError('LIVE_ENDED');
      }
      if (!requestSnap.exists ||
          requestSnap.data()?['status']?.toString() != 'invited') {
        throw StateError('INVITE_NOT_PENDING');
      }

      final guestCount =
          (sessionSnap.data()?['guestCount'] as num?)?.toInt() ?? 0;
      if (accept && guestCount >= 3) {
        throw StateError('LIVE_GUEST_LIMIT_REACHED');
      }

      tx.update(request, {
        'status': accept ? 'accepted' : 'declined',
        'decidedAt': FieldValue.serverTimestamp(),
      });
      if (accept) {
        tx.update(session, {
          'guestCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> requestToJoin(String liveId) async {
    final user = _user;
    await _sessions.doc(liveId).collection('join_requests').doc(user.uid).set({
      'uid': user.uid,
      'displayName': user.displayName ?? 'WorldVoice user',
      'photoUrl': user.photoURL ?? '',
      'status': 'pending',
      'hostMuted': false,
      'requestedAt': FieldValue.serverTimestamp(),
      'decidedAt': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  Future<void> decideRequest({
    required String liveId,
    required String userId,
    required bool accept,
  }) async {
    final session = _sessions.doc(liveId);
    final request = session.collection('join_requests').doc(userId);
    await _db.runTransaction((tx) async {
      final sessionSnap = await tx.get(session);
      final hostId = sessionSnap.data()?['hostId']?.toString() ?? '';
      final currentUser = _user;
      if (hostId != currentUser.uid) {
        final moderatorRef = _db
            .collection('users')
            .doc(hostId)
            .collection('moderators')
            .doc(currentUser.uid);
        final moderatorSnap = await tx.get(moderatorRef);
        if (!moderatorSnap.exists ||
            (moderatorSnap.data()?['status'] ?? 'accepted') != 'accepted') {
          throw StateError('MODERATOR_ONLY');
        }
      }
      final requestSnap = await tx.get(request);
      if (!requestSnap.exists ||
          requestSnap.data()?['status']?.toString() != 'pending') {
        throw StateError('REQUEST_NOT_PENDING');
      }
      final guestCount =
          (sessionSnap.data()?['guestCount'] as num?)?.toInt() ?? 0;
      if (accept && guestCount >= 3) {
        throw StateError('LIVE_GUEST_LIMIT_REACHED');
      }
      tx.update(request, {
        'status': accept ? 'accepted' : 'declined',
        'decidedAt': FieldValue.serverTimestamp(),
      });
      if (accept) {
        tx.update(session, {
          'guestCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Only the broadcaster may block a guest microphone. This is a Firestore
  /// moderation instruction; the guest client applies it by muting Agora.
  /// Releasing the block never remotely switches the user's microphone on.
  Future<void> setGuestMicrophoneBlocked({
    required String liveId,
    required String guestUserId,
    required bool blocked,
  }) async {
    final host = _user;
    if (guestUserId.isEmpty || guestUserId == host.uid) {
      throw StateError('INVALID_LIVE_GUEST');
    }
    final session = _sessions.doc(liveId);
    final request = session.collection('join_requests').doc(guestUserId);
    await _db.runTransaction((tx) async {
      final liveSnap = await tx.get(session);
      if (liveSnap.data()?['hostId'] != host.uid ||
          liveSnap.data()?['isLive'] != true) {
        throw StateError('HOST_ONLY');
      }
      final guestSnap = await tx.get(request);
      if (guestSnap.data()?['status'] != 'accepted') {
        throw StateError('GUEST_NOT_ON_STAGE');
      }
      tx.update(request, {'hostMuted': blocked});
    });
  }

  /// Host-only, transactional stage removal: the guest stays in the Live
  /// audience. The request status and session guest counter change together,
  /// and Firestore rules independently enforce the host's authority.
  Future<void> removeGuestFromStage({
    required String liveId,
    required String guestUserId,
  }) async {
    final host = _user;
    if (guestUserId.isEmpty || guestUserId == host.uid) {
      throw StateError('INVALID_LIVE_GUEST');
    }
    final session = _sessions.doc(liveId);
    final request = session.collection('join_requests').doc(guestUserId);
    await _db.runTransaction((tx) async {
      final sessionSnap = await tx.get(session);
      if (sessionSnap.data()?['hostId'] != host.uid ||
          sessionSnap.data()?['isLive'] != true) {
        throw StateError('HOST_ONLY');
      }
      final requestSnap = await tx.get(request);
      if (requestSnap.data()?['status'] != 'accepted') {
        throw StateError('GUEST_NOT_ON_STAGE');
      }
      final count = (sessionSnap.data()?['guestCount'] as num?)?.toInt() ?? 0;
      if (count < 1) throw StateError('GUEST_COUNTER_INVALID');

      tx.update(request, {
        'status': 'removed',
        'decidedAt': FieldValue.serverTimestamp(),
      });
      tx.update(session, {
        'guestCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> leaveGuest(String liveId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final session = _sessions.doc(liveId);
    final request = session.collection('join_requests').doc(user.uid);
    await _db.runTransaction((tx) async {
      final requestSnap = await tx.get(request);
      if (requestSnap.data()?['status']?.toString() != 'accepted') return;
      final sessionSnap = await tx.get(session);
      final count = (sessionSnap.data()?['guestCount'] as num?)?.toInt() ?? 0;
      tx.update(request, {
        'status': 'left',
        'decidedAt': FieldValue.serverTimestamp(),
      });
      tx.update(session, {
        'guestCount': count > 0 ? FieldValue.increment(-1) : 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchChat(String liveId) =>
      _sessions
          .doc(liveId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(80)
          .snapshots();

  Future<void> sendChat(String liveId, String text) async {
    final user = _user;
    final value = text.trim();
    if (value.isEmpty || value.length > 500) return;
    final session = await _sessions.doc(liveId).get();
    if (!session.exists || session.data()?['isLive'] != true) {
      throw StateError('LIVE_ENDED');
    }
    String bubbleId = 'free';
    try {
      final profile = await _db
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 4));
      bubbleId = await ActiveChatBubbleService.fromProfile(
        firestore: _db,
        uid: user.uid,
        profile: profile.data(),
      );
    } catch (_) {
      // Live comments still send with the free bubble if profile is offline.
    }
    final messages = _sessions.doc(liveId).collection('messages');
    final payload = <String, dynamic>{
      'senderId': user.uid,
      'senderName': user.displayName ?? 'WorldVoice user',
      'senderPhotoUrl': user.photoURL ?? '',
      'text': value,
      'createdAt': FieldValue.serverTimestamp(),
    };
    try {
      // Preferred schema: preserves the user's purchased custom chat bubble.
      await messages.add({...payload, 'bubbleId': bubbleId});
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
      // Compatibility for old live rules until updated Firebase rules are
      // deployed. A denied Firestore write is atomic, so this cannot
      // duplicate a committed message. The message still reaches Live chat,
      // displayed with the default free bubble.
      await messages.add(payload);
    }
  }

  Future<void> cancelPendingRequest(String liveId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final request = _sessions
        .doc(liveId)
        .collection('join_requests')
        .doc(user.uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(request);
      if (snap.data()?['status']?.toString() == 'pending') {
        tx.delete(request);
      }
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchMyRequest(String liveId) {
    final user = _user;
    return _sessions
        .doc(liveId)
        .collection('join_requests')
        .doc(user.uid)
        .snapshots();
  }

  Future<void> end(String liveId) async {
    final ref = _sessions.doc(liveId);
    final snap = await ref.get();
    if (snap.data()?['hostId'] != _user.uid) throw StateError('HOST_ONLY');
    await ref.update({
      'isLive': false,
      'endedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
