import 'package:cloud_firestore/cloud_firestore.dart';

class RoomTeacherAiNote {
  const RoomTeacherAiNote({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.originalText,
    required this.correction,
    required this.languageCode,
    this.pronunciationTip,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String displayName;
  final String originalText;
  final String correction;
  final String languageCode;
  final String? pronunciationTip;
  final DateTime? createdAt;

  factory RoomTeacherAiNote.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final raw = data['createdAt'];
    return RoomTeacherAiNote(
      id: doc.id,
      userId: (data['userId'] ?? '').toString(),
      displayName: (data['displayName'] ?? 'WorldVoice user').toString(),
      originalText: (data['originalText'] ?? '').toString(),
      correction: (data['correction'] ?? '').toString(),
      languageCode: (data['languageCode'] ?? 'en').toString(),
      pronunciationTip: data['pronunciationTip']?.toString(),
      createdAt: raw is Timestamp ? raw.toDate() : null,
    );
  }
}
