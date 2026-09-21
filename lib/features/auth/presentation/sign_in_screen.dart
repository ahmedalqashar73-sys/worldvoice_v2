import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_controller.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({required this.localeController, super.key});
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(localeController.locale?.languageCode);
    final rtl = const {'ar','ur','fa'}.contains(localeController.locale?.languageCode);
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(strings.signIn,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Text(
                  strings.signInBody,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65),
                  ),
                ),
                const SizedBox(height: 36),
                _AuthButton(
                  icon: Icons.g_mobiledata_rounded,
                  label: strings.google,
                  onPressed: () => _notConnected(context, rtl),
                ),
                const SizedBox(height: 12),
                _AuthButton(
                  icon: Icons.apple_rounded,
                  label: strings.apple,
                  onPressed: () => _notConnected(context, rtl),
                ),
                const SizedBox(height: 12),
                _AuthButton(
                  icon: Icons.mail_outline_rounded,
                  label: strings.email,
                  onPressed: () => _notConnected(context, rtl),
                ),
                const Spacer(),
                Text(
                  strings.legal,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _notConnected(BuildContext context, bool rtl) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(rtl ? 'سنربط تسجيل الدخول الآمن في الخطوة التالية.' : 'Secure authentication will be connected in the next step.')),
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({required this.icon, required this.label, required this.onPressed});
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 27),
        label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .12)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}
