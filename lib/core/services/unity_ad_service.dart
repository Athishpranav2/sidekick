import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:unity_ads/unity_ads.dart';

class UnityAdService {
  // Unity Ads Game ID
  static String get gameId {
    if (kDebugMode) {
      return '1234567'; // Test game ID
    } else {
      return 'YOUR_UNITY_GAME_ID'; // Your real game ID
    }
  }

  // Unity Ads Placement IDs
  static String get bannerAdUnitId {
    if (kDebugMode) {
      return 'Banner_Android'; // Test banner
    } else {
      return 'YOUR_BANNER_PLACEMENT_ID'; // Your real banner
    }
  }

  static String get interstitialAdUnitId {
    if (kDebugMode) {
      return 'Interstitial_Android'; // Test interstitial
    } else {
      return 'YOUR_INTERSTITIAL_PLACEMENT_ID'; // Your real interstitial
    }
  }

  static String get rewardedAdUnitId {
    if (kDebugMode) {
      return 'Rewarded_Android'; // Test rewarded
    } else {
      return 'YOUR_REWARDED_PLACEMENT_ID'; // Your real rewarded
    }
  }

  // Initialize Unity Ads
  static Future<void> initialize() async {
    await UnityAds.initialize(
      gameId,
      testMode: kDebugMode,
      enablePerPlacementLoad: true,
    );
    debugPrint('Unity Ads initialized');
  }

  // Create a banner ad widget
  static Widget createBannerAd() {
    return UnityBannerAd(
      placementId: bannerAdUnitId,
      onLoad: (placementId) {
        debugPrint('Unity Banner Ad loaded: $placementId');
      },
      onClick: (placementId) {
        debugPrint('Unity Banner Ad clicked: $placementId');
      },
      onError: (placementId, error, message) {
        debugPrint('Unity Banner Ad error: $error - $message');
      },
    );
  }

  // Load interstitial ad
  static Future<bool> loadInterstitialAd() async {
    try {
      await UnityAds.load(interstitialAdUnitId);
      return true;
    } catch (e) {
      debugPrint('Unity Interstitial load error: $e');
      return false;
    }
  }

  // Show interstitial ad
  static Future<bool> showInterstitialAd() async {
    try {
      bool isReady = await UnityAds.isReady(interstitialAdUnitId);
      if (isReady) {
        await UnityAds.show(interstitialAdUnitId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Unity Interstitial show error: $e');
      return false;
    }
  }

  // Load rewarded ad
  static Future<bool> loadRewardedAd() async {
    try {
      await UnityAds.load(rewardedAdUnitId);
      return true;
    } catch (e) {
      debugPrint('Unity Rewarded load error: $e');
      return false;
    }
  }

  // Show rewarded ad
  static Future<bool> showRewardedAd() async {
    try {
      bool isReady = await UnityAds.isReady(rewardedAdUnitId);
      if (isReady) {
        await UnityAds.show(rewardedAdUnitId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Unity Rewarded show error: $e');
      return false;
    }
  }

  // Preload ads for better performance
  static Future<void> preloadAds() async {
    await loadInterstitialAd();
    await loadRewardedAd();
  }
}
