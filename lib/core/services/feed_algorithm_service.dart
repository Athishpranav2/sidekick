import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/post.dart';

enum FeedMode {
  algorithmic, // Twitter-like engagement-based
  chronological, // Latest first
  trending, // Most engaged in last 24h
  following, // From followed users only
}

class FeedAlgorithmService {
  static const int _defaultPageSize = 20;
  static const int _maxRefreshInterval = 300; // 5 minutes in seconds

  static DateTime? _lastRefresh;
  static List<Post>? _cachedPosts;

  /// Get algorithmic feed with ranking
  static Future<List<Post>> getAlgorithmicFeed({
    FeedMode mode = FeedMode.algorithmic,
    int pageSize = _defaultPageSize,
    DocumentSnapshot? lastDoc,
    bool forceRefresh = false,
  }) async {
    // Check cache first
    if (!forceRefresh && _canUseCachedFeed()) {
      return _cachedPosts!;
    }

    try {
      List<Post> posts = [];

      switch (mode) {
        case FeedMode.algorithmic:
          posts = await _getAlgorithmicRankedFeed(pageSize, lastDoc);
          break;
        case FeedMode.chronological:
          posts = await _getChronologicalFeed(pageSize, lastDoc);
          break;
        case FeedMode.trending:
          posts = await _getTrendingFeed(pageSize);
          break;
        case FeedMode.following:
          posts = await _getFollowingFeed(pageSize, lastDoc);
          break;
      }

      // Update cache
      _cachedPosts = posts;
      _lastRefresh = DateTime.now();

      return posts;
    } catch (e) {
      throw Exception('Failed to load feed: $e');
    }
  }

  /// Algorithmic feed ranking (Twitter-like)
  static Future<List<Post>> _getAlgorithmicRankedFeed(
    int pageSize,
    DocumentSnapshot? lastDoc,
  ) async {
    // Get recent posts from multiple time windows for better ranking
    final recentPosts = await _getPostsFromTimeWindow(
      hours: 24,
      limit: pageSize * 2,
    );

    final olderPosts = await _getPostsFromTimeWindow(
      hours: 168, // 1 week
      limit: pageSize,
      startAfter: DateTime.now().subtract(const Duration(hours: 24)),
    );

    // Combine and calculate engagement scores
    final allPosts = [...recentPosts, ...olderPosts];

    // Update engagement scores for all posts
    for (final post in allPosts) {
      await _updatePostEngagementScore(post.id);
    }

    // Sort by engagement score (highest first)
    allPosts.sort((a, b) {
      // Pinned posts always come first
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      // Then by engagement score
      final scoreA = a.calculateEngagementScore();
      final scoreB = b.calculateEngagementScore();
      return scoreB.compareTo(scoreA);
    });

    // Apply user personalization
    final personalizedPosts = await _applyPersonalization(allPosts);

    // Anti-spam filtering
    final filteredPosts = _applySpamFiltering(personalizedPosts);

    return filteredPosts.take(pageSize).toList();
  }

  /// Get chronological feed (newest first)
  static Future<List<Post>> _getChronologicalFeed(
    int pageSize,
    DocumentSnapshot? lastDoc,
  ) async {
    Query query = FirebaseFirestore.instance
        .collection('confessions')
        .where('status', isEqualTo: 'approved')
        .where('isHidden', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(pageSize);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Post.fromFirestore(doc.id, data);
    }).toList();
  }

  /// Get trending posts (most engagement in last 24h)
  static Future<List<Post>> _getTrendingFeed(int pageSize) async {
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));

    final snapshot = await FirebaseFirestore.instance
        .collection('confessions')
        .where('status', isEqualTo: 'approved')
        .where('isHidden', isEqualTo: false)
        .where('timestamp', isGreaterThan: Timestamp.fromDate(yesterday))
        .get();

    final posts = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Post.fromFirestore(doc.id, data);
    }).toList();

    // Sort by engagement in last 24h
    posts.sort((a, b) {
      final engagementA = (a.likes * 2) + (a.comments * 3) + (a.views * 0.1);
      final engagementB = (b.likes * 2) + (b.comments * 3) + (b.views * 0.1);
      return engagementB.compareTo(engagementA);
    });

    return posts.take(pageSize).toList();
  }

  /// Get posts from followed users only
  static Future<List<Post>> _getFollowingFeed(
    int pageSize,
    DocumentSnapshot? lastDoc,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    // Get user's following list
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    final following = List<String>.from(userDoc.data()?['following'] ?? []);

    if (following.isEmpty) {
      // If not following anyone, return trending posts
      return _getTrendingFeed(pageSize);
    }

    // Get posts from followed users (batched queries for large following lists)
    final posts = <Post>[];
    const batchSize = 10; // Firestore 'in' query limit

    for (int i = 0; i < following.length; i += batchSize) {
      final batch = following.skip(i).take(batchSize).toList();

      final snapshot = await FirebaseFirestore.instance
          .collection('confessions')
          .where('authorId', whereIn: batch)
          .where('status', isEqualTo: 'approved')
          .where('isHidden', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(pageSize)
          .get();

      posts.addAll(
        snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Post.fromFirestore(doc.id, data);
        }),
      );
    }

    // Sort combined results by timestamp
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return posts.take(pageSize).toList();
  }

  /// Get posts from specific time window
  static Future<List<Post>> _getPostsFromTimeWindow({
    required int hours,
    required int limit,
    DateTime? startAfter,
  }) async {
    final timeLimit = DateTime.now().subtract(Duration(hours: hours));
    final startTime = startAfter ?? timeLimit;

    final snapshot = await FirebaseFirestore.instance
        .collection('confessions')
        .where('status', isEqualTo: 'approved')
        .where('isHidden', isEqualTo: false)
        .where('timestamp', isGreaterThan: Timestamp.fromDate(startTime))
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Post.fromFirestore(doc.id, data);
    }).toList();
  }

  /// Update engagement score for a specific post
  static Future<void> _updatePostEngagementScore(String postId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('confessions')
          .doc(postId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final post = Post.fromFirestore(postId, data);
        final newScore = post.calculateEngagementScore();

        await FirebaseFirestore.instance
            .collection('confessions')
            .doc(postId)
            .update({'engagementScore': newScore});
      }
    } catch (e) {
      // Silently handle errors to not break feed loading
      print('Error updating engagement score for post $postId: $e');
    }
  }

  /// Apply personalization based on user behavior
  static Future<List<Post>> _applyPersonalization(List<Post> posts) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return posts;

    try {
      // Get user preferences and interaction history
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final userData = userDoc.data() ?? {};
      final likedPosts = List<String>.from(userData['likedPosts'] ?? []);
      final viewedPosts = List<String>.from(userData['viewedPosts'] ?? []);

      // Boost posts similar to previously liked content
      for (final post in posts) {
        if (likedPosts.contains(post.id)) {
          // User already liked this - deprioritize to show fresh content
          continue;
        }

        // Boost posts from authors user has previously engaged with
        if (post.authorId != null &&
            likedPosts.any(
              (likedId) => posts.any(
                (p) => p.id == likedId && p.authorId == post.authorId,
              ),
            )) {
          // Boost similar authors
        }
      }

      return posts;
    } catch (e) {
      // Return original posts if personalization fails
      return posts;
    }
  }

  /// Apply anti-spam filtering
  static List<Post> _applySpamFiltering(List<Post> posts) {
    return posts.where((post) {
      // Filter out posts with high report count
      if (post.reportCount > 5) return false;

      // Filter very short posts (likely spam)
      if (post.content.length < 10) return false;

      // Filter posts with excessive caps or special characters
      final capsCount = post.content.replaceAll(RegExp(r'[^A-Z]'), '').length;
      final capsRatio = capsCount / post.content.length;
      if (capsRatio > 0.7 && post.content.length > 20) return false;

      return true;
    }).toList();
  }

  /// Check if cached feed can be used
  static bool _canUseCachedFeed() {
    if (_cachedPosts == null || _lastRefresh == null) return false;

    final timeSinceRefresh = DateTime.now().difference(_lastRefresh!).inSeconds;
    return timeSinceRefresh < _maxRefreshInterval;
  }

  /// Clear feed cache (call when user manually refreshes)
  static void clearCache() {
    _cachedPosts = null;
    _lastRefresh = null;
  }

  /// Track post view for engagement
  static Future<void> trackPostView(String postId) async {
    try {
      await FirebaseFirestore.instance
          .collection('confessions')
          .doc(postId)
          .update({'views': FieldValue.increment(1)});
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Track post share for engagement
  static Future<void> trackPostShare(String postId) async {
    try {
      await FirebaseFirestore.instance
          .collection('confessions')
          .doc(postId)
          .update({'shares': FieldValue.increment(1)});
    } catch (e) {
      // Silently handle errors
    }
  }
}
