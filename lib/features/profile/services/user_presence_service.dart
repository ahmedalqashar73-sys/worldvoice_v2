import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserPresenceService {
  UserPresenceService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> markOnline() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).set({
      'isOnline': true,
      'lastActiveAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> heartbeat() => markOnline();

  static Future<void> markOffline() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).set({
      'isOnline': false,
      'lastActiveAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

class PresenceSession {
  PresenceSession();

  Timer? _heartbeat;

  void start() {
    _heartbeat?.cancel();
    unawaited(UserPresenceService.markOnline());
    _heartbeat = Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(UserPresenceService.heartbeat()),
    );
  }

  void stop() {
    _heartbeat?.cancel();
    _heartbeat = null;
    unawaited(UserPresenceService.markOffline());
  }

  void dispose() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }
}
