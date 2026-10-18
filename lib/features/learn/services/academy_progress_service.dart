import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/academy_catalog.dart';

/// Learning progress is a private checklist, never coins, XP or certification.
/// The signed-in user can only create their own immutable completion records.
class AcademyProgressService {
  AcademyProgressService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _db.collection('users').doc(uid).collection('academy_progress');

  Stream<Set<String>> completedLessons(String uid) =>
      _collection(uid).snapshots().map((snapshot) => snapshot.docs
          .where((doc) => doc.data()['completed'] == true)
          .map((doc) => doc.id)
          .toSet());

  Future<void> complete(AcademyUnit unit, AcademyLessonKind kind) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Sign in to save your Academy lesson progress.');
    }
    final id = unit.lessonId(kind);
    final ref = _collection(uid).doc(id);
    final existing = await ref.get();
    if (existing.exists) return; // Firestore rule allows creates, not edits.
    await ref.set(<String, dynamic>{
      'completed': true,
      'language': unit.language,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }
}
