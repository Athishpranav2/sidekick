import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/post.dart';

enum FeedMode { algorithmic, chronological, trending }

class FeedResponse {
  final List<Post> posts;
  final bool hasMore;
  final String? lastPostId;
  final String algorithm;

  const FeedResponse({
    required this.posts,
    required this.hasMore,
    this.lastPostId,
    required this.algorithm,
  });
}

class CloudFeedService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Get feed from cloud function with proper error handling
  static Future<FeedResponse> getFeed({
    FeedMode mode = FeedMode.algorithmic,
    int pageSize = 20,
    String? lastPostId,
    bool forceRefresh = false,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      debugPrint('🌩️ Calling cloud function with mode: $mode');

      final callable = _functions.httpsCallable('getFeed');
      final result = await callable.call({
        'userId': user.uid,
        'mode': mode.name,
        'pageSize': pageSize,
        'lastPostId': lastPostId,
        'forceRefresh': forceRefresh,
      });

      final data = result.data as Map<String, dynamic>;
      final postsData = data['posts'] as List<dynamic>;

      debugPrint('✅ Cloud function returned ${postsData.length} posts');

      // FIXED: Convert cloud function response to Post objects with proper timestamp handling
      final posts = postsData.map((postData) {
        // Handle the type casting more safely
        final postMap = Map<String, dynamic>.from(postData as Map);

        // FIXED: Handle timestamp correctly - expect milliseconds from cloud function
        DateTime timestamp;
        final timestampValue = postMap['timestamp'];
        if (timestampValue is int) {
          // Cloud function sends milliseconds as int
          timestamp = DateTime.fromMillisecondsSinceEpoch(timestampValue);
        } else if (timestampValue is double) {
          // Handle double milliseconds
          timestamp = DateTime.fromMillisecondsSinceEpoch(
            timestampValue.toInt(),
          );
        } else {
          // Fallback to current time
          timestamp = DateTime.now();
          debugPrint(
            '⚠️ Invalid timestamp format: $timestampValue, using current time',
          );
        }

        // Handle likes array
        final likesData = postMap['likes'];
        int likesCount = 0;
        if (likesData is List) {
          likesCount = likesData.length;
        } else if (likesData is int) {
          likesCount = likesData;
        }

        // Handle comments array
        final commentsData = postMap['comments'];
        int commentsCount = 0;
        if (commentsData is List) {
          commentsCount = commentsData.length;
        } else if (commentsData is int) {
          commentsCount = commentsData;
        }

        return Post(
          id: postMap['id'] ?? '',
          content: postMap['text'] ?? '',
          isAnonymous: postMap['isAnonymous'] ?? true,
          username: postMap['username'],
          gender: postMap['gender'],
          timestamp: _formatTimestamp(timestamp),
          likes: likesCount,
          comments: commentsCount,
          cardColor: _getRandomCardColor(),
        );
      }).toList();

      return FeedResponse(
        posts: posts,
        hasMore: data['hasMore'] ?? false,
        lastPostId: data['lastPostId'],
        algorithm: data['algorithm'] ?? 'unknown',
      );
    } catch (e) {
      debugPrint('❌ Cloud function error: $e');

      // Fallback to direct Firestore query if cloud function fails
      debugPrint('🔄 Falling back to direct Firestore query...');
      return _getFallbackFeed(mode, pageSize, lastPostId);
    }
  }

  /// Fallback method using direct Firestore queries
  static Future<FeedResponse> _getFallbackFeed(
    FeedMode mode,
    int pageSize,
    String? lastPostId,
  ) async {
    try {
      final db = FirebaseFirestore.instance;

      Query query = db
          .collection('confessions')
          .orderBy('timestamp', descending: true)
          .limit(pageSize * 3); // Get more to filter client-side

      final snapshot = await query.get();
      debugPrint(
        '📱 Fallback query returned ${snapshot.docs.length} raw posts',
      );

      // Filter client-side to avoid composite index issues
      final posts = snapshot.docs
          .map((doc) {
            final data = Map<String, dynamic>.from(doc.data() as Map);

            // Client-side filtering
            final isApproved =
                data['status'] == 'approved' || data['status'] == null;
            final isVisible = data['isHidden'] != true;

            if (!isApproved || !isVisible) return null;

            // Handle timestamp properly for fallback
            final timestamp =
                (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

            // Handle likes
            final likesData = data['likes'];
            int likesCount = 0;
            if (likesData is List) {
              likesCount = likesData.length;
            } else if (likesData is int) {
              likesCount = likesData;
            }

            // Handle comments
            final commentsData = data['comments'];
            int commentsCount = 0;
            if (commentsData is List) {
              commentsCount = commentsData.length;
            } else if (commentsData is int) {
              commentsCount = commentsData;
            }

            return Post(
              id: doc.id,
              content: data['text'] ?? '',
              isAnonymous: data['isAnonymous'] ?? true,
              username: data['username'],
              gender: data['gender'],
              timestamp: _formatTimestamp(timestamp),
              likes: likesCount,
              comments: commentsCount,
              cardColor: _getRandomCardColor(),
            );
          })
          .where((post) => post != null)
          .cast<Post>()
          .take(pageSize)
          .toList();

      debugPrint('📱 Fallback filtered to ${posts.length} approved posts');

      return FeedResponse(
        posts: posts,
        hasMore: posts.length >= pageSize,
        lastPostId: posts.isNotEmpty ? posts.last.id : null,
        algorithm: 'fallback-firestore',
      );
    } catch (e) {
      debugPrint('❌ Fallback query also failed: $e');
      return const FeedResponse(posts: [], hasMore: false, algorithm: 'error');
    }
  }

  /// Format timestamp for display
  static String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// Get random card color for posts
  static Color _getRandomCardColor() {
    final cardColors = [
      const Color(0xFFF5F5DC), // Beige
      const Color(0xFFFFFACD), // Light yellow
      const Color(0xFFE6E6E6), // Muted gray
      const Color(0xFFFFF0F5), // Light pink
      const Color(0xFFF0F8FF), // Light blue
    ];
    return cardColors[DateTime.now().millisecond % cardColors.length];
  }
}
