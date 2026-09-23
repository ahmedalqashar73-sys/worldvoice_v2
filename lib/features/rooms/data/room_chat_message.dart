import 'package:cloud_firestore/cloud_firestore.dart';

class RoomChatMessage {
  const RoomChatMessage({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.text,
    required this.createdAt,
    this.photoUrl,
  });

  final String id;
  final String userId;
  final String displayName;
  final String? photoUrl;
  final String text;
  final DateTime? createdAt;

  factory RoomChatMessage.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final rawCreatedAt = data['createdAt'];
    return RoomChatMessage(
      id: doc.id,
      userId: (data['userId'] ?? '').toString(),
      displayName: (data['displayName'] ?? 'WorldVoice user').toString(),
      photoUrl: data['photoUrl'] as String?,
      text: (data['text'] ?? '').toString(),
      createdAt: rawCreatedAt is Timestamp ? rawCreatedAt.toDate() : null,
    );
  }
}
