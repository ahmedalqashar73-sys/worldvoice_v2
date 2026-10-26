import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomHistoryService {
  RoomHistoryService();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  User? get _user => FirebaseAuth.instance.currentUser;

  Future<void> recordEnter({
    required String roomId,
    required String roomName,
    String? languageCode,
  }) async {
    final user = _user;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('room_history')
        .doc(roomId)
        .set(
      {
        'roomId': roomId,
        'roomName': roomName,
        'languageCode': languageCode,
        'lastEnteredAt': FieldValue.serverTimestamp(),
        'visitCount': FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> recordLeave(String roomId) async {
    final user = _user;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('room_history')
        .doc(roomId)
        .set(
      {
        'lastLeftAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchHistory() {
    final user = _user;
    if (user == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('room_history')
        .orderBy('lastEnteredAt', descending: true)
        .limit(100)
        .snapshots();
  }
}
