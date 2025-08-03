import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CustomAdService {
  // Custom ad service that works without external dependencies
  static Future<void> initialize() async {
    debugPrint('Custom ad service initialized');
  }

  // Create a custom banner ad widget
  static Widget createBannerAd() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF007AFF), const Color(0xFF0056CC)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Background pattern
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            // Ad content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Premium Feature',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Unlock exclusive content',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'AD',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'Learn More',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Load interstitial ad (placeholder)
  static Future<bool> loadInterstitialAd() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  // Show interstitial ad (placeholder)
  static Future<bool> showInterstitialAd() async {
    debugPrint('Showing custom interstitial ad');
    return true;
  }

  // Load rewarded ad (placeholder)
  static Future<bool> loadRewardedAd() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  // Show rewarded ad (placeholder)
  static Future<bool> showRewardedAd() async {
    debugPrint('Showing custom rewarded ad');
    return true;
  }

  // Preload ads for better performance
  static Future<void> preloadAds() async {
    await loadInterstitialAd();
    await loadRewardedAd();
  }
}
