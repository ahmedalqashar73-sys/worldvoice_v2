import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    String topic = '',
  }) async {
    final user = _user;
    final ref = _sessions.doc(channelId);
    await ref.set({
      'channelId': channelId,
      'hostId': user.uid,
      'hostName': user.displayName ?? 'WorldVoice host',
      'hostPhotoUrl': user.photoURL ?? '',
      'languageCode': languageCode,
      'topic': topic.trim(),
      'isLive': true,
      'viewerCount': 0,
      'guestCount': 0,
      'startedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchOpen() => _sessions
      .where('isLive', isEqualTo: true)
      .limit(100)
      .snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> watch(String liveId) =>
      _sessions.doc(liveId).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchJoinRequests(String liveId) =>
      _sessions
          .doc(liveId)
          .collection('join_requests')
          .where('status', isEqualTo: 'pending')
          .snapshots();

  Future<void> enterViewer(String liveId) async {
    final user = _user;
    final session = _sessions.doc(liveId);
    final viewer = session.collection('viewers').doc(user.uid);
    await _db.runTransaction((tx) async {
      final existing = await tx.get(viewer);
      if (!existing.exists) {
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

  Future<void> requestToJoin(String liveId) async {
    final user = _user;
    await _sessions.doc(liveId).collection('join_requests').doc(user.uid).set({
      'uid': user.uid,
      'displayName': user.displayName ?? 'WorldVoice user',
      'photoUrl': user.photoURL ?? '',
      'status': 'pending',
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> decideRequest({
    required String liveId,
    required String userId,
    required bool accept,
  }) async {
    final session = _sessions.doc(liveId);
    final snap = await session.get();
    if (snap.data()?['hostId'] != _user.uid) throw StateError('HOST_ONLY');
    await session.collection('join_requests').doc(userId).update({
      'status': accept ? 'accepted' : 'declined',
      'decidedAt': FieldValue.serverTimestamp(),
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
