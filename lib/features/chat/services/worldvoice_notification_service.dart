import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../rooms/data/room_backend_config.dart';

/// Non-blocking notification bridge. Failure never stops a room or Live.
class WorldVoiceNotificationService {
  WorldVoiceNotificationService._();

  static Future<Map<String, dynamic>> post(
      String route, Map<String, dynamic> payload) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in required');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) throw StateError('Missing ID token');
    final url = Uri.parse('${RoomBackendConfig.socialBaseUrl}$route');
    if (url.scheme != 'https') throw StateError('Secure server required');
    final response = await http.post(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    }, body: jsonEncode(payload)).timeout(const Duration(seconds: 15));
    final body = jsonDecode(response.body);
    if (response.statusCode >= 300 || body is! Map ||
        body['ok'] != true) {
      throw StateError(body is Map
          ? (body['error'] ?? 'Notification unavailable').toString()
          : 'Notification unavailable');
    }
    return Map<String, dynamic>.from(body);
  }

  static Future<void> publishActivity({
    required String kind,
    required String sessionId,
  }) async {
    try {
      await post('/system/activity/publish', {
        'kind': kind, 'sessionId': sessionId,
      });
    } catch (error) {
      debugPrint('WorldVoice activity publish: $error');
    }
  }

  static Future<void> registerDevice({
    required String token, required String languageCode,
  }) async {
    try {
      await post('/system/notifications/device', {
        'token': token, 'languageCode': languageCode,
      });
    } catch (error) {
      debugPrint('WorldVoice push registration: $error');
    }
  }
}
