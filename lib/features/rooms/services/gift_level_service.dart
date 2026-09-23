import 'package:cloud_firestore/cloud_firestore.dart';

class GiftLevelService {
  const GiftLevelService();

  Future<int> resolveFromProfile(
    Map<String, dynamic> profile,
  ) async {
    final fallback = (profile['giftLevel'] as num?)?.toInt() ?? 0;
    final points = (profile['giftLevelPoints'] as num?)?.toInt() ?? 0;

    final snapshot = await FirebaseFirestore.instance
        .collection('gift_level_thresholds')
        .get();

    if (snapshot.docs.isEmpty) return fallback;

    var resolved = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['active'] == false) continue;

      final level = (data['level'] as num?)?.toInt();
      final minPoints = (data['minPoints'] as num?)?.toInt();
      if (level == null || minPoints == null || level < 0 || minPoints < 0) {
        continue;
      }

      if (points >= minPoints && level > resolved) {
        resolved = level;
      }
    }

    return resolved;
  }
}
