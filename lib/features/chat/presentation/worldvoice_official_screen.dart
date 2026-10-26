import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';
import '../services/worldvoice_notification_service.dart';

/// Single official inbox for every signed-in member. Publishing requires
/// server-verified admin permissions; no client can write announcements.
class WorldVoiceOfficialScreen extends StatefulWidget {
  const WorldVoiceOfficialScreen({
    super.key, required this.localeController,
  });
  final LocaleController localeController;

  @override
  State<WorldVoiceOfficialScreen> createState() =>
      _WorldVoiceOfficialScreenState();
}

class _WorldVoiceOfficialScreenState extends State<WorldVoiceOfficialScreen> {
  late final Future<Map<String, dynamic>> _publisher = _checkPublisher();

  Future<Map<String, dynamic>> _checkPublisher() async {
    try {
      return await WorldVoiceNotificationService.post(
        '/system/announcements/can-publish', <String, dynamic>{},
      );
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.localeController.locale?.languageCode ?? 'en';
    final ar = lang == 'ar';
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF0A9366),
            child: Icon(Icons.public_rounded, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Text('WorldVoice',
            style: TextStyle(fontWeight: FontWeight.bold))),
          const Icon(Icons.verified, color: Color(0xFF0CBA86), size: 18),
        ]),
      ),
      body: uid == null
          ? Center(child: Text(ar ? 'يجب تسجيل الدخول أولًا' : 'Sign in first'))
          : Column(children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('worldvoice_announcements')
                      .where('active', isEqualTo: true)
                      .orderBy('createdAt', descending: true)
                      .limit(100).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text(ar
                        ? 'تعذر تحميل التحديثات. تحقق من قواعد Firebase والفهرس.'
                        : 'Unable to load updates. Check Firestore rules and index.'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final announcements = snapshot.data!.docs;
                    if (announcements.isEmpty) {
                      return Center(child: Text(ar
                        ? 'ستصلك تحديثات التطبيق هنا.'
                        : 'Official app updates will appear here.'));
                    }
                    return ListView.builder(
                      reverse: false,
                      padding: const EdgeInsets.all(14),
                      itemCount: announcements.length,
                      itemBuilder: (context, i) {
                        final data = announcements[i].data();
                        final translations = data['translations'];
                        final localized = translations is Map
                          ? translations[lang] ?? translations['en']
                          : null;
                        final text = localized is Map ? localized :
                          const <String, dynamic>{};
                        final time = data['createdAt'];
                        final clock = time is Timestamp
                            ? TimeOfDay.fromDateTime(time.toDate()).format(context)
                            : '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 13),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: Card(
                                color: Theme.of(context)
                                  .colorScheme.surfaceContainerHighest,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(children: [
                                        const Icon(Icons.verified_rounded,
                                          color: Color(0xFF0CBA86), size: 16),
                                        const SizedBox(width: 5),
                                        const Expanded(child: Text('WorldVoice Official',
                                          style: TextStyle(fontWeight: FontWeight.bold))),
                                        Text(clock, style: Theme.of(context)
                                          .textTheme.labelSmall),
                                      ]),
                                      const SizedBox(height: 10),
                                      Text((text['title'] ?? '').toString(),
                                        style: Theme.of(context).textTheme.titleMedium
                                          ?.copyWith(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      SelectableText((text['body'] ?? '').toString()),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('users')
                    .doc(uid).snapshots(),
                builder: (context, snapshot) {
                  final optedIn = snapshot.data?.data()?['emailAnnouncementsOptIn'] == true;
                  return SwitchListTile.adaptive(
                    dense: true,
                    value: optedIn,
                    title: Text(ar ? 'استلام تحديثات WorldVoice بالإيميل'
                        : 'Email me WorldVoice updates'),
                    subtitle: Text(ar
                        ? 'اختياري. يمكنك إيقافه في أي وقت.'
                        : 'Optional. You can turn this off at any time.'),
                    onChanged: (value) async {
                      try {
                        await WorldVoiceNotificationService.post(
                          '/system/announcements/email/preference',
                          {'enabled': value},
                        );
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(error.toString())));
                      }
                    },
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _publisher,
                  builder: (context, snap) {
                    if (snap.data?['canPublish'] == true) {
                      return SizedBox(width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.campaign_outlined),
                          label: Text(ar ? 'إرسال تحديث لجميع المستخدمين'
                              : 'Publish update to all members'),
                          onPressed: () => showModalBottomSheet<void>(
                            context: context, isScrollControlled: true,
                            useSafeArea: true, showDragHandle: true,
                            builder: (_) => _OfficialComposer(
                              languageCode: lang,
                              emailConfigured: snap.data?['emailConfigured'] == true),
                          ),
                        ),
                      );
                    }
                    return Text(ar
                        ? 'حساب WorldVoice الرسمي لإعلانات التطبيق.'
                        : 'Official WorldVoice application announcements.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  },
                ),
              ),
            ]),
    );
  }
}

class _OfficialComposer extends StatefulWidget {
  const _OfficialComposer({required this.languageCode, required this.emailConfigured});
  final String languageCode;
  final bool emailConfigured;

  @override
  State<_OfficialComposer> createState() => _OfficialComposerState();
}

class _OfficialComposerState extends State<_OfficialComposer> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _sending = false;
  bool _sendEmail = false;
  String? _announcementId;
  int _emailSent = 0;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_sending || (_announcementId == null &&
        (_title.text.trim().isEmpty || _body.text.trim().isEmpty))) return;
    setState(() { _sending = true; _error = null; });
    try {
      if (_announcementId == null) {
        final result = await WorldVoiceNotificationService.post(
          '/system/announcements/publish', {
            'title': _title.text.trim(),
            'body': _body.text.trim(),
            'sourceLanguage': ['ar','en','es','fr','zh','ko']
                .contains(widget.languageCode) ? widget.languageCode : 'en',
            'sendEmail': _sendEmail && widget.emailConfigured,
          },
        );
        _announcementId = result['announcementId']?.toString();
      }
      if (_sendEmail && _announcementId != null) {
        // A network interruption does not republish the same announcement.
        // The backend holds the current cursor to resume email delivery.
        for (var batch = 0; batch < 120; batch++) {
          if (!mounted) return;
          final result = await WorldVoiceNotificationService.post(
            '/system/announcements/email/process', {
              'announcementId': _announcementId,
            },
          );
          _emailSent = (result['sent'] as num?)?.toInt() ?? _emailSent;
          if (mounted) setState(() {});
          if (result['complete'] == true) break;
          if (batch == 119) {
            throw StateError('Email batches paused. Tap again to resume.');
          }
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) setState(() => _error = _announcementId == null
        ? error.toString()
        : 'Announcement published. Email delivery can resume: $error');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.languageCode == 'ar';
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 8, 18,
        MediaQuery.viewInsetsOf(context).bottom + 18),
      child: SingleChildScrollView(child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(ar ? 'إعلان رسمي لجميع مستخدمي WorldVoice'
              : 'WorldVoice official announcement',
            style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(controller: _title,
            maxLength: 150, enabled: !_sending,
            decoration: InputDecoration(
              labelText: ar ? 'عنوان التحديث' : 'Announcement title')),
          const SizedBox(height: 10),
          TextField(controller: _body,
            maxLines: 5, minLines: 3, maxLength: 3000,
            enabled: !_sending,
            decoration: InputDecoration(
              labelText: ar ? 'نص الرسالة' : 'Announcement message',
              border: const OutlineInputBorder())),
          Text(ar
            ? 'سيترجم الخادم الإعلان إلى لغات التطبيق الست قبل نشره.'
            : 'The server translates into all six app languages before publishing.',
            style: Theme.of(context).textTheme.bodySmall),
          if (widget.emailConfigured)
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(ar ? 'إرسال نسخة إلى البريد الإلكتروني'
                : 'Also email subscribed members'),
              subtitle: Text(ar
                ? 'فقط للمستخدمين الموافقين على رسائل البريد.'
                : 'Only members who opted in to email updates.'),
              value: _sendEmail,
              onChanged: _sending || _announcementId != null ? null
                : (value) => setState(() => _sendEmail = value),
            ),
          if (_emailSent > 0)
            Text(ar ? 'تم إرسال $_emailSent رسالة بريد حتى الآن'
              : '$_emailSent emails submitted so far'),
          if (_error != null) Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: TextStyle(
              color: Theme.of(context).colorScheme.error))),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _sending ? null : _publish,
            icon: _sending
              ? const SizedBox(height: 16, width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.send_rounded),
            label: Text(_sending
              ? (ar ? 'جارٍ ترجمة وإرسال الإعلان'
                  : 'Translating and publishing...')
              : (ar ? 'ترجمة وإرسال للجميع' : 'Translate & publish')),
          ),
        ],
      )),
    );
  }
}
