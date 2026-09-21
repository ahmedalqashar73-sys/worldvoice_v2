import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_controller.dart';

enum AuthFlowMode { signIn, createAccount }

class AuthOptionsScreen extends StatefulWidget {
  const AuthOptionsScreen({
    required this.localeController,
    required this.mode,
    super.key,
  });

  final LocaleController localeController;
  final AuthFlowMode mode;

  @override
  State<AuthOptionsScreen> createState() => _AuthOptionsScreenState();
}

class _AuthOptionsScreenState extends State<AuthOptionsScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(widget.localeController.locale?.languageCode);
    final rtl = const {'ar', 'ur', 'fa'}.contains(widget.localeController.locale?.languageCode);
    final creating = widget.mode == AuthFlowMode.createAccount;

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            children: [
              Text(
                creating ? strings.createAccount : strings.signIn,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                creating ? strings.createAccountBody : strings.signInBody,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65),
                ),
              ),
              const SizedBox(height: 36),
              if (creating) ...[
                _AuthButton(icon: Icons.g_mobiledata_rounded, label: strings.google, onPressed: () => _pending(context, rtl)),
                const SizedBox(height: 12),
                _AuthButton(icon: Icons.apple_rounded, label: strings.apple, onPressed: () => _pending(context, rtl)),
                const SizedBox(height: 12),
                _AuthButton(icon: Icons.mail_outline_rounded, label: strings.email, onPressed: () => _pending(context, rtl)),
              ] else ...[
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    labelText: rtl ? 'البريد الإلكتروني' : 'Email',
                    prefixIcon: const Icon(Icons.mail_outline_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _password,
                  obscureText: _hidePassword,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: rtl ? 'كلمة المرور' : 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _hidePassword = !_hidePassword),
                      icon: Icon(_hidePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 58,
                  child: FilledButton(
                    onPressed: () => _pending(context, rtl),
                    child: Text(strings.signIn, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Text(strings.legal, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  void _pending(BuildContext context, bool rtl) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(rtl ? 'سنربط المصادقة الحقيقية بعد تثبيت الواجهات.' : 'Real authentication will be connected after the UI flow is finalized.')),
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({required this.icon, required this.label, required this.onPressed});
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
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
