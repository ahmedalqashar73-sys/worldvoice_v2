import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'supported_language.dart';

class LocaleController extends ChangeNotifier {
  static const _localeKey = 'app_locale_code';
  static const _chosenKey = 'app_locale_chosen';

  Locale? _locale;
  bool _hasChosenLanguage = false;

  Locale? get locale => _locale;
  bool get hasChosenLanguage => _hasChosenLanguage;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_localeKey);
    _hasChosenLanguage = prefs.getBool(_chosenKey) ?? false;

    if (saved != null && SupportedLanguages.all.any((e) => e.code == saved)) {
      _locale = Locale(saved);
    } else {
      final device = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      _locale = Locale(SupportedLanguages.resolveCode(device));
    }
    notifyListeners();
  }

  Future<void> select(String code) async {
    if (!SupportedLanguages.all.any((e) => e.code == code)) return;
    _locale = Locale(code);
    _hasChosenLanguage = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, code);
    await prefs.setBool(_chosenKey, true);
  }
}
