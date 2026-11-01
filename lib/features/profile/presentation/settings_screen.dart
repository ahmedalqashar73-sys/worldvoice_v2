import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/worldvoice_appearance.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/localization/supported_language.dart';
import '../../auth/services/auth_service.dart';
import 'vip_membership_screen.dart';
import 'message_settings_screen.dart';
import '../../onboarding/presentation/language/language_selection_screen.dart';

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
        title: Text(AppStrings.of(code).profile('settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.language_rounded),
              title: Text(
                AppStrings.of(code).profile('appLanguage'),
              ),
              subtitle: Text(_currentLanguageName(localeController)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
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
            ),
          ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: WorldVoiceAppearance.instance.mode,
            builder: (context, selected, _) => Card(
              child: ListTile(
                key: const ValueKey('worldvoice-app-appearance'),
                leading: Icon(selected == ThemeMode.dark
                    ? Icons.dark_mode_rounded
                    : Icons.brightness_6_rounded),
                title: Text(code == 'ar' ? 'مظهر WorldVoice' : 'WorldVoice appearance'),
                subtitle: Text(switch (selected) {
                  ThemeMode.dark => code == 'ar' ? 'داكن' : 'Dark',
                  ThemeMode.light => code == 'ar' ? 'فاتح' : 'Light',
                  ThemeMode.system => code == 'ar' ? 'حسب الجهاز' : 'System',
                }),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  final selection = await showModalBottomSheet<ThemeMode>(
                    context: context, showDragHandle: true,
                    builder: (sheetContext) => SafeArea(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        for (final mode in ThemeMode.values)
                          ListTile(
                            leading: Icon(
                              mode == selected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: mode == selected
                                  ? Theme.of(sheetContext).colorScheme.primary
                                  : null,
                            ),
                            title: Text(switch (mode) {
                              ThemeMode.dark => code == 'ar' ? 'داكن' : 'Dark',
                              ThemeMode.light => code == 'ar' ? 'فاتح' : 'Light',
                              ThemeMode.system => code == 'ar'
                                  ? 'حسب إعدادات الجهاز' : 'Follow device',
                            }),
                            onTap: () => Navigator.pop(sheetContext, mode),
                          ),
                      ]),
                    ),
                  );
                  if (selection != null) {
                    await WorldVoiceAppearance.instance.setMode(selection);
                  }
                },
              ),
            ),
          ),
          Card(
            child: ListTile(
              key: const ValueKey('settings-vip-store'),
              leading: const Icon(Icons.workspace_premium_rounded,
                  color: Color(0xFFB38C31)),
              title: Text(code == 'ar' ? 'متجر VIP والاشتراك'
                  : 'VIP membership and store'),
              subtitle: Text(code == 'ar'
                  ? 'المميزات، حالة العضوية، والاشتراك الشهري'
                  : 'Benefits, membership status and monthly subscription'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const VipMembershipScreen(),
                ),
              ),
            ),
          ),
          Card(
            child: ListTile(
              key: const ValueKey('settings-message-settings-entry'),
              leading: const Icon(Icons.chat_bubble_outline_rounded),
              title: Text(code == 'ar' ? 'إعدادات الرسائل' : 'Message settings'),
              subtitle: Text(code == 'ar'
                  ? 'منع الرسائل، الحالة، الإشعارات، والأرشيف'
                  : 'Message privacy, online status, notifications and archive'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MessageSettingsScreen(
                    localeController: localeController),
                ),
              ),
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
                final hideCity = data['hideCity'] == true;

                return Column(
                  children: [
                    Card(
                      child: SwitchListTile(
                        secondary: const Icon(Icons.location_off_outlined),
                        title: Text(
                          AppStrings.of(code).profile('hideCity'),
                        ),
                        subtitle: Text(
                          AppStrings.of(code).profile('hideCityDescription'),
                        ),
                        value: hideCity,
                        onChanged: (value) {
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .set({
                            'hideCity': value,
                          }, SetOptions(merge: true));
                        },
                      ),
                    ),
                    Card(
                  child: SwitchListTile(
                    secondary: const Icon(Icons.visibility_off_outlined),
                    title: Text(
                      AppStrings.of(code).profile('hideProfileVisits'),
                    ),
                    subtitle: Text(
                      isVip
                          ? AppStrings.of(code).profile('hideProfileVisitsDescription')
                          : AppStrings.of(code).profile('vipFeature'),
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
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: Text(
                AppStrings.of(code).profile('logOut'),
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
          AppStrings.of(code).profile('logOutQuestion'),
        ),
        content: Text(
          AppStrings.of(code).profile('logOutDescription'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppStrings.of(code).profile('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(AppStrings.of(code).profile('logOut')),
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

String _currentLanguageName(LocaleController controller) {
  final code = controller.locale?.languageCode ?? 'en';
  for (final language in SupportedLanguages.all) {
    if (language.code == code) return language.nativeName;
  }
  return 'English';
}

