import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileSocialService {
  ProfileSocialService._();

  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> _sub(
    String uid,
    String name,
  ) {
    return _db.collection('users').doc(uid).collection(name);
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> followers(String uid) =>
      _sub(uid, 'followers').snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>> following(String uid) =>
      _sub(uid, 'following').snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>> visitors(String uid) =>
      _sub(uid, 'profile_visitors')
          .orderBy('visitedAt', descending: true)
          .snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>> visitedProfiles(
    String uid,
  ) =>
      _sub(uid, 'visited_profiles')
          .orderBy('visitedAt', descending: true)
          .snapshots();

  static Future<bool> isFollowing(String targetUid) async {
    final me = _auth.currentUser?.uid;
    if (me == null || me == targetUid) return false;
    final doc = await _sub(me, 'following').doc(targetUid).get();
    return doc.exists;
  }

  static Future<void> toggleFollow(String targetUid) async {
    final me = _auth.currentUser?.uid;
    if (me == null || me == targetUid) return;

    final myFollowing = _sub(me, 'following').doc(targetUid);
    final theirFollowers = _sub(targetUid, 'followers').doc(me);
    final existing = await myFollowing.get();

    final batch = _db.batch();
    if (existing.exists) {
      batch.delete(myFollowing);
      batch.delete(theirFollowers);
    } else {
      final now = FieldValue.serverTimestamp();
      batch.set(myFollowing, {'createdAt': now});
      batch.set(theirFollowers, {'createdAt': now});
    }
    await batch.commit();

    await _refreshCounts(me);
    await _refreshCounts(targetUid);
  }

  static Future<void> _refreshCounts(String uid) async {
    final followersCount = await _sub(uid, 'followers').count().get();
    final followingCount = await _sub(uid, 'following').count().get();
    await _db.collection('users').doc(uid).set({
      'followersCount': followersCount.count ?? 0,
      'followingCount': followingCount.count ?? 0,
    }, SetOptions(merge: true));
  }

  static Future<Set<String>> mutualPartnerIds(String uid) async {
    final results = await Future.wait([
      _sub(uid, 'followers').get(),
      _sub(uid, 'following').get(),
    ]);
    final followersIds = results[0].docs.map((doc) => doc.id).toSet();
    final followingIds = results[1].docs.map((doc) => doc.id).toSet();
    return followersIds.intersection(followingIds);
  }

  static Future<void> recordVisit(String targetUid) async {
    final viewer = _auth.currentUser;
    if (viewer == null || viewer.uid == targetUid) return;

    final viewerSnap = await _db.collection('users').doc(viewer.uid).get();
    final viewerData = viewerSnap.data() ?? const <String, dynamic>{};
    final targetSnap = await _db.collection('users').doc(targetUid).get();
    final targetData = targetSnap.data() ?? const <String, dynamic>{};

    final viewerIsVip = viewerData['isVip'] == true;
    final hideMyVisits = viewerData['hideVisitLog'] == true;

    final batch = _db.batch();
    final now = FieldValue.serverTimestamp();

    if (!(viewerIsVip && hideMyVisits)) {
      batch.set(
        _sub(targetUid, 'profile_visitors').doc(viewer.uid),
        {
          'visitedAt': now,
          'displayName': viewerData['displayName'],
          'username': viewerData['username'],
          'photoUrl': viewerData['photoUrl'],
        },
        SetOptions(merge: true),
      );
    }

    batch.set(
      _sub(viewer.uid, 'visited_profiles').doc(targetUid),
      {
        'visitedAt': now,
        'displayName': targetData['displayName'],
        'username': targetData['username'],
        'photoUrl': targetData['photoUrl'],
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }
}
