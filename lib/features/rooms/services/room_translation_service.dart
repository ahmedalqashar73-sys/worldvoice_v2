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

  /// Try on-device ML Kit first; use authenticated translation if unavailable.
  Future<String> translate({
    required String text,
    required String sourceCode,
    required String targetCode,
  }) async {
    final normalized = text.trim();
    if (normalized.isEmpty) return normalized;
    final source = _language(sourceCode);
    final target = _language(targetCode);
    final rawSource = sourceCode.toLowerCase().split(RegExp(r'[-_]')).first;
    final rawTarget = targetCode.toLowerCase().split(RegExp(r'[-_]')).first;
    if (rawSource.isNotEmpty && rawSource == rawTarget) return normalized;
    if (source != null && target != null && source == target) {
      return normalized;
    }

    Object? localFailure;
    if (source != null && target != null) {
      try {
        await Future.wait<void>([
          _ensureModel(source),
          _ensureModel(target),
        ]).timeout(const Duration(seconds: 75));
        final key = '${source.bcpCode}->${target.bcpCode}';
        final translator = _translators.putIfAbsent(
          key,
          () => OnDeviceTranslator(
            sourceLanguage: source,
            targetLanguage: target,
          ),
        );
        final translated = (await translator
                .translateText(normalized)
                .timeout(const Duration(seconds: 20)))
            .trim();
        if (translated.isNotEmpty) return translated;
        localFailure = StateError('On-device translation returned no text.');
      } catch (error) {
        localFailure = error;
      }
    } else {
      localFailure = StateError('On-device language model is unsupported.');
    }

    try {
      return await _translateViaBackend(
        text: normalized,
        targetCode: targetCode,
      );
    } catch (remoteError) {
      final detail = remoteError.toString().replaceFirst('Bad state: ', '');
      final localDetail =
          localFailure?.toString().replaceFirst('Bad state: ', '') ?? '';
      throw StateError(
        'Translation unavailable: $detail'
        '${localDetail.isEmpty ? '' : ' (device: $localDetail)'}',
      );
    }
  }

  Future<String> _translateViaBackend({
    required String text,
    required String targetCode,
  }) async {
    final remoteEndpoint = endpoint.trim();
    if (remoteEndpoint.isEmpty) {
      throw StateError('WorldVoice translation service is not configured.');
    }
    if (text.length > 500) {
      throw StateError('Translation is limited to 500 characters at a time.');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in to use translation.');
    final token = await user.getIdToken().timeout(
      const Duration(seconds: 12),
    );
    if (token == null || token.isEmpty) {
      throw StateError('Could not authorize translation.');
    }
    final response = await http
        .post(
          Uri.parse(remoteEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'context': _contextType,
            'roomId': roomId,
            'text': text,
            'targetLanguageCode': targetCode.trim().isEmpty
                ? 'en'
                : targetCode.trim().toLowerCase(),
          }),
        )
        .timeout(const Duration(seconds: 18));
    Map<String, dynamic> decoded = <String, dynamic>{};
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) decoded = body;
    } catch (_) {
      // A non-JSON response is reported with its HTTP status.
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        decoded['error']?.toString().trim().isNotEmpty == true
            ? decoded['error'].toString()
            : 'Translation server returned HTTP ${response.statusCode}.',
      );
    }
    final result = decoded['translation']?.toString().trim() ?? '';
    if (result.isEmpty) {
      throw StateError('Translation server returned no text.');
    }
    return result;
  }

  Future<void> _ensureModel(TranslateLanguage language) async {
    final code = language.bcpCode;
    final exists = await _models
        .isModelDownloaded(code)
        .timeout(const Duration(seconds: 10));
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
    final guessed = _guessSourceCode(
      normalized,
      fallbackSourceCode: fallbackSourceCode,
      targetCode: targetCode,
    );
    // A single shared device-to-server fallback is used for all surfaces.
    return translate(
      text: normalized,
      sourceCode: guessed ?? '',
      targetCode: targetCode,
    );
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
