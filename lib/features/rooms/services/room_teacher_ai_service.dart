import 'dart:async';
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
        : RoomBackendConfig.aiEndpoint('/teacher-ai');
  }

  String get askEndpoint {
    final explicit = _explicitAskEndpoint.trim();
    return explicit.isNotEmpty
        ? explicit
        : RoomBackendConfig.aiEndpoint('/teacher-ai/ask');
  }

  String get statusEndpoint =>
      RoomBackendConfig.aiEndpoint('/ai/status');

  bool get isConfigured => endpoint.trim().isNotEmpty;
  bool get isAskConfigured => askEndpoint.trim().isNotEmpty;

  /// Safe status label only. Do not expose provider keys or HTTP bodies.
  String? lastAvailabilityError;

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
        .snapshots()
        .map((snapshot) {
          // Avoid a composite Firestore index requirement; only read the
          // current user's corrections, then sort in memory.
          final notes = snapshot.docs
              .map(RoomTeacherAiNote.fromDoc)
              .toList(growable: false)
            ..sort((a, b) => (b.createdAt?.millisecondsSinceEpoch ?? 0)
                .compareTo(a.createdAt?.millisecondsSinceEpoch ?? 0));
          return notes.take(limit).toList(growable: false);
        });
  }

  Future<bool> probeAvailability() async {
    lastAvailabilityError = null;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      lastAvailabilityError = 'SIGN_IN_REQUIRED';
      return false;
    }
    if (statusEndpoint.trim().isEmpty) {
      lastAvailabilityError = 'BACKEND_URL_MISSING';
      return false;
    }

    try {
      final idToken = await user.getIdToken()
          .timeout(const Duration(seconds: 12));
      if (idToken == null || idToken.isEmpty) {
        lastAvailabilityError = 'AUTH_TOKEN_UNAVAILABLE';
        return false;
      }
      // Allow a cold Render instance time to wake; 12 seconds previously
      // mislabeled a slow server as a permanently offline AI provider.
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
          .timeout(const Duration(seconds: 45));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      // Public codes are safe to surface. The backend's raw error text
      // could contain internal details, so never show it to room members.
      if (response.statusCode == 401) {
        lastAvailabilityError = 'AUTH_REJECTED';
      } else if (response.statusCode == 403) {
        lastAvailabilityError = 'ROOM_ACCESS_DENIED';
      } else if (response.statusCode == 404) {
        lastAvailabilityError = 'ROOM_NOT_FOUND';
      } else if (response.statusCode == 429) {
        lastAvailabilityError = 'AI_PROVIDER_LIMIT';
      } else if (response.statusCode == 503) {
        // Only display the server's documented public error codes.
        // Never forward arbitrary provider error messages to the UI.
        String? safeCode;
        try {
          final responseData = jsonDecode(response.body);
          if (responseData is Map<String, dynamic>) {
            final code = responseData['code']?.toString();
            if (code == 'AI_MODEL_CONFIGURATION' ||
                code == 'AI_SERVICE_UNAVAILABLE') {
              safeCode = code;
            }
          }
        } catch (_) {
          // Old servers can return plain-text error responses.
        }
        lastAvailabilityError = safeCode ?? 'AI_SERVICE_UNAVAILABLE';
      } else {
        lastAvailabilityError = 'SERVER_HTTP_${response.statusCode}';
      }
      return false;
    } on TimeoutException {
      lastAvailabilityError = 'NETWORK_TIMEOUT';
      return false;
    } catch (error) {
      lastAvailabilityError = error is FormatException
          ? 'BAD_SERVER_RESPONSE'
          : 'NETWORK_ERROR';
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
        .timeout(const Duration(seconds: 45));

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

  RoomTeacherAiNote localPronunciationNote({
    required RoomCaption caption,
    required String roomLanguageCode,
  }) {
    final language = roomLanguageCode
        .trim()
        .toLowerCase()
        .split(RegExp(r'[-_]'))
        .first;
    final text = caption.text.trim();
    final lower = text.toLowerCase();

    String tip;
    if (language == 'en') {
      if (RegExp(r'\b(th|this|that|these|those|think|three)\b')
          .hasMatch(lower)) {
        tip =
            'For “th”, place the tongue lightly between the teeth and let the air pass; avoid replacing it with s, z, t, or d.';
      } else if (RegExp(r'\b(v|very|voice|have|love)\b').hasMatch(lower)) {
        tip =
            'Keep “v” different from “w”: touch the lower lip to the upper teeth for v, then release the air.';
      } else if (RegExp(r'\br\w*').hasMatch(lower)) {
        tip =
            'For English r, pull the tongue slightly back without touching the roof of the mouth; keep the sound smooth.';
      } else if (RegExp(r'\w+ed\b').hasMatch(lower)) {
        tip =
            'Pay attention to -ed endings: they can sound like /t/, /d/, or /ɪd/ depending on the final sound.';
      } else if (text.split(RegExp(r'\s+')).length >= 4) {
        tip =
            'Keep the stressed words clear and reduce the small grammar words. English rhythm sounds more natural when every word is not equally strong.';
      } else {
        tip =
            'Say the phrase once slowly, then again at normal speed. Keep the main stressed syllable clear and avoid adding extra vowels between consonants.';
      }
    } else if (language == 'ar') {
      if (RegExp(r'[عحخغ]').hasMatch(text)) {
        tip =
            'ركّز على الحروف الحلقية مثل ع، ح، خ، غ؛ أخرج الصوت من موضعه من غير إضافة حركة زائدة.';
      } else if (RegExp(r'[صضطظق]').hasMatch(text)) {
        tip =
            'انتبه للحروف المفخمة مثل ص، ض، ط، ظ، ق؛ اجعل التفخيم واضحًا من غير مبالغة.';
      } else {
        tip =
            'انطق الجملة بوضوح وبإيقاع طبيعي، وركّز على طول الحركات والتفريق بين الحروف المتقاربة.';
      }
    } else if (language == 'es') {
      tip =
          'Keep Spanish vowels short and pure, and pronounce each syllable clearly. Avoid turning vowels into English-style diphthongs.';
    } else if (language == 'fr') {
      tip =
          'Keep French vowels steady, link words naturally when appropriate, and avoid stressing every syllable equally.';
    } else if (language == 'de') {
      tip =
          'Keep German consonants crisp and make vowel length clear; long and short vowels can change how natural the word sounds.';
    } else {
      tip =
          'Repeat the recognized phrase slowly, then at natural speed. Keep the stressed syllables clear and avoid adding extra sounds between consonants.';
    }

    return RoomTeacherAiNote(
      id: 'local_pron_${DateTime.now().microsecondsSinceEpoch}',
      userId: caption.userId,
      displayName: caption.displayName,
      originalText: text,
      correction: '',
      languageCode: language.isEmpty ? caption.languageCode : language,
      pronunciationTip: tip,
      createdAt: DateTime.now(),
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