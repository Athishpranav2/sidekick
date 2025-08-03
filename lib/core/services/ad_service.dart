import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/ad_model.dart';

class AdService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get active ads for the feed
  static Future<List<AdModel>> getActiveAds({
    int limit = 10,
    String? category,
  }) async {
    try {
      Query query = _firestore
          .collection('ads')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true);

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      final querySnapshot = await query.limit(limit).get();

      return querySnapshot.docs
          .map(
            (doc) => AdModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      print('Error fetching ads: $e');
      return [];
    }
  }

  // Get ads for specific positions in feed
  static Future<List<AdModel>> getAdsForFeedPositions({
    List<int> positions = const [3, 7, 12], // Show ads at these positions
    int limit = 5,
  }) async {
    try {
      final ads = await getActiveAds(limit: limit);

      // Return ads that should be shown at specific positions
      // This is a simple implementation - you can make it more sophisticated
      return ads.take(positions.length).toList();
    } catch (e) {
      print('Error fetching ads for feed positions: $e');
      return [];
    }
  }

  // Track ad impression
  static Future<void> trackAdImpression(String adId, String userId) async {
    try {
      await _firestore.collection('ad_impressions').add({
        'adId': adId,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'impression',
      });
    } catch (e) {
      print('Error tracking ad impression: $e');
    }
  }

  // Track ad click
  static Future<void> trackAdClick(String adId, String userId) async {
    try {
      await _firestore.collection('ad_clicks').add({
        'adId': adId,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'click',
      });
    } catch (e) {
      print('Error tracking ad click: $e');
    }
  }

  // Create a new ad (admin function)
  static Future<void> createAd(AdModel ad) async {
    try {
      await _firestore.collection('ads').add(ad.toFirestore());
    } catch (e) {
      print('Error creating ad: $e');
      rethrow;
    }
  }

  // Update an ad (admin function)
  static Future<void> updateAd(
    String adId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection('ads').doc(adId).update(updates);
    } catch (e) {
      print('Error updating ad: $e');
      rethrow;
    }
  }

  // Delete an ad (admin function)
  static Future<void> deleteAd(String adId) async {
    try {
      await _firestore.collection('ads').doc(adId).delete();
    } catch (e) {
      print('Error deleting ad: $e');
      rethrow;
    }
  }
}
