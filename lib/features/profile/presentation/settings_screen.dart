import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/localization/app_strings.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/localization/supported_language.dart';
import '../../auth/services/auth_service.dart';
import '../../onboarding/presentation/language/language_selection_screen.dart';

const String _settingsBackend =
    String.fromEnvironment('WORLDVOICE_ECONOMY_ENDPOINT');

Future<void> _setMessageApprovalRequired(bool value) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw StateError('Sign in first.');
  final root = Uri.tryParse(_settingsBackend.trim());
  if (root == null ||
      root.scheme != 'https' ||
      !root.hasAuthority ||
      root.userInfo.isNotEmpty) {
    throw StateError('WorldVoice backend is not configured.');
  }
  final token = await user.getIdToken(true);
  if (token == null || token.isEmpty) {
    throw StateError('Could not authenticate your privacy setting.');
  }
  final basePath = root.path.endsWith('/')
      ? root.path.substring(0, root.path.length - 1)
      : root.path;
  final response = await http.post(
    root.replace(path: '$basePath/chat/privacy'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'messageApprovalRequired': value}),
  );
  Map<String, dynamic> body = <String, dynamic>{};
  try {
    final raw = jsonDecode(response.body);
    if (raw is Map<String, dynamic>) body = raw;
  } catch (_) {}
  if (response.statusCode < 200 ||
      response.statusCode >= 300 ||
      body['ok'] != true) {
    throw StateError(
      body['error']?.toString() ?? 'Could not update message privacy.',
    );
  }
}

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
                final messageApprovalRequired =
                    data['messageApprovalRequired'] == true;

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
                        secondary:
                            const Icon(Icons.shield_outlined),
                        title: Text(
                          code == 'ar'
                              ? 'الموافقة قبل الرسائل'
                              : 'Approve new messages',
                        ),
                        subtitle: Text(
                          code == 'ar'
                              ? 'إذا فعلتها، أي شخص جديد يرسل لك طلب أولًا، وما يقدر يراسلك إلا بعد موافقتك.'
                              : 'New people must send a request first. They can message you only after you approve.',
                        ),
                        value: messageApprovalRequired,
                        onChanged: (value) async {
                          try {
                            await _setMessageApprovalRequired(value);
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  error
                                      .toString()
                                      .replaceFirst('Bad state: ', ''),
                                ),
                              ),
                            );
                          }
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

