import 'package:firebase_auth/firebase_auth.dart';
import '../../engagement/services/engagement_service.dart';

class GiftLevelService {
  const GiftLevelService();
  Future<int> resolveFromProfile(Map<String, dynamic> profile) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0;
    final data = await EngagementService.badge(uid);
    return ((data['giftLevel'] as num?)?.toInt() ?? 0).clamp(0, 50);
  }
}
