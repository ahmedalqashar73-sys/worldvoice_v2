import 'package:flutter/material.dart';

class SupportedLanguage {
  const SupportedLanguage({
    required this.code,
    required this.nativeName,
    required this.englishName,
  });

  final String code;
  final String nativeName;
  final String englishName;

  Locale get locale => Locale(code);
}

abstract final class SupportedLanguages {
  static const all = <SupportedLanguage>[
    SupportedLanguage(code: 'ar', nativeName: 'العربية', englishName: 'Arabic'),
    SupportedLanguage(code: 'en', nativeName: 'English', englishName: 'English'),
    SupportedLanguage(code: 'es', nativeName: 'Español', englishName: 'Spanish'),
    SupportedLanguage(code: 'fr', nativeName: 'Français', englishName: 'French'),
    SupportedLanguage(code: 'zh', nativeName: '中文', englishName: 'Chinese'),
    SupportedLanguage(code: 'ko', nativeName: '한국어', englishName: 'Korean'),
    SupportedLanguage(code: 'ja', nativeName: '日本語', englishName: 'Japanese'),
    SupportedLanguage(code: 'ru', nativeName: 'Русский', englishName: 'Russian'),
    SupportedLanguage(code: 'tr', nativeName: 'Türkçe', englishName: 'Turkish'),
    SupportedLanguage(code: 'ur', nativeName: 'اردو', englishName: 'Urdu'),
    SupportedLanguage(code: 'de', nativeName: 'Deutsch', englishName: 'German'),
    SupportedLanguage(code: 'pt', nativeName: 'Português', englishName: 'Portuguese'),
    SupportedLanguage(code: 'fa', nativeName: 'فارسی', englishName: 'Persian'),
    SupportedLanguage(code: 'id', nativeName: 'Bahasa Indonesia', englishName: 'Indonesian'),
    SupportedLanguage(code: 'th', nativeName: 'ไทย', englishName: 'Thai'),
    SupportedLanguage(code: 'hi', nativeName: 'हिन्दी', englishName: 'Hindi'),
    SupportedLanguage(code: 'it', nativeName: 'Italiano', englishName: 'Italian'),
  ];

  static List<Locale> get locales => all.map((e) => e.locale).toList(growable: false);

  static String resolveCode(String deviceCode) {
    return all.any((language) => language.code == deviceCode) ? deviceCode : 'en';
  }
}
