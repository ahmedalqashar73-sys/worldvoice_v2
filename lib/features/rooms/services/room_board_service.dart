import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomBoardService {
  RoomBoardService({required this.roomId});

  final String roomId;
  final List<Map<String, dynamic>> _redoStrokes = [];
  bool get canRedo => _redoStrokes.isNotEmpty;
  String? get currentUserId => _user?.uid;

  Future<void> undoStroke({String scope = 'board'}) async {
    final uid = currentUserId;
    if (uid == null) return;
    final snapshot = await _items.orderBy('createdAt').get();
    final own = snapshot.docs.where((doc) =>
        doc.data()['userId'] == uid && doc.data()['type'] == 'stroke' && (doc.data()['scope'] ?? 'board') == scope);
    if (own.isEmpty) return;
    final last = own.last;
    await last.reference.delete();
    _redoStrokes.add(last.data());
  }

  Future<void> redoStroke({String scope = 'board'}) async {
    if (_redoStrokes.isEmpty) return;
    final data = _redoStrokes.last;
    if ((data['scope'] ?? 'board') != scope) { _redoStrokes.clear(); return; }
    await _items.add({...data, 'createdAt': FieldValue.serverTimestamp()});
    _redoStrokes.removeLast();
  }


  FirebaseFirestore get _db => FirebaseFirestore.instance;
  User? get _user => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>> get _room =>
      _db.collection('rooms').doc(roomId);

  CollectionReference<Map<String, dynamic>> get _items =>
      _room.collection('board_items');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchItems() {
    return _items.orderBy('createdAt').snapshots();
  }

  Future<void> addText(String text, {String scope = 'board', int color = 0xFFFFFFFF}) async {
    final user = _user;
    final value = text.trim();
    if (user == null || value.isEmpty) return;
    await _items.add({
      'type': 'text',
      'text': value,
      'scope': scope,
      'color': color,
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
    final item = _items.doc();
    await _db.runTransaction((transaction) async {
      final room = await transaction.get(_room);
      final data = room.data() ?? {};
      if (data['hostId'] != user.uid) throw StateError('Only the host can present media.');
      if (data['screenShareActive'] == true || data['boardMediaId'] != null) {
        throw StateError('Stop the current presentation first.');
      }
      transaction.set(item, {'type': type, 'url': url, 'name': name,
        'userId': user.uid, 'createdAt': FieldValue.serverTimestamp()});
      transaction.update(_room, {'boardMediaId': item.id});
    });
  }

  Future<void> stopMedia() => _room.update({'boardMediaId': FieldValue.delete()});

  Future<void> addStroke({
    required List<Map<String, double>> points,
    required int colorValue,
    required double width,
    String scope = 'board',
  }) async {
    final user = _user;
    if (user == null || points.length < 2) return;
    await _items.add({
      'type': 'stroke',
      'scope': scope,
      'points': points,
      'color': colorValue,
      'width': width,
      'userId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _redoStrokes.clear();
  }

  Future<void> clear({String scope = 'board'}) async {
    final snapshot = await _items.get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if ((data['type'] == 'stroke' || data['type'] == 'text') && (data['scope'] ?? 'board') == scope) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();
    _redoStrokes.clear();
  }
}
