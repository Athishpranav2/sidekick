import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:applovin_max/applovin_max.dart';

class AppLovinAdService {
  // AppLovin MAX SDK Key
  static String get sdkKey {
    if (kDebugMode) {
      return 'YOUR_APPLOVIN_SDK_KEY'; // Test SDK key
    } else {
      return 'YOUR_APPLOVIN_SDK_KEY'; // Your real SDK key
    }
  }

  // AppLovin MAX Ad Unit IDs
  static String get bannerAdUnitId {
    if (kDebugMode) {
      return 'banner'; // Test banner
    } else {
      return 'YOUR_BANNER_AD_UNIT_ID'; // Your real banner
    }
  }

  static String get interstitialAdUnitId {
    if (kDebugMode) {
      return 'inter'; // Test interstitial
    } else {
      return 'YOUR_INTERSTITIAL_AD_UNIT_ID'; // Your real interstitial
    }
  }

  static String get rewardedAdUnitId {
    if (kDebugMode) {
      return 'rewarded'; // Test rewarded
    } else {
      return 'YOUR_REWARDED_AD_UNIT_ID'; // Your real rewarded
    }
  }

  // Initialize AppLovin MAX
  static Future<void> initialize() async {
    await AppLovinMAX.initialize(sdkKey);
    debugPrint('AppLovin MAX initialized');
  }

  // Create a banner ad
  static Widget createBannerAd() {
    return AppLovinMAX.createBanner(
      bannerAdUnitId,
      AppLovinAdViewPosition.bottomCenter,
    );
  }

  // Load interstitial ad
  static Future<bool> loadInterstitialAd() async {
    bool? isLoaded = await AppLovinMAX.isInterstitialReady(
      interstitialAdUnitId,
    );
    if (isLoaded != true) {
      await AppLovinMAX.loadInterstitial(interstitialAdUnitId);
    }
    return isLoaded ?? false;
  }

  // Show interstitial ad
  static Future<bool> showInterstitialAd() async {
    bool? isReady = await AppLovinMAX.isInterstitialReady(interstitialAdUnitId);
    if (isReady == true) {
      await AppLovinMAX.showInterstitial(interstitialAdUnitId);
      return true;
    }
    return false;
  }

  // Load rewarded ad
  static Future<bool> loadRewardedAd() async {
    bool? isLoaded = await AppLovinMAX.isRewardedAdReady(rewardedAdUnitId);
    if (isLoaded != true) {
      await AppLovinMAX.loadRewardedAd(rewardedAdUnitId);
    }
    return isLoaded ?? false;
  }

  // Show rewarded ad
  static Future<bool> showRewardedAd() async {
    bool? isReady = await AppLovinMAX.isRewardedAdReady(rewardedAdUnitId);
    if (isReady == true) {
      await AppLovinMAX.showRewardedAd(rewardedAdUnitId);
      return true;
    }
    return false;
  }

  // Preload ads for better performance
  static Future<void> preloadAds() async {
    await loadInterstitialAd();
    await loadRewardedAd();
  }
}
