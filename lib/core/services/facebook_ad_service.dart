import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:facebook_audience_network/facebook_audience_network.dart';

class FacebookAdService {
  // Facebook Audience Network Ad Unit IDs
  static String get bannerAdUnitId {
    if (kDebugMode) {
      return 'IMG_16_9_APP_INSTALL#996731452420973_996731452420973'; // Test banner
    } else {
      return 'IMG_16_9_APP_INSTALL#996731452420973_996731452420973'; // Your real banner
    }
  }

  static String get interstitialAdUnitId {
    if (kDebugMode) {
      return 'IMG_16_9_APP_INSTALL#996731452420973_996731452420973'; // Test interstitial
    } else {
      return 'IMG_16_9_APP_INSTALL#996731452420973_996731452420973'; // Your real interstitial
    }
  }

  static String get rewardedAdUnitId {
    if (kDebugMode) {
      return 'VID_HD_16_9_15S_APP_INSTALL#996731452420973_996731452420973'; // Test rewarded
    } else {
      return 'VID_HD_16_9_15S_APP_INSTALL#996731452420973_996731452420973'; // Your real rewarded
    }
  }

  // Initialize Facebook Audience Network
  static Future<void> initialize() async {
    await FacebookAudienceNetwork.init(
      testingId: kDebugMode ? "37b1da9d-b5c6-3862-a438-2b1e83e64074" : null,
    );
    debugPrint('Facebook Audience Network initialized');
  }

  // Create a banner ad
  static Widget createBannerAd() {
    return FacebookBannerAd(
      placementId: bannerAdUnitId,
      bannerSize: BannerSize.STANDARD,
      listener: (result, value) {
        debugPrint("Banner Ad: $result --> $value");
      },
    );
  }

  // Load interstitial ad
  static Future<bool> loadInterstitialAd() async {
    bool? isLoaded = await FacebookInterstitialAd.loadInterstitialAd(
      placementId: interstitialAdUnitId,
      listener: (result, value) {
        debugPrint("Interstitial Ad: $result --> $value");
      },
    );
    return isLoaded ?? false;
  }

  // Show interstitial ad
  static Future<bool> showInterstitialAd() async {
    bool? isShown = await FacebookInterstitialAd.showInterstitialAd();
    return isShown ?? false;
  }

  // Load rewarded ad
  static Future<bool> loadRewardedAd() async {
    bool? isLoaded = await FacebookRewardedVideoAd.loadRewardedVideoAd(
      placementId: rewardedAdUnitId,
      listener: (result, value) {
        debugPrint("Rewarded Ad: $result --> $value");
      },
    );
    return isLoaded ?? false;
  }

  // Show rewarded ad
  static Future<bool> showRewardedAd() async {
    bool? isShown = await FacebookRewardedVideoAd.showRewardedVideoAd();
    return isShown ?? false;
  }

  // Preload ads for better performance
  static Future<void> preloadAds() async {
    await loadInterstitialAd();
    await loadRewardedAd();
  }
}
