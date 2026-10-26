import 'dart:async';
import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class RoomRewardedAdService {
  RoomRewardedAdService();

  static const String _androidProductionId =
      String.fromEnvironment('ADMOB_REWARDED_ANDROID_ID');
  static const String _iosProductionId =
      String.fromEnvironment('ADMOB_REWARDED_IOS_ID');

  static const String _androidTestId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _iosTestId =
      'ca-app-pub-3940256099942544/1712485313';

  String? get _adUnitId {
    if (Platform.isAndroid) {
      return _androidProductionId.trim().isNotEmpty
          ? _androidProductionId.trim()
          : _androidTestId;
    }
    if (Platform.isIOS) {
      return _iosProductionId.trim().isNotEmpty
          ? _iosProductionId.trim()
          : _iosTestId;
    }
    return null;
  }

  bool get usesTestAd {
    if (Platform.isAndroid) return _androidProductionId.trim().isEmpty;
    if (Platform.isIOS) return _iosProductionId.trim().isEmpty;
    return false;
  }

  Future<bool> show() async {
    final adUnitId = _adUnitId;
    if (adUnitId == null) return false;

    final completer = Completer<bool>();

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          var earnedReward = false;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (shownAd) {
              shownAd.dispose();
              if (!completer.isCompleted) {
                completer.complete(earnedReward);
              }
            },
            onAdFailedToShowFullScreenContent: (shownAd, error) {
              shownAd.dispose();
              if (!completer.isCompleted) {
                completer.complete(false);
              }
            },
          );

          ad.show(
            onUserEarnedReward: (shownAd, reward) {
              earnedReward = true;
            },
          );
        },
        onAdFailedToLoad: (error) {
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      ),
    );

    return completer.future;
  }
}
