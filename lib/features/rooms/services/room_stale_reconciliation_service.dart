import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Requests server-side stale-room reconciliation, never closes rooms directly.
/// One attempt per minute per app instance, with no UI-blocking network wait.
abstract final class RoomStaleReconciliationService {
  static DateTime? _lastAttempt;
  static const _baseUrl = String.fromEnvironment(
    'WORLDVOICE_WORLDBOND_BACKEND_URL',
    defaultValue: 'https://worldvoice-teacher-ai.onrender.com',
  );

  static Future<void> refresh() async {
    final now = DateTime.now();
    if (_lastAttempt != null &&
        now.difference(_lastAttempt!) < const Duration(minutes: 1)) return;
    _lastAttempt = now;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final token = await user.getIdToken();
      if (token == null || token.isEmpty) return;
      final base = Uri.parse(_baseUrl);
      if (base.scheme != 'https' || !base.hasAuthority) return;
      final uri = base.replace(
        path: '${base.path.endsWith('/') ? base.path.substring(0, base.path.length - 1) : base.path}/rooms/reconcile-stale',
      );
      final result = await http.get(uri,
        headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 12));
      if (result.statusCode != 200) {
        debugPrint('WorldVoice stale room reconcile: HTTP ${result.statusCode}');
      }
    } catch (e) {
      // Never prevent opening the rooms list if the Render service is asleep.
      debugPrint('WorldVoice stale room reconcile unavailable: $e');
    }
  }
}
