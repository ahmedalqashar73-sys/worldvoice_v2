import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class UserPresenceService {
  UserPresenceService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Presence must NEVER create a user profile. On a fresh login the onboarding
  // flow owns that document; a presence-only document makes a completed profile
  // appear missing and fails the strict Firestore users/create rules.
  static Future<void> _updateExistingProfile(Map<String, Object?> fields) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _db.collection('users').doc(user.uid).update(fields);
    } on FirebaseException catch (error) {
      // An absent profile or an outdated deployed rule should not crash login
      // or show an unrelated PERMISSION_DENIED message on the profile screen.
      if (error.code != 'not-found' && error.code != 'permission-denied') {
        debugPrint('WorldVoice presence update failed: ${error.code}');
      }
    } catch (error) {
      debugPrint('WorldVoice presence update failed: $error');
    }
  }

  static Future<void> markOnline() => _updateExistingProfile({
        'isOnline': true,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });

  static Future<void> heartbeat() => markOnline();

  static Future<void> markOffline() => _updateExistingProfile({
        'isOnline': false,
        'lastActiveAt': FieldValue.serverTimestamp(),
        'lastSeenAt': FieldValue.serverTimestamp(),
      });
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
