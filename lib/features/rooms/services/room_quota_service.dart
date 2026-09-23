import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomQuotaStatus {
  const RoomQuotaStatus({
    required this.allowed,
    required this.usedSeconds,
    required this.limitSeconds,
    required this.adsWatched,
    required this.adBonusSeconds,
    this.isUnlimited = false,
  });

  final bool allowed;
  final int usedSeconds;
  final int limitSeconds;
  final int adsWatched;
  final int adBonusSeconds;
  final bool isUnlimited;

  int get remainingSeconds =>
      isUnlimited ? 1 << 30 : (limitSeconds - usedSeconds).clamp(0, limitSeconds);
}

class RoomQuotaService {
  RoomQuotaService();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  User? get _user => FirebaseAuth.instance.currentUser;

  DateTime? _sessionStartedAt;
  bool _sessionIsHost = false;
  int _sessionRoomLevel = 1;

  String get _dayKey {
    final now = DateTime.now().toUtc();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  DocumentReference<Map<String, dynamic>>? get _usageRef {
    final user = _user;
    if (user == null) return null;
    return _db
        .collection('users')
        .doc(user.uid)
        .collection('room_usage')
        .doc(_dayKey);
  }

  Future<RoomQuotaStatus> check({
    required bool asHost,
    required int roomLevel,
  }) async {
    final user = _user;
    final ref = _usageRef;
    if (user == null || ref == null) {
      return const RoomQuotaStatus(
        allowed: false,
        usedSeconds: 0,
        limitSeconds: 0,
        adsWatched: 0,
        adBonusSeconds: 0,
      );
    }

    final profile =
        await _db.collection('users').doc(user.uid).get();
    final isVip = profile.data()?['isVip'] == true;

    if (isVip) {
      return const RoomQuotaStatus(
        allowed: true,
        usedSeconds: 0,
        limitSeconds: 0,
        adsWatched: 0,
        adBonusSeconds: 0,
        isUnlimited: true,
      );
    }

    final snap = await ref.get();
    final data = snap.data() ?? const <String, dynamic>{};
    final used = (data['usedSeconds'] as num?)?.toInt() ?? 0;
    final adsWatched = (data['adsWatched'] as num?)?.toInt() ?? 0;
    final adBonus = (data['adBonusSeconds'] as num?)?.toInt() ?? 0;

    final base = asHost
        ? (4 * 60 * 60) + ((roomLevel - 1).clamp(0, 999) * 15 * 60)
        : 2 * 60 * 60;
    final limit = base + (asHost ? 0 : adBonus.clamp(0, 3 * 60 * 60));

    return RoomQuotaStatus(
      allowed: used < limit,
      usedSeconds: used,
      limitSeconds: limit,
      adsWatched: adsWatched,
      adBonusSeconds: adBonus,
    );
  }

  Future<RoomQuotaStatus> startSession({
    required bool asHost,
    required int roomLevel,
  }) async {
    final status = await check(
      asHost: asHost,
      roomLevel: roomLevel,
    );

    if (status.allowed) {
      _sessionStartedAt = DateTime.now();
      _sessionIsHost = asHost;
      _sessionRoomLevel = roomLevel;
    }

    return status;
  }

  Future<void> endSession() async {
    final ref = _usageRef;
    final startedAt = _sessionStartedAt;
    if (ref == null || startedAt == null) return;

    final elapsed = DateTime.now().difference(startedAt).inSeconds;
    _sessionStartedAt = null;

    if (elapsed <= 0) return;

    await ref.set(
      {
        'usedSeconds': FieldValue.increment(elapsed),
        'lastSessionWasHost': _sessionIsHost,
        'lastRoomLevel': _sessionRoomLevel,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<RoomQuotaStatus> recordRewardedAdWatched() async {
    final ref = _usageRef;
    if (ref == null) {
      return const RoomQuotaStatus(
        allowed: false,
        usedSeconds: 0,
        limitSeconds: 0,
        adsWatched: 0,
        adBonusSeconds: 0,
      );
    }

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? const <String, dynamic>{};
      final currentAds = (data['adsWatched'] as num?)?.toInt() ?? 0;
      final nextAds = (currentAds + 1).clamp(0, 3);
      final bonus = nextAds >= 3 ? 3 * 60 * 60 : 0;

      tx.set(
        ref,
        {
          'adsWatched': nextAds,
          'adBonusSeconds': bonus,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    return check(asHost: false, roomLevel: 1);
  }
}
