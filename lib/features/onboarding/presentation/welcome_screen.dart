import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_controller.dart';
import '../../auth/presentation/auth_options_screen.dart';
import 'language/language_selection_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({required this.localeController, super.key});
  final LocaleController localeController;

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
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LanguageSelectionScreen(
                            controller: localeController,
                            showBackButton: true,
                            closeOnSelect: true,
                          ),
                        ),
                      );
                    },
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
                      MaterialPageRoute(
                        builder: (_) => AuthOptionsScreen(
                          localeController: localeController,
                          mode: AuthFlowMode.createAccount,
                        ),
                      ),
                    ),
                    child: Text(strings.createAccount, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AuthOptionsScreen(
                          localeController: localeController,
                          mode: AuthFlowMode.signIn,
                        ),
                      ),
                    ),
                    child: Text(strings.signIn, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
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
