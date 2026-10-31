import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../chat/services/worldvoice_notification_service.dart';

import '../data/room_chat_message.dart';
import 'active_chat_bubble_service.dart';

class RoomChatService {
  RoomChatService({required this.roomId});

  final String roomId;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  User? get _user => FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>> get _messages =>
      _db.collection('rooms').doc(roomId).collection('messages');

  Stream<List<RoomChatMessage>> watchMessages() {
    return _messages
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(RoomChatMessage.fromDoc)
              .toList(growable: false),
        );
  }

  Future<void> send(String value) async {
    final user = _user;
    final text = value.trim();
    if (user == null || text.isEmpty) return;
    if (text.length > 500) {
      throw StateError('Message is too long.');
    }

    final profile =
        await _db.collection('users').doc(user.uid).get();
    final data = profile.data() ?? const <String, dynamic>{};
    final verifiedBubble = await ActiveChatBubbleService.fromProfile(
      firestore: _db, uid: user.uid, profile: data);

    final saved = await _messages.add({
      'userId': user.uid,
      'displayName':
          (data['displayName'] ?? user.displayName ?? 'WorldVoice user')
              .toString(),
      'photoUrl': data['photoUrl'],
      'text': text,
      'bubbleId': verifiedBubble,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Message delivery is complete before this optional push. Notification
    // errors must not cause the client to resend an already-saved message.
    unawaited(WorldVoiceNotificationService.post(
      '/system/room-message/notify',
      {'roomId': roomId, 'messageId': saved.id},
    ).catchError((Object error) {
      // The optional push may be unavailable while the backend deploys.
      return <String, dynamic>{'ok': false};
    }));
  }

  Future<void> delete(String messageId) =>
      _messages.doc(messageId).delete();
}
