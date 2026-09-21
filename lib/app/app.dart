import 'package:flutter/material.dart';

import '../core/localization/locale_controller.dart';
import '../core/localization/supported_language.dart';
import '../core/theme/app_theme.dart';
import '../features/onboarding/presentation/language/language_selection_screen.dart';

class WorldVoiceApp extends StatefulWidget {
  const WorldVoiceApp({super.key});

  @override
  State<WorldVoiceApp> createState() => _WorldVoiceAppState();
}

class _WorldVoiceAppState extends State<WorldVoiceApp> {
  final LocaleController _localeController = LocaleController();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _localeController.addListener(_refresh);
    _load();
  }

  Future<void> _load() async {
    await _localeController.load();
    if (mounted) setState(() => _ready = true);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _localeController.removeListener(_refresh);
    _localeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WorldVoice',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      locale: _localeController.locale,
      supportedLocales: SupportedLanguages.locales,
      home: !_ready
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : LanguageSelectionScreen(controller: _localeController),
    );
  }
}
