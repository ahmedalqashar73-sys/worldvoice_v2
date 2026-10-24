import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/chat_local_share_service.dart';

/// A single, safe cross-feature Share to Chat entry point.
/// Only existing one-to-one chats are supported by the encrypted local outbox.
abstract final class WorldVoiceShareToChatSheet {
  static Future<void> show(
    BuildContext context, {
    required String text,
    required String title,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    if (uid == null) return;
    String? sending;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheet) => StatefulBuilder(
        builder: (ctx, update) => SizedBox(
          height: MediaQuery.sizeOf(ctx).height * .64,
          child: Column(children: [
            ListTile(
              title: Text(title, style: const TextStyle(
                fontWeight: FontWeight.w900, fontSize: 18)),
              subtitle: Text(ar
                  ? 'تُحفظ المشاركة على جهازك، وتُسلّم عند اتصال الطرفين.'
                  : 'Saved on your device; delivered once both peers connect.'),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('chats')
                    .where('memberIds', arrayContains: uid)
                    .where('active', isEqualTo: true).snapshots(),
                builder: (ctx, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text(ar
                        ? 'تعذّر تحميل المحادثات حاليًا.'
                        : 'Conversations unavailable.'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data();
                    final members = (data['memberIds'] as List?)
                        ?.map((x) => x.toString()).toList() ?? <String>[];
                    return data['type'] != 'group' &&
                        members.length == 2 && members.contains(uid);
                  }).toList();
                  if (docs.isEmpty) {
                    return Center(child: Text(ar
                        ? 'ما عندك محادثات خاصة جاهزة للمشاركة.'
                        : 'No direct conversations available.'));
                  }
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (ctx, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final members = List<String>.from(data['memberIds']);
                      final peer = members.firstWhere((id) => id != uid);
                      final names = Map<String, dynamic>.from(
                        data['memberNames'] as Map? ?? <String, dynamic>{});
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text((names[peer] ?? 'WorldVoice').toString()),
                        trailing: sending == doc.id
                            ? const SizedBox.square(dimension: 20,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send_rounded),
                        onTap: sending != null ? null : () async {
                          update(() => sending = doc.id);
                          try {
                            await WorldVoiceLocalShareService.queue(
                                chatId: doc.id, text: text);
                            if (!sheet.mounted) return;
                            Navigator.of(sheet).pop();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(ar
                                  ? 'تم حفظ المشاركة لإرسالها من جهازك.'
                                  : 'Share saved on your device for delivery.')),
                            );
                          } catch (error) {
                            if (!ctx.mounted) return;
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(error.toString()
                                  .replaceFirst('Bad state: ', ''))),
                            );
                          } finally {
                            if (ctx.mounted) update(() => sending = null);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
