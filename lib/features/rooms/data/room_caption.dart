import 'package:cloud_firestore/cloud_firestore.dart';

class RoomCaption {
  const RoomCaption({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.text,
    required this.languageCode,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String displayName;
  final String text;
  final String languageCode;
  final DateTime? createdAt;

  factory RoomCaption.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final rawCreatedAt = data['createdAt'];
    return RoomCaption(
      id: doc.id,
      userId: (data['userId'] ?? '').toString(),
      displayName: (data['displayName'] ?? 'WorldVoice user').toString(),
      text: (data['text'] ?? '').toString(),
      languageCode: (data['languageCode'] ?? 'en').toString().toLowerCase(),
      createdAt:
          rawCreatedAt is Timestamp ? rawCreatedAt.toDate() : null,
    );
  }
}
