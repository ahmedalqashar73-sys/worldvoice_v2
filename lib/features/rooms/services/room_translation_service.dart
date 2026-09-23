import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class RoomTranslationService {
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

  Future<void> dispose() async {
    for (final translator in _translators.values) {
      await translator.close();
    }
    _translators.clear();
  }
}
