import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../data/room_backend_config.dart';
import '../data/room_caption.dart';

class RoomCaptionService {
  RoomCaptionService({required this.roomId, this.collectionName = 'rooms'});

  final String roomId;
  final String collectionName;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  User? get _user => FirebaseAuth.instance.currentUser;

  String get transcriptionEndpoint =>
      RoomBackendConfig.aiEndpoint('/speech/transcribe');

  CollectionReference<Map<String, dynamic>> get _captions =>
      _db.collection(collectionName).doc(roomId).collection('captions');

  Stream<List<RoomCaption>> watchLatest({int limit = 30}) {
    return _captions
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(RoomCaption.fromDoc)
              .where((caption) => caption.text.trim().isNotEmpty)
              .toList(growable: false),
        );
  }

  Future<String> transcribeWav(
    Uint8List wavBytes, {
    String? languageCode,
  }) async {
    final user = _user;
    if (user == null) {
      throw StateError('Sign in is required for live transcription.');
    }
    final endpoint = transcriptionEndpoint.trim();
    if (endpoint.isEmpty) {
      throw StateError('WorldVoice transcription backend is not configured.');
    }
    if (wavBytes.length < 1024) return '';

    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Could not authorize live transcription.');
    }

    final uri = Uri.parse(endpoint).replace(
      queryParameters: {
        'context': collectionName == 'live_sessions' ? 'live' : 'room',
        'roomId': roomId,
        if (languageCode?.trim().isNotEmpty == true)
          'languageCode': languageCode!.trim().toLowerCase(),
      },
    );

    final response = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'audio/wav',
          },
          body: wavBytes,
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = 'Live transcription failed.';
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
        // Keep the generic message when the server returns non-JSON text.
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
    if (decoded is! Map<String, dynamic>) return '';
    return decoded['text']?.toString().trim() ?? '';
  }

  Future<void> publishFinal({
    required String displayName,
    required String text,
    required String languageCode,
  }) async {
    final user = _user;
    final normalized = text.trim();
    if (user == null || normalized.isEmpty) return;

    await _captions.add({
      'userId': user.uid,
      'displayName':
          displayName.trim().isEmpty ? 'WorldVoice user' : displayName.trim(),
      'text': normalized.length > 400
          ? normalized.substring(0, 400)
          : normalized,
      'languageCode':
          languageCode.trim().isEmpty ? 'en' : languageCode.toLowerCase(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
