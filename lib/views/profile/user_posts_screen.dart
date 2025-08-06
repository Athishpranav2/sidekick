import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../models/post.dart';
import '../sidetalk/post_card.dart';
import '../sidetalk/post_detail_screen.dart';

class UserPostsScreen extends StatefulWidget {
  final String userId;
  final String displayName;

  const UserPostsScreen({
    super.key,
    required this.userId,
    required this.displayName,
  });

  @override
  State<UserPostsScreen> createState() => _UserPostsScreenState();
}

class _UserPostsScreenState extends State<UserPostsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Post> _posts = [];
  bool _isLoading = false; // Changed from true to false
  bool _hasMorePosts = true;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    print('=== INIT STATE ===');
    print('Initial _isLoading: $_isLoading');
    print('Initial _hasMorePosts: $_hasMorePosts');
    _loadUserPosts();
  }

  Future<void> _loadUserPosts() async {
    print('=== _loadUserPosts START ===');
    print('_hasMorePosts: $_hasMorePosts');
    print('_isLoading: $_isLoading');
    print('widget.userId: ${widget.userId}');

    if (!_hasMorePosts || _isLoading) {
      print(
        'Early return - hasMorePosts: $_hasMorePosts, isLoading: $_isLoading',
      );
      return;
    }

    print('Setting loading state to true');
    setState(() {
      _isLoading = true;
    });
    print('Loading state set to true');

    try {
      print('Creating query for user: ${widget.userId}');

      Query query = _firestore
          .collection('confessions')
          .where('userId', isEqualTo: widget.userId)
          .limit(10);

      print(
        'Query created, _lastDocument: ${_lastDocument != null ? "exists" : "null"}',
      );
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
        print('Added startAfterDocument to query');
      }

      print('Executing query...');
      final snapshot = await query.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Query timeout after 10 seconds');
          throw Exception('Query timeout');
        },
      );
      print('Query executed successfully');
      print('Found ${snapshot.docs.length} posts');

      if (snapshot.docs.isEmpty) {
        print('No posts found for user');
        setState(() {
          _hasMorePosts = false;
          _isLoading = false;
        });
        print('=== _loadUserPosts END (no posts) ===');
        return;
      }

      print('Processing ${snapshot.docs.length} documents...');
      final newPosts = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        print('Processing document ${doc.id}: $data');

        final createdAt = data['createdAt']?.toDate() ?? DateTime.now();

        final post = Post(
          id: doc.id,
          content:
              data['text'] ??
              data['content'] ??
              '', // Handle both 'text' and 'content' fields
          isAnonymous: data['isAnonymous'] ?? false,
          username: data['username'] ?? '',
          gender: data['gender'],
          timestamp: _formatTimestamp(createdAt),
          likes: _parseLikes(data['likes']), // Handle likes as list or int
          comments: _parseComments(
            data['comments'],
          ), // Handle comments as list or int
          cardColor: _getRandomCardColor(),
        );
        print('Created post: ${post.id}');
        return post;
      }).toList();

      print('Created ${newPosts.length} post objects');

      print('Updating state...');
      setState(() {
        _posts.addAll(newPosts);
        _lastDocument = snapshot.docs.last;
        _hasMorePosts = snapshot.docs.length == 10;
        _isLoading = false;
      });
      print('State updated successfully');
      print('=== _loadUserPosts END ===');
    } catch (e) {
      print('=== ERROR in _loadUserPosts ===');
      print('Error: $e');
      print('Error type: ${e.runtimeType}');

      // Try a simpler query as fallback
      try {
        print('Trying fallback query...');
        final fallbackSnapshot = await _firestore
            .collection('confessions')
            .where('userId', isEqualTo: widget.userId)
            .limit(5)
            .get();

        print('Fallback query found ${fallbackSnapshot.docs.length} posts');

        if (fallbackSnapshot.docs.isNotEmpty) {
          print('Processing fallback posts...');
          final newPosts = fallbackSnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            print('Fallback post data: $data');

            final createdAt = data['createdAt']?.toDate() ?? DateTime.now();

            final post = Post(
              id: doc.id,
              content:
                  data['text'] ??
                  data['content'] ??
                  '', // Handle both 'text' and 'content' fields
              isAnonymous: data['isAnonymous'] ?? false,
              username: data['username'] ?? '',
              gender: data['gender'],
              timestamp: _formatTimestamp(createdAt),
              likes: _parseLikes(data['likes']), // Handle likes as list or int
              comments: _parseComments(
                data['comments'],
              ), // Handle comments as list or int
              cardColor: _getRandomCardColor(),
            );
            print('Created fallback post: ${post.id}');
            return post;
          }).toList();

          print('Updating state with fallback posts...');
          setState(() {
            _posts.addAll(newPosts);
            _hasMorePosts = false; // Don't try to load more with fallback
            _isLoading = false;
          });
          print('Fallback posts loaded successfully');
          return;
        } else {
          print('Fallback query also returned no posts');
        }
      } catch (fallbackError) {
        print('Fallback query also failed: $fallbackError');
        print('Fallback error type: ${fallbackError.runtimeType}');
      }

      print('Setting loading to false after all attempts failed');
      setState(() {
        _isLoading = false;
      });
      print('=== ERROR HANDLING END ===');
    }
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _posts.clear();
      _lastDocument = null;
      _hasMorePosts = true;
    });
    await _loadUserPosts();
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Color _getRandomCardColor() {
    final colors = [
      const Color(0xFF1C1C1E),
      const Color(0xFF2C2C2E),
      const Color(0xFF3C3C3E),
    ];
    return colors[DateTime.now().millisecond % colors.length];
  }

  int _parseLikes(dynamic likes) {
    if (likes == null) return 0;
    if (likes is int) return likes;
    if (likes is List) return likes.length;
    return 0;
  }

  int _parseComments(dynamic comments) {
    if (comments == null) return 0;
    if (comments is int) return comments;
    if (comments is List) return comments.length;
    return 0;
  }

  void _showDeleteDialog(BuildContext context, Post post) {
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.delete_forever,
                color: const Color(0xFFFF453A),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Delete Post',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete this post? This action cannot be undone.',
            style: TextStyle(color: Colors.grey[300], fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deletePost(post);
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  color: const Color(0xFFFF453A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCustomPostCard(Post post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2E), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with username and timestamp
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF2C2C2E),
                child: Text(
                  (post.username?.isNotEmpty == true)
                      ? post.username!.substring(0, 1).toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.isAnonymous
                          ? 'Anonymous'
                          : (post.username ?? 'User'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      post.timestamp,
                      style: const TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Post content
          Text(
            post.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              // Like button
              GestureDetector(
                onTap: () {
                  // TODO: Implement like functionality
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.transparent,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 18,
                        color: const Color(0xFF8E8E93),
                      ),
                      if (post.likes > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          post.likes.toString(),
                          style: const TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Comment button
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PostDetailScreen(post: post),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.transparent,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 18,
                        color: const Color(0xFF8E8E93),
                      ),
                      if (post.comments > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          post.comments.toString(),
                          style: const TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Delete button
              GestureDetector(
                onTap: () => _showDeleteDialog(context, post),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.transparent,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: const Color(0xFF8E8E93),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(Post post) async {
    try {
      print('Deleting post: ${post.id}');

      // Delete from Firestore
      await _firestore.collection('confessions').doc(post.id).delete();

      // Remove from local list
      setState(() {
        _posts.removeWhere((p) => p.id == post.id);
      });

      print('Post deleted successfully');

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Post deleted successfully',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xFF1C1C1E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error deleting post: $e');

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete post: $e',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xFF1C1C1E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    print('=== BUILD METHOD ===');
    print('_posts.length: ${_posts.length}');
    print('_isLoading: $_isLoading');
    print('_hasMorePosts: $_hasMorePosts');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${widget.displayName}\'s Posts',
          style: TextStyle(
            fontSize: size.width * 0.045,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        backgroundColor: Colors.black,
        color: AppColors.systemRed,
        child: _posts.isEmpty && !_isLoading
            ? _buildEmptyState(size)
            : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: _posts.length + (_hasMorePosts ? 1 : 0),
                itemBuilder: (context, index) {
                  print(
                    'Building item $index of ${_posts.length + (_hasMorePosts ? 1 : 0)}',
                  );

                  if (index == _posts.length) {
                    print('Building loading indicator');
                    if (_hasMorePosts && !_isLoading) {
                      print('Calling _loadUserPosts from loading indicator');
                      _loadUserPosts();
                      return Container(
                        padding: const EdgeInsets.all(16),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.systemRed,
                          ),
                        ),
                      );
                    } else if (_isLoading) {
                      print('Already loading, showing loading indicator');
                      return Container(
                        padding: const EdgeInsets.all(16),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.systemRed,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }

                  final post = _posts[index];
                  print('Building post card for post: ${post.id}');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildCustomPostCard(post),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState(Size size) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: size.width * 0.2,
            height: size.width * 0.2,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              color: const Color(0xFF8E8E93),
              size: size.width * 0.1,
            ),
          ),
          SizedBox(height: size.height * 0.03),
          Text(
            'No Posts Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: size.width * 0.05,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: size.height * 0.01),
          Text(
            '${widget.displayName} hasn\'t shared any posts yet',
            style: TextStyle(
              color: const Color(0xFF8E8E93),
              fontSize: size.width * 0.038,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
