import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/localization/locale_controller.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../rooms/data/room_backend_config.dart';
import '../services/user_presence_service.dart';

/// One place for real chat privacy, presence, notifications and archiving.
class MessageSettingsScreen extends StatelessWidget {
  const MessageSettingsScreen({required this.localeController, super.key});

  final LocaleController localeController;

  Future<void> _updateSetting(
      BuildContext context, String uid, Map<String, Object> fields) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid)
          .update(fields);
      if (fields['showOnlineStatus'] == true) {
        await UserPresenceService.heartbeat();
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', ''))));
      }
    }
  }

  Future<void> _updateApproval(BuildContext context, bool value) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('Please sign in.');
      final base = Uri.parse(RoomBackendConfig.socialBaseUrl);
      final token = await user.getIdToken();
      final path = base.path.endsWith('/')
          ? base.path.substring(0, base.path.length - 1) : base.path;
      final result = await http.post(base.replace(path: '$path/chat/privacy'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'messageApprovalRequired': value}),
      ).timeout(RoomBackendConfig.socialRequestTimeout);
      final response = jsonDecode(result.body);
      if (result.statusCode < 200 || result.statusCode >= 300 ||
          response is! Map || response['ok'] != true) {
        throw StateError(response is Map
            ? (response['error'] ?? 'Could not update privacy.').toString()
            : 'Could not update privacy.');
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', ''))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final ar = (localeController.locale?.languageCode ??
        Localizations.localeOf(context).languageCode) == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(ar ? 'إعدادات الرسائل' : 'Message settings')),
      body: uid == null
        ? Center(child: Text(ar ? 'يرجى تسجيل الدخول' : 'Sign in first'))
        : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users')
                .doc(uid).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text(ar ? 'تعذر قراءة إعدادات الرسائل'
                    : 'Could not load message settings'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data?.data() ?? const <String, dynamic>{};
              final canReceive = data['receiveDirectMessages'] != false;
              final showPresence = data['showOnlineStatus'] != false;
              final notifications = data['chatNotificationsEnabled'] != false;
              final approval = data['messageApprovalRequired'] == true;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  Card(child: SwitchListTile(
                    key: const ValueKey('settings-block-incoming-messages'),
                    secondary: const Icon(Icons.mark_email_unread_outlined),
                    title: Text(ar ? 'منع استقبال الرسائل' : 'Block incoming messages'),
                    subtitle: Text(ar
                        ? 'يمنع وصول الرسائل الخاصة الجديدة، حتى من المحادثات الموجودة. لا يشمل رسائل المجموعات.'
                        : 'Stop new private messages, including existing chats. Group messages are unaffected.'),
                    value: !canReceive,
                    onChanged: (value) => _updateSetting(context, uid,
                      {'receiveDirectMessages': !value}),
                  )),
                  Card(child: SwitchListTile(
                    key: const ValueKey('settings-message-approval'),
                    secondary: const Icon(Icons.shield_outlined),
                    title: Text(ar ? 'الموافقة قبل الرسائل' : 'Approve new messages'),
                    subtitle: Text(ar
                        ? 'تحتاج المحادثات الخاصة الجديدة إلى موافقتك قبل البدء.'
                        : 'New private conversations must be approved first.'),
                    value: approval,
                    onChanged: !canReceive ? null :
                        (value) => _updateApproval(context, value),
                  )),
                  Card(child: SwitchListTile(
                    key: const ValueKey('settings-show-online-status'),
                    secondary: const Icon(Icons.circle_outlined),
                    title: Text(ar ? 'إظهار حالة الاتصال' : 'Show online status'),
                    subtitle: Text(ar
                        ? 'إظهار متصل الآن أو غير متصل بجانب اسمك في الرسائل.'
                        : 'Show your online or offline status beside your name in chats.'),
                    value: showPresence,
                    onChanged: (value) => _updateSetting(context, uid, {
                      'showOnlineStatus': value,
                      if (!value) 'isOnline': false,
                    }),
                  )),
                  Card(child: SwitchListTile(
                    key: const ValueKey('settings-mute-chat-notifications'),
                    secondary: const Icon(Icons.notifications_off_outlined),
                    title: Text(ar ? 'كتم إشعارات الرسائل' : 'Mute message notifications'),
                    subtitle: Text(ar
                        ? 'إيقاف إشعارات الرسائل الخاصة والمجموعات دون إيقاف استلام الرسائل.'
                        : 'Mute private and group message notifications without stopping delivery.'),
                    value: !notifications,
                    onChanged: (value) => _updateSetting(context, uid,
                      {'chatNotificationsEnabled': !value}),
                  )),
                  Card(child: ListTile(
                    key: const ValueKey('settings-chat-archive'),
                    leading: const Icon(Icons.archive_outlined),
                    title: Text(ar ? 'أرشيف المحادثات' : 'Archived conversations'),
                    subtitle: Text(ar
                        ? 'عرض المحادثات المؤرشفة وإلغاء أرشفتها. لا تُحذف الرسائل.'
                        : 'View or restore archived chats without deleting messages.'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => ChatScreen(
                        localeController: localeController,
                        showArchived: true,
                      )),
                    ),
                  )),
                ],
              );
            },
          ),
    );
  }
}
