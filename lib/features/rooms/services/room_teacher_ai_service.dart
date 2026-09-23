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

  String get endpoint {
    final explicit = _explicitEndpoint.trim();
    return explicit.isNotEmpty
        ? explicit
        : RoomBackendConfig.endpoint('/teacher-ai');
  }

  bool get isConfigured => endpoint.trim().isNotEmpty;

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
