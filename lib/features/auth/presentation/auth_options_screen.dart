import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_controller.dart';
import '../services/auth_service.dart';
import '../../profile/presentation/profile_setup_screen.dart';

enum AuthFlowMode { signIn, createAccount }

class AuthOptionsScreen extends StatefulWidget {
  const AuthOptionsScreen({required this.localeController, required this.mode, super.key});
  final LocaleController localeController;
  final AuthFlowMode mode;

  @override
  State<AuthOptionsScreen> createState() => _AuthOptionsScreenState();
}

class _AuthOptionsScreenState extends State<AuthOptionsScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;
  bool _busy = false;

  bool get _rtl => const {'ar', 'ur', 'fa'}.contains(widget.localeController.locale?.languageCode);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _message(String text, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? const Color(0xFF159B62) : null,
          content: Row(
            children: [
              if (success) ...[
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  text,
                  style: success
                      ? const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)
                      : null,
                ),
              ),
            ],
          ),
        ),
      );
  }

  void _openProfile() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => ProfileSetupScreen(localeController: widget.localeController)),
      (route) => false,
    );
  }

  Future<void> _google() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await AuthService.signInWithGoogle();
      _message(_rtl ? 'تم تسجيل الدخول بنجاح ✓' : 'Signed in successfully ✓', success: true);
      await Future<void>.delayed(const Duration(milliseconds: 450));
      _openProfile();
    } catch (e) {
      final canceled = e.toString().contains('canceled') ||
          e.toString().contains('Cancelled by user');
      if (!canceled) {
        _message(
          _rtl ? 'تعذر تسجيل الدخول عبر Google. حاول مرة أخرى.' : 'Google sign-in failed. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _emailAuth() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.length < 6) {
      _message(_rtl ? 'أدخل بريدًا صحيحًا وكلمة مرور من 6 أحرف على الأقل.' : 'Enter a valid email and a password of at least 6 characters.');
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (widget.mode == AuthFlowMode.createAccount) {
        await AuthService.createWithEmail(email: email, password: password);
      } else {
        await AuthService.signInWithEmail(email: email, password: password);
      }
      _message(_rtl ? 'تم تسجيل الدخول بنجاح ✓' : 'Signed in successfully ✓', success: true);
      await Future<void>.delayed(const Duration(milliseconds: 450));
      _openProfile();
    } catch (e) {
      _message(_rtl ? 'تعذرت المصادقة: $e' : 'Authentication failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _emailSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Directionality(
        textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 4, 24, MediaQuery.viewInsetsOf(sheetContext).bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: _rtl ? 'البريد الإلكتروني' : 'Email')),
            const SizedBox(height: 12),
            TextField(controller: _password, obscureText: _hidePassword, decoration: InputDecoration(labelText: _rtl ? 'كلمة المرور' : 'Password', suffixIcon: IconButton(onPressed: () => setState(() => _hidePassword = !_hidePassword), icon: Icon(_hidePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded)))),
            const SizedBox(height: 18),
            SizedBox(width: double.infinity, height: 54, child: FilledButton(
              onPressed: () async {
                Navigator.pop(sheetContext);
                await _emailAuth();
              },
              child: Text(widget.mode == AuthFlowMode.createAccount ? (_rtl ? 'إنشاء الحساب' : 'Create account') : (_rtl ? 'تسجيل الدخول' : 'Sign in')),
            )),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(widget.localeController.locale?.languageCode);
    final creating = widget.mode == AuthFlowMode.createAccount;
    return Directionality(
      textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            children: [
              Text(creating ? strings.createAccount : strings.signIn, style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text(creating ? strings.createAccountBody : strings.signInBody, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65))),
              const SizedBox(height: 36),
              _AuthButton(icon: Icons.g_mobiledata_rounded, label: strings.google, onPressed: _busy ? null : _google),
              const SizedBox(height: 12),
              _AuthButton(icon: Icons.apple_rounded, label: strings.apple, onPressed: () => _message(_rtl ? 'Apple Sign In سيكون متاحًا على iOS.' : 'Apple Sign In will be available on iOS.')),
              const SizedBox(height: 12),
              _AuthButton(icon: Icons.mail_outline_rounded, label: strings.email, onPressed: _busy ? null : _emailSheet),
              if (_busy) ...[const SizedBox(height: 24), const Center(child: CircularProgressIndicator())],
              const SizedBox(height: 32),
              Text(strings.legal, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({required this.icon, required this.label, required this.onPressed});
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

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
