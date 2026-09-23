import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/room_caption.dart';

class RoomCaptionService {
  RoomCaptionService({required this.roomId});

  final String roomId;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  User? get _user => FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>> get _captions =>
      _db.collection('rooms').doc(roomId).collection('captions');

  Stream<List<RoomCaption>> watchLatest({int limit = 30}) {
    return _captions
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(RoomCaption.fromDoc)
              .where((caption) => caption.text.trim().isNotEmpty)
              .toList(growable: false),
        );
  }

  Future<void> publishFinal({
    required String displayName,
    required String text,
    required String languageCode,
  }) async {
    final user = _user;
    final normalized = text.trim();
    if (user == null || normalized.isEmpty) return;

    await _captions.add({
      'userId': user.uid,
      'displayName':
          displayName.trim().isEmpty ? 'WorldVoice user' : displayName.trim(),
      'text': normalized.length > 400
          ? normalized.substring(0, 400)
          : normalized,
      'languageCode':
          languageCode.trim().isEmpty ? 'en' : languageCode.toLowerCase(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
