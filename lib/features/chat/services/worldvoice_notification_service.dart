import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../rooms/data/room_backend_config.dart';

/// Non-blocking notification bridge. Failure never stops a room or Live.
class WorldVoiceNotificationService {
  WorldVoiceNotificationService._();

  static const _topicKey = 'worldvoice_last_official_push_topic';
  static Future<void> _topicQueue = Future<void>.value();

  static String _announcementTopic(String languageCode) {
    const supported = ['ar', 'en', 'es', 'fr', 'zh', 'ko'];
    final language = supported.contains(languageCode) ? languageCode : 'en';
    return 'worldvoice_announcements_$language';
  }

  static Future<void> syncAnnouncementTopic(String languageCode) {
    final target = _announcementTopic(languageCode);
    _topicQueue = _topicQueue.then((_) => _applyTopic(target));
    return _topicQueue;
  }

  static Future<void> clearAnnouncementTopic() {
    _topicQueue = _topicQueue.then((_) => _applyTopic(null));
    return _topicQueue;
  }

  static Future<void> _applyTopic(String? target) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final old = prefs.getString(_topicKey);
      if (old == target) return;
      final messaging = FirebaseMessaging.instance;
      if (old != null && old.isNotEmpty) {
        await messaging.unsubscribeFromTopic(old);
        await prefs.remove(_topicKey);
      }
      if (target != null && FirebaseAuth.instance.currentUser != null) {
        await messaging.subscribeToTopic(target);
        await prefs.setString(_topicKey, target);
        final deviceToken = await messaging.getToken();
        if (deviceToken != null) {
          await registerDevice(
            token: deviceToken,
            languageCode: target.substring(target.lastIndexOf('_') + 1),
          );
        }
      }
    } catch (error) {
      debugPrint('WorldVoice topic sync: $error');
    }
  }

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
    }, body: jsonEncode(payload)).timeout(
      route == '/system/announcements/publish'
        ? const Duration(seconds: 80)
        : route == '/system/announcements/email/process'
          ? const Duration(seconds: 40)
          : const Duration(seconds: 15),
    );
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
