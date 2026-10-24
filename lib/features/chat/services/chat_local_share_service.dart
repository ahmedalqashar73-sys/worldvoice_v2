import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'local_chat_store.dart';

/// Cross-feature text shares join the same local encrypted queue as direct DMs.
/// A successful return means committed to THIS device, not delivered/read.
abstract final class WorldVoiceLocalShareService {
  static Future<void> queue({
    required String chatId,
    required String text,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to share.');
    final normalized = text.trim();
    if (normalized.isEmpty) return;
    if (normalized.length > 12000) {
      throw StateError('Share text is too long.');
    }

    // Preserve the existing server-authoritative membership checks.
    final chat = await FirebaseFirestore.instance
        .collection('chats').doc(chatId).get();
    final members = (chat.data()?['memberIds'] as List?)
            ?.map((member) => member.toString()).toList() ?? <String>[];
    if (!chat.exists || chat.data()?['active'] != true ||
        chat.data()?['type'] == 'group' ||
        members.length != 2 || !members.contains(uid)) {
      throw StateError('This direct conversation is not available.');
    }

    final store = LocalChatStore.of(uid, chatId);
    await store.upsert({
      'id': LocalChatStore.newId(),
      'senderId': uid,
      'type': 'text',
      'text': normalized,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'edited': false,
      'withdrawn': false,
      'hidden': false,
      'delivered': false,
      'read': false,
    });
    // The foreground WebRTC conversation flushes the stored outbox on open.
    // Never send the actual text to a Firestore/Render/Cloudinary API here.
  }
}
