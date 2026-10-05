import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../data/room_backend_config.dart';
import '../data/room_caption.dart';
import '../data/room_teacher_ai_note.dart';

class RoomTeacherAiSpokenAnswer {
  const RoomTeacherAiSpokenAnswer({
    required this.id,
    required this.answer,
    required this.languageCode,
  });

  final String id;
  final String answer;
  final String languageCode;
}

class RoomTeacherAiService {
  RoomTeacherAiService({required this.roomId, this.collectionName = 'rooms'});

  final String roomId;
  final String collectionName;

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

  String get statusEndpoint =>
      RoomBackendConfig.endpoint('/ai/status');

  bool get isConfigured => endpoint.trim().isNotEmpty;
  bool get isAskConfigured => askEndpoint.trim().isNotEmpty;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String get _contextType =>
      collectionName == 'live_sessions' ? 'live' : 'room';


  Stream<List<RoomTeacherAiSpokenAnswer>> watchSpokenAnswers() {
    return _db
        .collection(collectionName)
        .doc(roomId)
        .snapshots()
        .map((snapshot) {
          final raw = snapshot.data()?['teacherAiVoice'];
          if (raw is! Map) return const <RoomTeacherAiSpokenAnswer>[];
          final data = Map<String, dynamic>.from(raw);
          final id = (data['id'] ?? '').toString().trim();
          final answer = (data['answer'] ?? '').toString().trim();
          if (id.isEmpty || answer.isEmpty) {
            return const <RoomTeacherAiSpokenAnswer>[];
          }
          return <RoomTeacherAiSpokenAnswer>[
            RoomTeacherAiSpokenAnswer(
              id: id,
              answer: answer,
              languageCode:
                  (data['languageCode'] ?? 'en').toString().trim(),
            ),
          ];
        });
  }

  Stream<List<RoomTeacherAiNote>> watchNotes({int limit = 20}) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream<List<RoomTeacherAiNote>>.empty();
    }
    return _db
        .collection(collectionName)
        .doc(roomId)
        .collection('teacher_ai_notes')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(RoomTeacherAiNote.fromDoc)
              .toList(growable: false),
        );
  }

  Future<bool> probeAvailability() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || statusEndpoint.trim().isEmpty) return false;

    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) return false;

    try {
      final response = await http
          .post(
            Uri.parse(statusEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'context': _contextType,
              'roomId': roomId,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }

      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> &&
            decoded['code']?.toString() == 'AI_SERVICE_UNAVAILABLE') {
          return false;
        }
      } catch (_) {}
      return false;
    } catch (_) {
      return false;
    }
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
            'context': _contextType,
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
          if (decoded['code']?.toString() == 'AI_SERVICE_UNAVAILABLE') {
            throw StateError('AI_SERVICE_UNAVAILABLE');
          }
          message = decoded['error']?.toString() ?? message;
        }
      } on StateError {
        rethrow;
      } catch (_) {
        // Keep the generic message.
      }
      final lower = message.toLowerCase();
      if (response.statusCode == 429 &&
          (lower.contains('credit') ||
              lower.contains('quota') ||
              lower.contains('billing'))) {
        throw StateError('AI_SERVICE_UNAVAILABLE');
      }
      throw StateError(message);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Teacher AI returned an invalid response.');
    }

    if (decoded['ignored'] == true) {
      return '';
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
        'context': _contextType,
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