import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';
import '../../onboarding/presentation/language/language_selection_screen.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({
    required this.localeController,
    super.key,
  });

  final LocaleController localeController;

  String _t(String code, String en, String ar, String es) {
    if (code == 'ar') return ar;
    if (code == 'es') return es;
    return en;
  }

  Future<void> _logout(BuildContext context, String code) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t(code, 'Log out', 'تسجيل الخروج', 'Cerrar sesión')),
        content: Text(
          _t(
            code,
            'Do you want to log out of WorldVoice?',
            'هل تريد تسجيل الخروج من WorldVoice؟',
            '¿Quieres cerrar sesión en WorldVoice?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_t(code, 'Cancel', 'إلغاء', 'Cancelar')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_t(code, 'Log out', 'تسجيل الخروج', 'Cerrar sesión')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final code = localeController.locale?.languageCode ?? 'en';
    final rtl = const {'ar', 'ur', 'fa'}.contains(code);

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_t(code, 'Settings', 'الإعدادات', 'Ajustes')),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.language_rounded),
                title: Text(_t(code, 'App language', 'لغة التطبيق', 'Idioma de la app')),
                subtitle: Text(
                  _t(
                    code,
                    'Change the language used by WorldVoice',
                    'غيّر لغة واجهة WorldVoice',
                    'Cambia el idioma de WorldVoice',
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LanguageSelectionScreen(
                        controller: localeController,
                        showBackButton: true,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (uid != null)
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data() ?? const <String, dynamic>{};
                  final isVip = data['isVip'] == true;
                  final hideVisitLog = data['hideVisitLog'] == true;

                  return Card(
                    child: SwitchListTile(
                      secondary: const Icon(Icons.visibility_off_outlined),
                      title: Text(
                        _t(code, 'Hide my profile visits', 'إخفاء زياراتي للبروفايلات', 'Ocultar mis visitas'),
                      ),
                      subtitle: Text(
                        isVip
                            ? _t(
                                code,
                                'Other users will not see that you visited them.',
                                'لن يرى الآخرون أنك زرت بروفايلهم.',
                                'Otros usuarios no verán que visitaste su perfil.',
                              )
                            : _t(
                                code,
                                'Available for VIP accounts.',
                                'متاح لحسابات VIP.',
                                'Disponible para cuentas VIP.',
                              ),
                      ),
                      value: isVip && hideVisitLog,
                      onChanged: !isVip
                          ? null
                          : (value) {
                              FirebaseFirestore.instance.collection('users').doc(uid).set(
                                {'hideVisitLog': value},
                                SetOptions(merge: true),
                              );
                            },
                    ),
                  );
                },
              ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.logout_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  _t(code, 'Log out', 'تسجيل الخروج', 'Cerrar sesión'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onTap: () => _logout(context, code),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
