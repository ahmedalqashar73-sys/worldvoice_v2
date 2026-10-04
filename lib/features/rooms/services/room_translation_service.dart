import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:http/http.dart' as http;

import '../data/room_backend_config.dart';

class RoomTranslationService {
  RoomTranslationService({
    required this.roomId,
    this.collectionName = 'rooms',
  });

  final String roomId;
  final String collectionName;

  static const String _explicitEndpoint =
      String.fromEnvironment('WORLDVOICE_TRANSLATION_ENDPOINT');

  String get endpoint {
    final explicit = _explicitEndpoint.trim();
    return explicit.isNotEmpty
        ? explicit
        : RoomBackendConfig.endpoint('/translate');
  }

  String get _contextType =>
      collectionName == 'live_sessions' ? 'live' : 'room';
  final OnDeviceTranslatorModelManager _models =
      OnDeviceTranslatorModelManager();
  final Map<String, OnDeviceTranslator> _translators =
      <String, OnDeviceTranslator>{};

  Future<String> translate({
    required String text,
    required String sourceCode,
    required String targetCode,
  }) async {
    final normalized = text.trim();
    if (normalized.isEmpty) return normalized;

    final source = _language(sourceCode);
    final target = _language(targetCode);
    if (source == null || target == null || source == target) {
      return normalized;
    }

    await _ensureModel(source);
    await _ensureModel(target);

    final key = '${source.bcpCode}->${target.bcpCode}';
    final translator = _translators.putIfAbsent(
      key,
      () => OnDeviceTranslator(
        sourceLanguage: source,
        targetLanguage: target,
      ),
    );

    return translator.translateText(normalized);
  }

  Future<void> _ensureModel(TranslateLanguage language) async {
    final code = language.bcpCode;
    final exists = await _models.isModelDownloaded(code);
    if (!exists) {
      await _models.downloadModel(
        code,
        isWifiRequired: false,
      );
    }
  }

  TranslateLanguage? _language(String rawCode) {
    final code = rawCode.toLowerCase().split(RegExp('[-_]')).first;
    switch (code) {
      case 'ar':
        return TranslateLanguage.arabic;
      case 'en':
        return TranslateLanguage.english;
      case 'es':
        return TranslateLanguage.spanish;
      case 'fr':
        return TranslateLanguage.french;
      case 'de':
        return TranslateLanguage.german;
      case 'it':
        return TranslateLanguage.italian;
      case 'pt':
        return TranslateLanguage.portuguese;
      case 'tr':
        return TranslateLanguage.turkish;
      case 'ru':
        return TranslateLanguage.russian;
      case 'zh':
        return TranslateLanguage.chinese;
      case 'ja':
        return TranslateLanguage.japanese;
      case 'ko':
        return TranslateLanguage.korean;
      case 'ur':
        return TranslateLanguage.urdu;
      case 'fa':
        return TranslateLanguage.persian;
      case 'id':
        return TranslateLanguage.indonesian;
      case 'th':
        return TranslateLanguage.thai;
      case 'hi':
        return TranslateLanguage.hindi;
      default:
        return null;
    }
  }

  Future<String> translateAuto({
    required String text,
    required String targetCode,
  }) async {
    final normalized = text.trim();
    if (normalized.isEmpty) return normalized;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Sign in is required to translate messages.');
    }
    if (endpoint.trim().isEmpty) {
      throw StateError('WorldVoice translation backend is not configured.');
    }

    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Could not authorize translation.');
    }

    final response = await http
        .post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'context': _contextType,
            'roomId': roomId,
            'text': normalized,
            'targetLanguageCode': targetCode.trim().isEmpty
                ? 'en'
                : targetCode.trim().toLowerCase(),
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = 'Translation failed.';
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
      throw StateError('Translation returned an invalid response.');
    }
    final translation = decoded['translation']?.toString().trim() ?? '';
    if (translation.isEmpty) {
      throw StateError('Translation returned an empty response.');
    }
    return translation;
  }

  Future<void> dispose() async {
    for (final translator in _translators.values) {
      await translator.close();
    }
    _translators.clear();
  }
}
