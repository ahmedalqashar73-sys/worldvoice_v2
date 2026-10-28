import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/academy_catalog.dart';

/// Per-account cache survives app restarts and protects progress when the
/// deployed Firebase rules or network are temporarily unavailable.
///
/// A local-only completion is NEVER described as cloud-synchronized.
class AcademyProgressService {
  AcademyProgressService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static String _cacheKey(String uid) => 'worldvoice.academy.v2.$uid.completed';
  static String _pendingKey(String uid) => 'worldvoice.academy.v2.$uid.pending';

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _db.collection('users').doc(uid).collection('academy_progress');

  Future<Set<String>> _local(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_cacheKey(uid))?.toSet() ?? <String>{};
  }

  Future<void> _addLocal(String uid, String id, {required bool pending}) async {
    final prefs = await SharedPreferences.getInstance();
    final local = prefs.getStringList(_cacheKey(uid))?.toSet() ?? <String>{};
    local.add(id);
    await prefs.setStringList(_cacheKey(uid), local.toList()..sort());
    final toSync = prefs.getStringList(_pendingKey(uid))?.toSet() ?? <String>{};
    if (pending) {
      toSync.add(id);
    } else {
      toSync.remove(id);
    }
    await prefs.setStringList(_pendingKey(uid), toSync.toList()..sort());
  }

  /// Always starts with local progress. Network error does not erase lessons.
  Stream<Set<String>> completedLessons(String uid) async* {
    final cached = await _local(uid);
    yield cached;
    try {
      await for (final snapshot in _collection(uid).snapshots()) {
        final cloud = snapshot.docs
            .where((doc) => doc.data()['completed'] == true)
            .map((doc) => doc.id).toSet();
        final union = {...cached, ...cloud};
        yield union;
        // Refresh local cache from server data; never discard unsynced lessons.
        for (final id in cloud.difference(cached)) {
          await _addLocal(uid, id, pending: false);
        }
      }
    } on FirebaseException {
      // Show only what really exists on device, without claiming cloud sync.
      yield await _local(uid);
    }
  }

  /// Returns true when cloud synced, false for local-only pending sync.
  /// A signed-in UID is mandatory so progress is never shared across accounts.
  Future<bool> complete(AcademyUnit unit, AcademyLessonKind kind) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Sign in to save Academy progress.');
    }
    final id = unit.lessonId(kind);
    final ref = _collection(uid).doc(id);
    try {
      final existing = await ref.get();
      if (!existing.exists) {
        await ref.set(<String, dynamic>{
          'completed': true,
          'language': unit.language,
          'completedAt': FieldValue.serverTimestamp(),
        });
      }
      await _addLocal(uid, id, pending: false);
      return true;
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied' &&
          error.code != 'unavailable' &&
          error.code != 'deadline-exceeded') {
        rethrow;
      }
      await _addLocal(uid, id, pending: true);
      return false;
    }
  }

  /// Retry explicitly; do not pretend a pending save was already synchronized.
  Future<int> synchronizePending() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return 0;
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_pendingKey(uid)) ?? <String>[];
    var synced = 0;
    for (final id in pending) {
      // Limit to catalog-approved immutable Academy IDs, not arbitrary paths.
      AcademyUnit? selected;
      AcademyLessonKind? kind;
      for (final unit in academyUnits) {
        for (final type in AcademyLessonKind.values) {
          if (id == unit.lessonId(type)) {
            selected = unit;
            kind = type;
            break;
          }
        }
        if (selected != null) break;
      }
      if (selected == null || kind == null) continue;
      final ref = _collection(uid).doc(id);
      try {
        final existing = await ref.get();
        if (!existing.exists) {
          await ref.set({
            'completed': true,
            'language': selected.language,
            'completedAt': FieldValue.serverTimestamp(),
          });
        }
        await _addLocal(uid, id, pending: false);
        synced++;
      } on FirebaseException {
        // Remain pending until connectivity / deployed rules are repaired.
        break;
      }
    }
    return synced;
  }

  Future<int> pendingCount() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return 0;
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_pendingKey(uid)) ?? <String>[]).length;
  }
}
