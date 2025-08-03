import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  // Google AdMob App ID
  static String get appId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544~3347511713'; // Test app ID
    } else {
      return 'ca-app-pub-6993710937842311~68811194341'; // Your real app ID
    }
  }

  // Google AdMob Ad Unit IDs
  static String get bannerAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Test banner
    } else {
      return 'ca-app-pub-6993710937842311/7702471362'; // Your real banner
    }
  }

  static String get interstitialAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Test interstitial
    } else {
      return 'ca-app-pub-6993710937842311/YOUR_INTERSTITIAL_ID'; // Your real interstitial
    }
  }

  static String get rewardedAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Test rewarded
    } else {
      return 'ca-app-pub-6993710937842311/YOUR_REWARDED_ID'; // Your real rewarded
    }
  }

  // Initialize Google AdMob
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    debugPrint('Google AdMob initialized');
  }

  // Create a banner ad
  static BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner ad loaded successfully');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
        },
        onAdOpened: (ad) {
          debugPrint('Banner ad opened');
        },
        onAdClosed: (ad) {
          debugPrint('Banner ad closed');
        },
      ),
    );
  }

  // Load interstitial ad
  static Future<InterstitialAd?> loadInterstitialAd() async {
    try {
      InterstitialAd? interstitialAd;
      await InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            interstitialAd = ad;
            debugPrint('Interstitial ad loaded successfully');
          },
          onAdFailedToLoad: (error) {
            debugPrint('Interstitial ad failed to load: $error');
          },
        ),
      );
      return interstitialAd;
    } catch (e) {
      debugPrint('Interstitial ad error: $e');
      return null;
    }
  }

  // Show interstitial ad
  static Future<bool> showInterstitialAd(InterstitialAd? ad) async {
    if (ad != null) {
      await ad.show();
      return true;
    }
    return false;
  }

  // Load rewarded ad
  static Future<RewardedAd?> loadRewardedAd() async {
    try {
      RewardedAd? rewardedAd;
      await RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            rewardedAd = ad;
            debugPrint('Rewarded ad loaded successfully');
          },
          onAdFailedToLoad: (error) {
            debugPrint('Rewarded ad failed to load: $error');
          },
        ),
      );
      return rewardedAd;
    } catch (e) {
      debugPrint('Rewarded ad error: $e');
      return null;
    }
  }

  // Show rewarded ad
  static Future<bool> showRewardedAd(RewardedAd? ad) async {
    if (ad != null) {
      await ad.show(
        onUserEarnedReward: (_, reward) {
          debugPrint('User earned reward: ${reward.amount}');
        },
      );
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
