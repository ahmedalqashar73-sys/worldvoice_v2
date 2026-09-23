import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomBoardService {
  RoomBoardService({required this.roomId});

  final String roomId;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  User? get _user => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>> get _room =>
      _db.collection('rooms').doc(roomId);

  CollectionReference<Map<String, dynamic>> get _items =>
      _room.collection('board_items');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchItems() {
    return _items.orderBy('createdAt').snapshots();
  }

  Future<void> addText(String text) async {
    final user = _user;
    final value = text.trim();
    if (user == null || value.isEmpty) return;
    await _items.add({
      'type': 'text',
      'text': value,
      'userId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addMedia({
    required String type,
    required String url,
    required String name,
  }) async {
    final user = _user;
    if (user == null || url.isEmpty) return;
    await _items.add({
      'type': type,
      'url': url,
      'name': name,
      'userId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addStroke({
    required List<Map<String, double>> points,
    required int colorValue,
    required double width,
  }) async {
    final user = _user;
    if (user == null || points.length < 2) return;
    await _items.add({
      'type': 'stroke',
      'points': points,
      'color': colorValue,
      'width': width,
      'userId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> clear() async {
    final snapshot = await _items.get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
