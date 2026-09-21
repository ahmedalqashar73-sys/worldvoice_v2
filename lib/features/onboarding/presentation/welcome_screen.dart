import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/localization/supported_language.dart';
import '../../auth/presentation/sign_in_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({required this.localeController, super.key});
  final LocaleController localeController;

  Future<void> _languages(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Language', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              ),
              ...SupportedLanguages.all.map((language) => ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text(language.nativeName, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: language.nativeName == language.englishName ? null : Text(language.englishName),
                    trailing: localeController.locale?.languageCode == language.code
                        ? Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () async {
                      await localeController.select(language.code);
                      if (context.mounted) Navigator.pop(context);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(localeController.locale?.languageCode);
    final rtl = const {'ar','ur','fa'}.contains(localeController.locale?.languageCode);
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 26),
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: IconButton.filledTonal(
                    onPressed: () => _languages(context),
                    icon: const Icon(Icons.language_rounded),
                    tooltip: strings.language,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(Icons.public_rounded, size: 52, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 26),
                Text('WorldVoice', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Text(
                  strings.tagline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .68),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  strings.welcomeBody,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: FilledButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SignInScreen(localeController: localeController)),
                    ),
                    child: Text(strings.getStarted, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
