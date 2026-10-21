import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// All CEFR courses (English and Spanish) share one ad cadence per account.
/// A lesson "visit" means tapping a lesson card, never opening a subsection
/// such as Grammar, Vocabulary, Story or Podcast.
abstract final class AcademyAdFrequency {
  static const visitsPerAd = 3;

  static String storageKey(String uid) =>
      'worldvoice.academy.free.lessons_since_ad.v1.$uid';

  /// True once every three lesson openings; returns false otherwise.
  /// Counter changes are stored locally and have no effect on user progress.
  static Future<bool> countFreeLessonVisit(String uid) async {
    if (uid.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final key = storageKey(uid);
    final next = ((prefs.getInt(key) ?? 0) + 1) % visitsPerAd;
    await prefs.setInt(key, next);
    return next == 0;
  }
}

/// Non-blocking freemium ad gate before lesson navigation.
///
/// - VIP users are always exempt (uses the same Firestore users.isVip
///   flag as the existing free-home banner).
/// - Guest accounts, failed VIP checks and ad-load failures continue without ads.
/// - All ads are Google TEST interstitials in debug/profile builds.
/// - Release builds intentionally show NO ads until production AdMob IDs,
///   a production manifest app ID, platform consent and account approvals
///   are configured; do not publish Google's test IDs as live monetization.
abstract final class AcademyLessonAdGate {
  static bool get _supportedDevice => !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
       defaultTargetPlatform == TargetPlatform.iOS);

  static String? get _testAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-3940256099942544/1033173712';
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    }
    return null;
  }

  static Future<void> beforeLesson({required String? uid}) async {
    // No delays for production learners until real AdMob identifiers,
    // consent and publishing approvals are configured.
    if (kReleaseMode || !_supportedDevice || uid == null || uid.isEmpty) return;
    try {
      // Never risk advertising to a VIP due to an unavailable Firestore read.
      // Skip on timeout/offline; the lesson must remain accessible.
      final user = await FirebaseFirestore.instance
          .collection('users').doc(uid).get()
          .timeout(const Duration(seconds: 2));
      if (!user.exists || user.data()?['isVip'] == true) return;

      if (!await AcademyAdFrequency.countFreeLessonVisit(uid)) return;

      // Existing Android/iOS manifest uses a Google DEMO app ID.
      // A real AdMob app ID, production unit IDs and consent are prerequisites
      // to enabling ads in public release builds.
      final unitId = _testAdUnitId;
      if (unitId == null) return;
      await _showGoogleTestInterstitial(unitId);
    } catch (error) {
      debugPrint('Academy lesson ad skipped: $error');
    }
  }

  static Future<void> _showGoogleTestInterstitial(String unitId) async {
    final loaded = Completer<InterstitialAd?>();
    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (loaded.isCompleted) {
            ad.dispose();
          } else {
            loaded.complete(ad);
          }
        },
        onAdFailedToLoad: (error) {
          if (!loaded.isCompleted) loaded.complete(null);
          debugPrint('Academy test interstitial unavailable: $error');
        },
      ),
    );

    final ad = await loaded.future.timeout(
      const Duration(seconds: 4), onTimeout: () => null);
    if (ad == null) return;

    final dismissed = Completer<void>();
    void done(InterstitialAd instance) {
      instance.dispose();
      if (!dismissed.isCompleted) dismissed.complete();
    }
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: done,
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Academy test interstitial failed to show: $error');
        done(ad);
      },
    );
    try {
      await ad.show();
      await dismissed.future.timeout(
        const Duration(seconds: 60), onTimeout: () => ad.dispose());
    } catch (error) {
      ad.dispose();
      debugPrint('Academy test interstitial cancelled: $error');
    }
  }
}
