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
  final Map<String, Future<void>> _modelDownloads =
      <String, Future<void>>{};

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

    return translator
        .translateText(normalized)
        .timeout(const Duration(seconds: 20));
  }

  Future<void> _ensureModel(TranslateLanguage language) async {
    final code = language.bcpCode;
    final exists = await _models.isModelDownloaded(code);
    if (exists) return;

    final pending = _modelDownloads[code];
    if (pending != null) {
      await pending;
      return;
    }

    final download = _downloadModel(code);
    _modelDownloads[code] = download;
    try {
      await download;
    } finally {
      if (identical(_modelDownloads[code], download)) {
        _modelDownloads.remove(code);
      }
    }
  }

  Future<void> _downloadModel(String code) async {
    await _models
        .downloadModel(code, isWifiRequired: false)
        .timeout(const Duration(seconds: 60));

    final ready = await _models
        .isModelDownloaded(code)
        .timeout(const Duration(seconds: 10));
    if (!ready) {
      throw StateError(
        'Translation model $code could not be prepared on this device.',
      );
    }
  }

  Future<void> preparePair({
    required String sourceCode,
    required String targetCode,
  }) async {
    final source = _language(sourceCode);
    final target = _language(targetCode);
    if (source == null || target == null || source == target) return;
    await Future.wait<void>([
      _ensureModel(source),
      _ensureModel(target),
    ]).timeout(const Duration(seconds: 70));
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
    String? fallbackSourceCode,
  }) async {
    final normalized = text.trim();
    if (normalized.isEmpty) return normalized;

    // A detected sentence already in the viewer's target language must
    // never be mistranslated using the room's language as a fallback hint.
    final target = targetCode.toLowerCase().split(RegExp(r'[-_]')).first;
    final explicitScriptLanguage = _scriptLanguage(normalized);
    if (explicitScriptLanguage == target) return normalized;

    Object? localError;
    final sourceCode = _guessSourceCode(
      normalized,
      fallbackSourceCode: fallbackSourceCode,
      targetCode: targetCode,
    );

    // Prefer ML Kit on the device whenever we can identify the source.
    // This keeps normal room/chat translation independent of paid AI quota.
    if (sourceCode != null) {
      try {
        return await translate(
          text: normalized,
          sourceCode: sourceCode,
          targetCode: targetCode,
        );
      } catch (error) {
        localError = error;
      }
    }

    Object? backendError;
    final user = FirebaseAuth.instance.currentUser;
    final configured = endpoint.trim().isNotEmpty;

    if (user != null && configured) {
      try {
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
            .timeout(const Duration(seconds: 12));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            final translation =
                decoded['translation']?.toString().trim() ?? '';
            if (translation.isNotEmpty) return translation;
          }
        } else {
          var message = 'Translation backend unavailable.';
          try {
            final decoded = jsonDecode(response.body);
            if (decoded is Map<String, dynamic>) {
              message = decoded['error']?.toString() ?? message;
            }
          } catch (_) {}
          backendError = StateError(message);
        }
      } catch (error) {
        backendError = error;
      }
    }

    throw StateError(
      backendError?.toString().replaceFirst('Bad state: ', '') ??
          localError?.toString().replaceFirst('Bad state: ', '') ??
          'Translation is unavailable for this language right now.',
    );
  }

  String? _scriptLanguage(String text) {
    if (RegExp(r'[ぁ-ゟ゠-ヿ]').hasMatch(text)) return 'ja';
    if (RegExp(r'[가-힣]').hasMatch(text)) return 'ko';
    if (RegExp(r'[一-鿿]').hasMatch(text)) return 'zh';
    if (RegExp(r'[А-Яа-яЁё]').hasMatch(text)) return 'ru';
    if (RegExp(r'[ऀ-ॿ]').hasMatch(text)) return 'hi';
    if (RegExp(r'[ก-๿]').hasMatch(text)) return 'th';
    if (RegExp(r'[پچژگ]').hasMatch(text)) return 'fa';
    if (RegExp(r'[ٹڈڑںھہۓے]').hasMatch(text)) return 'ur';
    if (RegExp(r'[؀-ۿ]').hasMatch(text)) return 'ar';
    return null;
  }

  String? _guessSourceCode(
    String text, {
    required String targetCode,
    String? fallbackSourceCode,
  }) {
    final target =
        targetCode.toLowerCase().split(RegExp(r'[-_]')).first;
    final fallback = fallbackSourceCode
        ?.toLowerCase()
        .split(RegExp(r'[-_]'))
        .first;

    bool has(RegExp expression) => expression.hasMatch(text);

    String? detected;
    if (has(RegExp(r'[ぁ-ゟ゠-ヿ]'))) {
      detected = 'ja';
    } else if (has(RegExp(r'[가-힣]'))) {
      detected = 'ko';
    } else if (has(RegExp(r'[一-鿿]'))) {
      detected = 'zh';
    } else if (has(RegExp(r'[А-Яа-яЁё]'))) {
      detected = 'ru';
    } else if (has(RegExp(r'[ऀ-ॿ]'))) {
      detected = 'hi';
    } else if (has(RegExp(r'[ก-๿]'))) {
      detected = 'th';
    } else if (has(RegExp(r'[پچژگ]'))) {
      detected = 'fa';
    } else if (has(RegExp(r'[ٹڈڑںھہۓے]'))) {
      detected = 'ur';
    } else if (has(RegExp(r'[؀-ۿ]'))) {
      detected = 'ar';
    }

    if (detected != null && detected != target) return detected;

    if (fallback != null &&
        fallback != target &&
        _language(fallback) != null) {
      return fallback;
    }

    if (target != 'en' && has(RegExp(r'[A-Za-z]'))) {
      return 'en';
    }
    return detected;
  }

  Future<void> dispose() async {
    for (final translator in _translators.values) {
      await translator.close();
    }
    _translators.clear();
    _modelDownloads.clear();
  }
}
