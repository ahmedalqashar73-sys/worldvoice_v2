import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../data/room_backend_config.dart';
import '../data/room_caption.dart';
import '../data/room_teacher_ai_note.dart';

class RoomTeacherAiService {
  RoomTeacherAiService({required this.roomId});

  final String roomId;

  static const String _explicitEndpoint =
      String.fromEnvironment('WORLDVOICE_TEACHER_AI_ENDPOINT');

  static const String _explicitAskEndpoint =
      String.fromEnvironment('WORLDVOICE_TEACHER_AI_ASK_ENDPOINT');

  String get endpoint {
    final explicit = _explicitEndpoint.trim();
    return explicit.isNotEmpty
        ? explicit
        : RoomBackendConfig.endpoint('/teacher-ai');
  }

  String get askEndpoint {
    final explicit = _explicitAskEndpoint.trim();
    return explicit.isNotEmpty
        ? explicit
        : RoomBackendConfig.endpoint('/teacher-ai/ask');
  }

  bool get isConfigured => endpoint.trim().isNotEmpty;
  bool get isAskConfigured => askEndpoint.trim().isNotEmpty;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Stream<List<RoomTeacherAiNote>> watchNotes({int limit = 20}) {
    return _db
        .collection('rooms')
        .doc(roomId)
        .collection('teacher_ai_notes')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(RoomTeacherAiNote.fromDoc)
              .toList(growable: false),
        );
  }

  Future<String> ask({
    required String prompt,
    required String roomLanguageCode,
  }) async {
    final normalized = prompt.trim();
    if (normalized.isEmpty) {
      throw StateError('Ask Teacher AI a question first.');
    }
    if (normalized.length > 1200) {
      throw StateError('Teacher AI questions are limited to 1200 characters.');
    }
    if (!isAskConfigured) {
      throw StateError('Teacher AI backend is not configured.');
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Sign in is required to use Teacher AI.');
    }

    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Could not authorize Teacher AI.');
    }

    final response = await http
        .post(
          Uri.parse(askEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'roomId': roomId,
            'prompt': normalized,
            'roomLanguageCode': roomLanguageCode.trim().isEmpty
                ? 'en'
                : roomLanguageCode.trim(),
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = 'Teacher AI request failed.';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          message = decoded['error']?.toString() ?? message;
        }
      } catch (_) {
        // Keep the generic message.
      }
      throw StateError(message);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Teacher AI returned an invalid response.');
    }

    final answer = decoded['answer']?.toString().trim() ?? '';
    if (answer.isEmpty) {
      throw StateError('Teacher AI returned an empty response.');
    }
    return answer;
  }

  Future<bool> submitCaption({
    required RoomCaption caption,
    required String roomLanguageCode,
  }) async {
    if (!isConfigured) return false;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || caption.userId != user.uid) return false;

    final idToken = await user.getIdToken();
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        if (idToken != null && idToken.isNotEmpty)
          'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'roomId': roomId,
        'captionId': caption.id,
        'userId': caption.userId,
        'displayName': caption.displayName,
        'text': caption.text,
        'languageCode': caption.languageCode,
        'roomLanguageCode': roomLanguageCode,
      }),
    );

    return response.statusCode >= 200 && response.statusCode < 300;
  }
}
