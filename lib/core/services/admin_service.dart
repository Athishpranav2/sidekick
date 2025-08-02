import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/post.dart';

class AdminService {
  static const List<String> adminEmails = [
    'admin@sidekick.com',
    'moderator@sidekick.com',
    // Add your admin emails here
    'your-email@gmail.com', // Replace with your actual email
  ];

  /// Check if current user is an admin
  static bool isCurrentUserAdmin() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return false;
    return adminEmails.contains(user!.email!.toLowerCase());
  }

  /// Get current user's admin level
  static Future<String> getCurrentUserAdminLevel() async {
    if (!isCurrentUserAdmin()) return 'user';

    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return 'user';

    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user!.uid)
          .get();

      if (adminDoc.exists) {
        return adminDoc.data()?['level'] ?? 'moderator';
      }
    } catch (e) {
      print('Error getting admin level: $e');
    }

    return 'moderator'; // Default admin level
  }

  /// Pin a post (admin only)
  static Future<void> pinPost(String postId, {String? reason}) async {
    if (!isCurrentUserAdmin()) throw Exception('Unauthorized');

    final user = FirebaseAuth.instance.currentUser!;

    await FirebaseFirestore.instance
        .collection('confessions')
        .doc(postId)
        .update({
          'isPinned': true,
          'pinnedBy': user.uid,
          'pinnedAt': FieldValue.serverTimestamp(),
          'pinnedReason': reason,
        });

    // Log admin action
    await _logAdminAction('pin_post', postId, reason);
  }

  /// Unpin a post (admin only)
  static Future<void> unpinPost(String postId) async {
    if (!isCurrentUserAdmin()) throw Exception('Unauthorized');

    await FirebaseFirestore.instance
        .collection('confessions')
        .doc(postId)
        .update({
          'isPinned': false,
          'pinnedBy': null,
          'pinnedAt': null,
          'pinnedReason': null,
        });

    await _logAdminAction('unpin_post', postId, null);
  }

  /// Hide a post (admin only)
  static Future<void> hidePost(String postId, String reason) async {
    if (!isCurrentUserAdmin()) throw Exception('Unauthorized');

    final user = FirebaseAuth.instance.currentUser!;

    await FirebaseFirestore.instance
        .collection('confessions')
        .doc(postId)
        .update({
          'isHidden': true,
          'status': 'hidden',
          'moderatorId': user.uid,
          'moderatedAt': FieldValue.serverTimestamp(),
          'moderationReason': reason,
        });

    await _logAdminAction('hide_post', postId, reason);
  }

  /// Unhide a post (admin only)
  static Future<void> unhidePost(String postId) async {
    if (!isCurrentUserAdmin()) throw Exception('Unauthorized');

    await FirebaseFirestore.instance
        .collection('confessions')
        .doc(postId)
        .update({
          'isHidden': false,
          'status': 'approved',
          'moderationReason': null,
        });

    await _logAdminAction('unhide_post', postId, null);
  }

  /// Promote a post (increase visibility)
  static Future<void> promotePost(String postId, {String? reason}) async {
    if (!isCurrentUserAdmin()) throw Exception('Unauthorized');

    final user = FirebaseAuth.instance.currentUser!;

    await FirebaseFirestore.instance
        .collection('confessions')
        .doc(postId)
        .update({
          'isPromoted': true,
          'promotedBy': user.uid,
          'promotedAt': FieldValue.serverTimestamp(),
          'promotedReason': reason,
          // Boost engagement score for promoted posts
          'engagementScore': FieldValue.increment(100),
        });

    await _logAdminAction('promote_post', postId, reason);
  }

  /// Remove promotion from a post
  static Future<void> unpromotePost(String postId) async {
    if (!isCurrentUserAdmin()) throw Exception('Unauthorized');

    await FirebaseFirestore.instance
        .collection('confessions')
        .doc(postId)
        .update({
          'isPromoted': false,
          'promotedBy': null,
          'promotedAt': null,
          'promotedReason': null,
        });

    await _logAdminAction('unpromote_post', postId, null);
  }

  /// Delete a post permanently (admin only)
  static Future<void> deletePost(String postId, String reason) async {
    if (!isCurrentUserAdmin()) throw Exception('Unauthorized');

    final user = FirebaseAuth.instance.currentUser!;

    // Move to deleted collection for audit trail
    final postDoc = await FirebaseFirestore.instance
        .collection('confessions')
        .doc(postId)
        .get();

    if (postDoc.exists) {
      final data = postDoc.data()!;
      data['deletedBy'] = user.uid;
      data['deletedAt'] = FieldValue.serverTimestamp();
      data['deletionReason'] = reason;

      // Store in deleted collection
      await FirebaseFirestore.instance
          .collection('deleted_posts')
          .doc(postId)
          .set(data);

      // Delete from main collection
      await FirebaseFirestore.instance
          .collection('confessions')
          .doc(postId)
          .delete();
    }

    await _logAdminAction('delete_post', postId, reason);
  }

  /// Report a post (any user can do this)
  static Future<void> reportPost(String postId, String reason) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Must be logged in to report');

    // Add to reports collection
    await FirebaseFirestore.instance.collection('reports').add({
      'postId': postId,
      'reportedBy': user.uid,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });

    // Increment report count on the post
    await FirebaseFirestore.instance
        .collection('confessions')
        .doc(postId)
        .update({'reportCount': FieldValue.increment(1)});
  }

  /// Get pending reports (admin only)
  static Future<List<Map<String, dynamic>>> getPendingReports() async {
    if (!isCurrentUserAdmin()) throw Exception('Unauthorized');

    final snapshot = await FirebaseFirestore.instance
        .collection('reports')
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Resolve a report (admin only)
  static Future<void> resolveReport(
    String reportId,
    String action, {
    String? notes,
  }) async {
    if (!isCurrentUserAdmin()) throw Exception('Unauthorized');

    final user = FirebaseAuth.instance.currentUser!;

    await FirebaseFirestore.instance
        .collection('reports')
        .doc(reportId)
        .update({
          'status': 'resolved',
          'resolvedBy': user.uid,
          'resolvedAt': FieldValue.serverTimestamp(),
          'action': action,
          'notes': notes,
        });
  }

  /// Get admin dashboard stats
  static Future<Map<String, dynamic>> getAdminStats() async {
    if (!isCurrentUserAdmin()) throw Exception('Unauthorized');

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final thisWeek = now.subtract(Duration(days: now.weekday - 1));

      // Get various stats
      final futures = await Future.wait([
        // Total posts
        FirebaseFirestore.instance.collection('confessions').count().get(),

        // Posts today
        FirebaseFirestore.instance
            .collection('confessions')
            .where('timestamp', isGreaterThan: Timestamp.fromDate(today))
            .count()
            .get(),

        // Pending reports
        FirebaseFirestore.instance
            .collection('reports')
            .where('status', isEqualTo: 'pending')
            .count()
            .get(),

        // Hidden posts
        FirebaseFirestore.instance
            .collection('confessions')
            .where('isHidden', isEqualTo: true)
            .count()
            .get(),

        // Pinned posts
        FirebaseFirestore.instance
            .collection('confessions')
            .where('isPinned', isEqualTo: true)
            .count()
            .get(),
      ]);

      return {
        'totalPosts': futures[0].count,
        'postsToday': futures[1].count,
        'pendingReports': futures[2].count,
        'hiddenPosts': futures[3].count,
        'pinnedPosts': futures[4].count,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to get admin stats: $e');
    }
  }

  /// Get recent admin actions log
  static Future<List<Map<String, dynamic>>> getAdminActionsLog({
    int limit = 50,
  }) async {
    if (!isCurrentUserAdmin()) throw Exception('Unauthorized');

    final snapshot = await FirebaseFirestore.instance
        .collection('admin_actions')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Set feed algorithm weights (admin only)
  static Future<void> setFeedAlgorithmWeights({
    double? likeWeight,
    double? commentWeight,
    double? shareWeight,
    double? viewWeight,
    double? timeDecayFactor,
  }) async {
    if (!isCurrentUserAdmin()) throw Exception('Unauthorized');

    final weights = <String, dynamic>{};
    if (likeWeight != null) weights['likeWeight'] = likeWeight;
    if (commentWeight != null) weights['commentWeight'] = commentWeight;
    if (shareWeight != null) weights['shareWeight'] = shareWeight;
    if (viewWeight != null) weights['viewWeight'] = viewWeight;
    if (timeDecayFactor != null) weights['timeDecayFactor'] = timeDecayFactor;

    weights['updatedAt'] = FieldValue.serverTimestamp();
    weights['updatedBy'] = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('admin_settings')
        .doc('feed_algorithm')
        .set(weights, SetOptions(merge: true));

    await _logAdminAction('update_algorithm_weights', null, weights.toString());
  }

  /// Private method to log admin actions
  static Future<void> _logAdminAction(
    String action,
    String? targetId,
    String? details,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('admin_actions').add({
        'action': action,
        'targetId': targetId,
        'details': details,
        'adminId': user.uid,
        'adminEmail': user.email,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging admin action: $e');
    }
  }
}
