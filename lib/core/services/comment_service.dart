import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/comment.dart';

class CommentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get comments for a specific post
  static Stream<List<Comment>> getCommentsStream(String postId) {
    return _firestore
        .collection('confessions')
        .doc(postId)
        .snapshots()
        .map((docSnapshot) {
      if (!docSnapshot.exists) return <Comment>[];
      
      final data = docSnapshot.data()!;
      final commentsArray = data['comments'] as List<dynamic>? ?? [];
      
      return commentsArray.asMap().entries.map((entry) {
        final index = entry.key;
        final commentData = entry.value as Map<String, dynamic>;
        
        return Comment(
          id: index.toString(), // Use array index as ID
          content: commentData['text'] ?? commentData['content'] ?? '',
          username: commentData['username'] ?? '',
          isAnonymous: commentData['isAnonymous'] ?? false,
          timestamp: _formatTimestamp(commentData['timestamp']),
        );
      }).toList();
    });
  }

  // Add a new comment to a post
  static Future<bool> addComment({
    required String postId,
    required String content,
    required bool isAnonymous,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final commentData = {
        'text': content,
        'userId': user.uid,
        'username': isAnonymous ? null : (user.displayName ?? 'Anonymous'),
        'isAnonymous': isAnonymous,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Add comment to the comments array
      await _firestore.collection('confessions').doc(postId).update({
        'comments': FieldValue.arrayUnion([commentData]),
      });

      return true;
    } catch (e) {
      print('Error adding comment: $e');
      return false;
    }
  }

  // Delete a comment (if user owns it)
  static Future<bool> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Get the document to find the comment to delete
      final docSnapshot = await _firestore
          .collection('confessions')
          .doc(postId)
          .get();

      if (!docSnapshot.exists) return false;

      final data = docSnapshot.data()!;
      final commentsArray = List<Map<String, dynamic>>.from(data['comments'] ?? []);
      
      // Find comment by index (commentId is the array index)
      final commentIndex = int.tryParse(commentId);
      if (commentIndex == null || commentIndex >= commentsArray.length) return false;
      
      final commentToDelete = commentsArray[commentIndex];
      
      // Check if user owns the comment
      if (commentToDelete['userId'] != user.uid) return false;

      // Remove the comment from array
      commentsArray.removeAt(commentIndex);

      // Update the document with the modified array
      await _firestore.collection('confessions').doc(postId).update({
        'comments': commentsArray,
      });

      return true;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }

  // Format timestamp for display
  static String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'now';
    
    if (timestamp is Timestamp) {
      final now = DateTime.now();
      final commentTime = timestamp.toDate();
      final difference = now.difference(commentTime);

      if (difference.inMinutes < 1) {
        return 'now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h';
      } else {
        return '${difference.inDays}d';
      }
    }
    
    return 'now';
  }

  // Get comment count for a post
  static Future<int> getCommentCount(String postId) async {
    try {
      final docSnapshot = await _firestore
          .collection('confessions')
          .doc(postId)
          .get();
      
      if (!docSnapshot.exists) return 0;
      
      final data = docSnapshot.data()!;
      final commentsArray = data['comments'] as List<dynamic>? ?? [];
      return commentsArray.length;
    } catch (e) {
      print('Error getting comment count: $e');
      return 0;
    }
  }
}
