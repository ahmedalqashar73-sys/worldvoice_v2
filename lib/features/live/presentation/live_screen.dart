import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';
import '../../rooms/presentation/unified_gift_panel.dart';

/// Server-approved broadcasts only; never show fake viewers or sell gifts for
/// a stream that has no verified Agora media session.
class LiveScreen extends StatelessWidget {
  const LiveScreen({required this.localeController, super.key});
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final code = localeController.locale?.languageCode ?? 'en';
    final rtl = const {'ar', 'ur', 'fa'}.contains(code);
    final ar = code == 'ar';
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('live_sessions')
            .where('status', isEqualTo: 'broadcasting').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(ar
                ? 'البث غير متاح حاليًا' : 'Live sessions unavailable'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final sessions = snapshot.data!.docs;
          return ListView(padding: const EdgeInsets.all(16), children: [
            Text(ar ? 'البث المباشر' : 'Live',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(ar
              ? 'لا يبدأ البث المدفوع قبل التحقق من اتصال الصوت والفيديو.'
              : 'Live gifts require a verified broadcasting session.'),
            const SizedBox(height: 16),
            if (sessions.isEmpty)
              Card(child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  const Icon(Icons.live_tv_rounded, size: 46),
                  const SizedBox(height: 8),
                  Text(ar
                    ? 'لا توجد بثوث موثّقة الآن. نكمل ربط الفيديو.'
                    : 'No verified live broadcasts yet. Video integration is pending.',
                    textAlign: TextAlign.center),
                ]),
              )),
            for (final session in sessions)
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.live_tv_rounded)),
                title: Text(session.data()['title']?.toString() ??
                    (ar ? 'بث مباشر' : 'Live broadcast')),
                subtitle: Text(session.data()['hostName']?.toString() ??
                    (ar ? 'المضيف' : 'Host')),
                onTap: () => Navigator.push(context, MaterialPageRoute<void>(
                  builder: (_) => _VerifiedLiveSession(
                    id: session.id,
                    title: session.data()['title']?.toString() ??
                        'Live',
                    hostId: session.data()['hostId']?.toString() ?? '',
                  ),
                )),
              ),
          ]);
        },
      ),
    );
  }
}

class _VerifiedLiveSession extends StatelessWidget {
  const _VerifiedLiveSession({
    required this.id, required this.title, required this.hostId,
  });
  final String id;
  final String title;
  final String hostId;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(child: Column(children: [
        const Expanded(child: Center(child:
          Icon(Icons.videocam_off_outlined, size: 54))),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(ar
            ? 'مشغل الفيديو المباشر لم يُربط بعد. لا يمكن إرسال هدايا مدفوعة حتى يكتمل.'
            : 'The live video player is not linked yet. Paid gifts remain locked.',
            textAlign: TextAlign.center),
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('live_sessions')
            .doc(id).collection('gifts')
            .orderBy('createdAt', descending: true).limit(3).snapshots(),
          builder: (context, snapshot) => SizedBox(
            height: 55,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final event in snapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Chip(
                      avatar: const Icon(Icons.card_giftcard_rounded, size: 18),
                      label: Text('${event.data()['senderName'] ?? 'Guest'}: '
                        '${event.data()['giftId'] ?? 'Gift'}'),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 305,
          child: UnifiedGiftPanel(
            contextType: 'live', contextId: id,
            recipients: hostId.isEmpty ? const {} : {hostId: title},
          ),
        ),
      ])),
    );
  }
}
