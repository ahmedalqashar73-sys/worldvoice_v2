import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/localization/supported_language.dart';
import '../../auth/services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.localeController,
    super.key,
  });

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final code = localeController.locale?.languageCode ?? 'en';
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t(code, 'Settings', 'الإعدادات', 'Ajustes')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.language_rounded),
              title: Text(
                _t(code, 'App language', 'لغة التطبيق', 'Idioma de la app'),
              ),
              subtitle: Text(_currentLanguageName(localeController)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _LanguageSettingsScreen(
                      localeController: localeController,
                    ),
                  ),
                );
              },
            ),
          ),
          if (uid != null)
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final data =
                    snapshot.data?.data() ?? const <String, dynamic>{};
                final isVip = data['isVip'] == true;
                final hideVisits = data['hideVisitLog'] == true;

                return Card(
                  child: SwitchListTile(
                    secondary: const Icon(Icons.visibility_off_outlined),
                    title: Text(
                      _t(
                        code,
                        'Hide my profile visits',
                        'إخفاء زياراتي للبروفايلات',
                        'Ocultar mis visitas de perfil',
                      ),
                    ),
                    subtitle: Text(
                      isVip
                          ? _t(
                              code,
                              'When enabled, other people will not see that you visited them.',
                              'عند التفعيل لن يعرف الآخرون أنك زرت بروفايلهم.',
                              'Al activarlo, otros no verán que visitaste su perfil.',
                            )
                          : _t(
                              code,
                              'VIP feature',
                              'ميزة VIP',
                              'Función VIP',
                            ),
                    ),
                    value: isVip && hideVisits,
                    onChanged: isVip
                        ? (value) {
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .set({
                              'hideVisitLog': value,
                            }, SetOptions(merge: true));
                          }
                        : null,
                  ),
                );
              },
            ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: Text(
                _t(code, 'Log out', 'تسجيل الخروج', 'Cerrar sesión'),
              ),
              onTap: () => _confirmLogout(context, code),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, String code) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          _t(code, 'Log out?', 'تسجيل الخروج؟', '¿Cerrar sesión?'),
        ),
        content: Text(
          _t(
            code,
            'You can sign in again at any time.',
            'يمكنك تسجيل الدخول مرة أخرى في أي وقت.',
            'Puedes volver a iniciar sesión en cualquier momento.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_t(code, 'Cancel', 'إلغاء', 'Cancelar')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_t(code, 'Log out', 'خروج', 'Salir')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await AuthService.signOut();
    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _LanguageSettingsScreen extends StatelessWidget {
  const _LanguageSettingsScreen({
    required this.localeController,
  });

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final code = localeController.locale?.languageCode ?? 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _t(code, 'App language', 'لغة التطبيق', 'Idioma de la app'),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: SupportedLanguages.all.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final language = SupportedLanguages.all[index];
          final selected =
              language.code == localeController.locale?.languageCode;

          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            tileColor: selected
                ? Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: .55)
                : null,
            title: Text(
              language.nativeName,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: language.nativeName == language.englishName
                ? null
                : Text(language.englishName),
            trailing: selected
                ? Icon(
                    Icons.check_circle_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () async {
              await localeController.select(language.code);
              if (context.mounted) Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }
}

String _currentLanguageName(LocaleController controller) {
  final code = controller.locale?.languageCode ?? 'en';
  for (final language in SupportedLanguages.all) {
    if (language.code == code) return language.nativeName;
  }
  return 'English';
}

String _t(String code, String en, String ar, String es) {
  if (code == 'ar') return ar;
  if (code == 'es') return es;
  return en;
}
