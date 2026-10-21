import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Free students can open up to three distinct NEW lessons per local day.
/// Already-started lessons and completed reviews remain accessible.
/// Local persistence is suitable for testing; a tamper-resistant,
/// cross-device production quota requires server-side enforcement.
enum AcademyDailyAccess { newLesson, alreadyStarted, limitReached }

abstract final class AcademyDailyLessonQuota {
  static const maxNewLessonsPerDay = 3;
  static Future<void> _queue = Future<void>.value();

  static String dateToken(DateTime date) {
    final d = date.toLocal();
    return d.year.toString().padLeft(4, '0') +
        d.month.toString().padLeft(2, '0') +
        d.day.toString().padLeft(2, '0');
  }

  static String storageKey(String uid, DateTime at) =>
      'worldvoice.academy.free.daily.v2.' + uid + '.' + dateToken(at);

  static Future<List<String>> openedLessons(String uid, {DateTime? now}) async {
    if (uid.isEmpty) return const <String>[];
    final prefs = await SharedPreferences.getInstance();
    return List<String>.unmodifiable(
      prefs.getStringList(storageKey(uid, now ?? DateTime.now())) ??
          <String>[],
    );
  }

  /// Sequential admission prevents double-taps from exceeding the limit.
  static Future<AcademyDailyAccess> admit(
      String uid, String lessonId, {DateTime? now}) async {
    if (uid.isEmpty || lessonId.isEmpty) {
      throw ArgumentError('Account and lesson ID must be nonempty');
    }
    final previous = _queue;
    final completed = Completer<void>();
    _queue = completed.future;
    await previous;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = storageKey(uid, now ?? DateTime.now());
      final lessons = prefs.getStringList(key) ?? <String>[];
      if (lessons.contains(lessonId)) return AcademyDailyAccess.alreadyStarted;
      if (lessons.length >= maxNewLessonsPerDay) {
        return AcademyDailyAccess.limitReached;
      }
      if (!await prefs.setStringList(key, <String>[...lessons, lessonId])) {
        return AcademyDailyAccess.alreadyStarted;
      }
      return AcademyDailyAccess.newLesson;
    } finally {
      completed.complete();
    }
  }
}

/// One app-opening ad opportunity on the third, sixth, ninth cold start.
abstract final class AcademyAppOpenFrequency {
  static const launchesPerAd = 3;
  static String storageKey(String uid) =>
      'worldvoice.academy.free.app_open.v1.' + uid;

  static Future<bool> registerLaunch(String uid) async {
    if (uid.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final key = storageKey(uid);
    final next = ((prefs.getInt(key) ?? 0) + 1) % launchesPerAd;
    await prefs.setInt(key, next);
    return next == 0;
  }
}

/// Test IDs ONLY. Public release ad serving is disabled pending production
/// AdMob IDs, privacy disclosures, consent and AdMob approval.
abstract final class AcademyDemoAds {
  static DateTime? _lastFullscreenAd;
  static bool _showingFullscreen = false;

  static bool get enabled => !kReleaseMode && !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
       defaultTargetPlatform == TargetPlatform.iOS);

  static String? get _interstitialId => switch (defaultTargetPlatform) {
    TargetPlatform.android => 'ca-app-pub-3940256099942544/1033173712',
    TargetPlatform.iOS => 'ca-app-pub-3940256099942544/4411468910',
    _ => null,
  };

  static String? get _appOpenId => switch (defaultTargetPlatform) {
    TargetPlatform.android => 'ca-app-pub-3940256099942544/9257395921',
    TargetPlatform.iOS => 'ca-app-pub-3940256099942544/5575463023',
    _ => null,
  };

  /// Avoid back-to-back full-screen ads if a learner opens a lesson just
  /// after seeing an app-open ad or skips between lessons unusually quickly.
  static bool get _mayShow {
    if (_showingFullscreen) return false;
    final last = _lastFullscreenAd;
    return last == null ||
        DateTime.now().difference(last) >= const Duration(seconds: 60);
  }

  static Future<void> showLessonInterstitial() async {
    final unit = _interstitialId;
    if (!enabled || unit == null || !_mayShow) return;
    final ready = Completer<InterstitialAd?>();
    InterstitialAd.load(
      adUnitId: unit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (ready.isCompleted) {
            ad.dispose();
          } else {
            ready.complete(ad);
          }
        },
        onAdFailedToLoad: (error) {
          if (!ready.isCompleted) ready.complete(null);
          debugPrint('Academy interstitial unavailable: ' + error.toString());
        },
      ),
    );

    final ad = await ready.future.timeout(
      const Duration(seconds: 4), onTimeout: () => null);
    if (ad == null) return;
    if (!_mayShow) {
      ad.dispose();
      return;
    }

    final ended = Completer<void>();
    void done(InterstitialAd item) {
      item.dispose();
      _lastFullscreenAd = DateTime.now();
      _showingFullscreen = false;
      if (!ended.isCompleted) ended.complete();
    }
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: done,
      onAdFailedToShowFullScreenContent: (item, error) => done(item),
    );
    _showingFullscreen = true;
    try {
      await ad.show();
      await ended.future.timeout(const Duration(seconds: 60));
    } catch (error) {
      debugPrint('Academy interstitial skipped: ' + error.toString());
      done(ad);
    }
  }

  /// AppOpenAd must be shown over the launch loading screen, never as an
  /// interstitial on app startup or over content after loading completes.
  static Future<void> showStartupAppOpen() async {
    final unit = _appOpenId;
    if (!enabled || unit == null || !_mayShow) return;
    final ready = Completer<AppOpenAd?>();
    AppOpenAd.load(
      adUnitId: unit,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          if (ready.isCompleted) {
            ad.dispose();
          } else {
            ready.complete(ad);
          }
        },
        onAdFailedToLoad: (error) {
          if (!ready.isCompleted) ready.complete(null);
          debugPrint('Academy app-open unavailable: ' + error.toString());
        },
      ),
    );
    final ad = await ready.future.timeout(
      const Duration(seconds: 4), onTimeout: () => null);
    if (ad == null) return;
    if (!_mayShow) {
      ad.dispose();
      return;
    }

    final ended = Completer<void>();
    void done(AppOpenAd item) {
      item.dispose();
      _lastFullscreenAd = DateTime.now();
      _showingFullscreen = false;
      if (!ended.isCompleted) ended.complete();
    }
    ad.fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
      onAdDismissedFullScreenContent: done,
      onAdFailedToShowFullScreenContent: (item, error) => done(item),
    );
    _showingFullscreen = true;
    try {
      await ad.show();
      await ended.future.timeout(const Duration(seconds: 60));
    } catch (error) {
      debugPrint('Academy app-open skipped: ' + error.toString());
      done(ad);
    }
  }
}

/// Checks the same users/{uid}.isVip field as the existing home banner.
/// Offline / unknown entitlements fail open to avoid falsely blocking VIPs.
abstract final class AcademyLessonAdGate {
  static Future<bool> beforeLesson(
    BuildContext context, {
    required String? uid,
    required String lessonId,
    bool isReview = false,
  }) async {
    if (uid == null || uid.isEmpty || isReview) return true;
    try {
      final user = await FirebaseFirestore.instance
          .collection('users').doc(uid).get()
          .timeout(const Duration(seconds: 2));
      if (!user.exists || user.data()?['isVip'] == true) return true;

      final decision = await AcademyDailyLessonQuota.admit(uid, lessonId);
      if (decision == AcademyDailyAccess.limitReached) {
        if (context.mounted) {
          final ar = Localizations.localeOf(context).languageCode == 'ar';
          await showDialog<void>(
            context: context,
            builder: (dialog) => AlertDialog(
              title: Text(ar ? 'انتهت دروسك المجانية اليوم'
                  : 'Daily free lesson limit reached'),
              content: Text(ar
                  ? 'يمكنك دراسة ثلاثة دروس جديدة فقط في اليوم. '
                    'راجع الدروس المكتملة الآن، أو ارجع غدًا لدروس جديدة. '
                    'اشتراك VIP يفتح دروسًا غير محدودة وبدون إعلانات.'
                  : 'Free members can start three new lessons per day. '
                    'Review completed lessons or return tomorrow. '
                    'VIP offers unlimited ad-free lessons.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialog),
                  child: Text(ar ? 'حسنًا' : 'OK'),
                ),
              ],
            ),
          );
        }
        return false;
      }
      if (decision == AcademyDailyAccess.newLesson) {
        await AcademyDemoAds.showLessonInterstitial();
      }
    } catch (error) {
      debugPrint('Academy quota/ad skipped: ' + error.toString());
    }
    return true;
  }
}

/// One app-open opportunity on every third signed-in cold start; VIP exempt.
abstract final class AcademyAppLaunchAdGate {
  static Future<void> beforeHome({
    required String uid,
    required bool isVip,
  }) async {
    if (isVip || !AcademyDemoAds.enabled) return;
    try {
      if (await AcademyAppOpenFrequency.registerLaunch(uid)) {
        await AcademyDemoAds.showStartupAppOpen();
      }
    } catch (error) {
      debugPrint('Academy startup ad skipped: ' + error.toString());
    }
  }
}
