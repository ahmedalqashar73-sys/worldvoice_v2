import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../profile/presentation/vip_membership_screen.dart';
import 'room_rewarded_ad_service.dart';

/// The live room entitlement must be read from the authenticated Firestore
/// profile, never from an arbitrary flag passed by the room participant.
abstract final class VipRoomFeatures {
  static bool activeVip(Map<String, dynamic>? profile, DateTime now) {
    if (profile?['isVip'] != true) return false;
    final expiry = profile?['vipExpiresAt'];
    if (expiry is Timestamp && !expiry.toDate().isAfter(now)) return false;
    if (expiry is DateTime && !expiry.isAfter(now)) return false;
    return true;
  }

  /// null = could not verify entitlement. Never ask a possible VIP to
  /// watch a rewarded ad because of offline Firebase or permission errors.
  static Future<bool?> getMembership() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return null;
    try {
      final doc = await FirebaseFirestore.instance.collection('users')
          .doc(uid).get().timeout(const Duration(seconds: 4));
      if (!doc.exists) return null;
      return activeVip(doc.data(), DateTime.now());
    } catch (_) {
      return null;
    }
  }

  static bool _arabic(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar';

  /// VIP-only interactive Teacher AI. Server-side authorization also verifies
  /// this entitlement before using the external AI provider.
  static Future<bool> requireTeacherVip(BuildContext context) async {
    final member = await getMembership();
    if (!context.mounted) return false;
    if (member == true) return true;
    if (member == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_arabic(context)
            ? 'تعذر التحقق من العضوية. حاول بعد الاتصال بالإنترنت.'
            : 'Could not verify your membership. Try again online.'),
      ));
      return false;
    }
    final upgrade = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(_arabic(context) ? 'Teacher AI خاص بـ VIP'
            : 'Teacher AI is a VIP feature'),
        content: Text(_arabic(context)
            ? 'المحادثة الصوتية مع معلم الذكاء الاصطناعي داخل الروم متاحة لأعضاء VIP فقط.'
            : 'Voice conversations with the room AI teacher require VIP.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false),
              child: Text(_arabic(context) ? 'لاحقًا' : 'Not now')),
          FilledButton(onPressed: () => Navigator.pop(dialog, true),
              child: Text(_arabic(context) ? 'عرض VIP' : 'View VIP')),
        ],
      ),
    );
    if (upgrade == true && context.mounted) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const VipMembershipScreen()),
      );
    }
    return false;
  }

  /// Free users unlock subtitles and instant translation for the current
  /// room/Live session by completing ONE rewarded video. VIP is immediate.
  static Future<bool> unlockLanguageTools(
    BuildContext context, {
    required bool unlockedForSession,
    required RoomRewardedAdService rewardedAds,
  }) async {
    if (unlockedForSession) return true;
    final vip = await getMembership();
    if (!context.mounted) return false;
    if (vip == true) return true;
    if (vip == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_arabic(context)
          ? 'تعذر التحقق من اشتراكك. تأكد من الإنترنت وحاول مجددًا.'
          : 'Membership unavailable. Check your connection and retry.'),
      ));
      return false;
    }
    final watch = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(_arabic(context) ? 'الترجمة والسبتايتل'
            : 'Translation and subtitles'),
        content: Text(_arabic(context)
            ? 'شاهد إعلان مكافأة واحدًا لفتح الترجمة والسبتايتل خلال هذه الجلسة. مع VIP لا تحتاج لإعلانات.'
            : 'Watch one rewarded ad to unlock subtitles and translation for this session. VIP has ad-free access.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false),
              child: Text(_arabic(context) ? 'إلغاء' : 'Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialog, true),
              child: Text(_arabic(context) ? 'مشاهدة الإعلان' : 'Watch ad')),
        ],
      ),
    );
    if (watch != true || !context.mounted) return false;
    final earned = await rewardedAds.show();
    if (!context.mounted) return false;
    if (!earned) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_arabic(context)
            ? 'لم يكتمل إعلان المكافأة. لم يتم فتح الميزة.'
            : 'The rewarded ad was not completed. Access remains locked.'),
      ));
    }
    return earned;
  }
}
