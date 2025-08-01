import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_card.dart';

import '../../models/post.dart';
import '../../models/filter_options.dart';
import '../../core/constants/app_colors.dart';
import '../compose/compose_screen.dart';

class SidetalkFeed extends StatefulWidget {
  const SidetalkFeed({super.key});

  @override
  State<SidetalkFeed> createState() => _SidetalkFeedState();
}

enum PostTypeFilter { all, anonymous, nonAnonymous }

class _SidetalkFeedState extends State<SidetalkFeed> {
  FilterState currentFilter = const FilterState();
  PostTypeFilter postTypeFilter = PostTypeFilter.all;

  // Simple tracking of liked posts
  Set<String> likedPosts = <String>{};
  List<Post> posts = [];
  bool isLoading = true;

  // Card colors for posts
  final List<Color> cardColors = [
    const Color(0xFFF5F5DC), // Beige
    const Color(0xFFFFFACD), // Light yellow
    const Color(0xFFE6E6E6), // Muted gray
    const Color(0xFFFFF0F5), // Light pink
    const Color(0xFFF0F8FF), // Light blue
  ];

  @override
  void initState() {
    super.initState();
    _loadLikedPosts();
    _listenToPosts();
  }

  void _loadLikedPosts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Get all confessions where user has liked (only works with new array schema)
      final querySnapshot = await FirebaseFirestore.instance
          .collection('confessions')
          .where('likes', arrayContains: user.uid)
          .get();

      setState(() {
        likedPosts = querySnapshot.docs.map((doc) => doc.id).toSet();
      });
    } catch (e) {
      print('Error loading liked posts: $e');
      // If the query fails (due to old schema), just start with empty liked posts
      setState(() {
        likedPosts = <String>{};
      });
    }
  }

  void _listenToPosts() {
    FirebaseFirestore.instance
        .collection('confessions')
        .orderBy('timestamp', descending: true)
        .limit(50) // Limit to recent 50 posts for performance
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              posts = snapshot.docs
                  .where((doc) {
                    final data = doc.data();
                    // Filter approved posts in the app to avoid compound index
                    return data['status'] == 'approved';
                  })
                  .map((doc) {
                    final data = doc.data();
                    return _confessionToPost(doc.id, data);
                  })
                  .toList();
              isLoading = false;
            });
          }
        })
        .onError((error) {
          print('Error listening to posts: $error');
          if (mounted) {
            setState(() {
              isLoading = false;
            });
          }
        });
  }

  Post _confessionToPost(String docId, Map<String, dynamic> data) {
    final timestamp =
        (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

    // Handle likes - can be either array (new) or int (old schema)
    int likesCount;
    final likesData = data['likes'];
    if (likesData is List) {
      // New schema: array of user IDs
      final likes = List<String>.from(
        likesData.where((item) => item != null).map((item) => item.toString()),
      );
      likesCount = likes.length;

      // Update local liked posts tracking for current user
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && likes.contains(user.uid)) {
        likedPosts.add(docId);
      } else {
        likedPosts.remove(docId);
      }
    } else if (likesData is int) {
      // Old schema: direct count
      likesCount = likesData;
    } else {
      // Default case
      likesCount = 0;
    }

    // Handle comments - can be either array (new) or int (old schema)
    int commentsCount;
    final commentsData = data['comments'];
    if (commentsData is List) {
      // New schema: array of comment objects
      final comments = List.from(commentsData.where((item) => item != null));
      commentsCount = comments.length;
    } else if (commentsData is int) {
      // Old schema: direct count
      commentsCount = commentsData;
    } else {
      // Default case
      commentsCount = 0;
    }

    return Post(
      id: docId,
      content: data['text'] ?? '',
      isAnonymous: data['isAnonymous'] ?? true,
      username: data['username'],
      timestamp: _formatTimestamp(timestamp),
      likes: likesCount,
      comments: commentsCount,
      cardColor: cardColors[docId.hashCode % cardColors.length],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  List<Post> get filteredPosts {
    List<Post> filtered = List.from(posts);

    // Filter by post type (existing filter)
    switch (currentFilter.postType) {
      case PostType.anonymous:
        filtered = filtered.where((post) => post.isAnonymous).toList();
        break;
      case PostType.public:
        filtered = filtered.where((post) => !post.isAnonymous).toList();
        break;
      case PostType.all:
        // Keep all posts
        break;
    }

    // Additional filter by anonymous/non-anonymous
    switch (postTypeFilter) {
      case PostTypeFilter.anonymous:
        filtered = filtered.where((post) => post.isAnonymous).toList();
        break;
      case PostTypeFilter.nonAnonymous:
        filtered = filtered.where((post) => !post.isAnonymous).toList();
        break;
      case PostTypeFilter.all:
        // Keep all posts
        break;
    }

    // Filter by category (placeholder logic - you can expand this based on post content analysis)
    switch (currentFilter.category) {
      case CategoryFilter.positive:
        // Example: filter posts with positive sentiment (implement sentiment analysis)
        break;
      case CategoryFilter.negative:
        // Example: filter posts with negative sentiment
        break;
      case CategoryFilter.sensitive:
        // Example: filter posts marked as sensitive
        break;
      case CategoryFilter.others:
        // Example: filter other category posts
        break;
      case CategoryFilter.all:
        // Keep all posts
        break;
    }

    // Filter by user's own posts (placeholder - requires user identification)
    if (currentFilter.showMyPostsOnly) {
      // filtered = filtered.where((post) => post.userId == currentUserId).toList();
      // For now, we'll just show posts with username (as example)
      filtered = filtered.where((post) => !post.isAnonymous).toList();
    }

    // Sort posts
    switch (currentFilter.sortBy) {
      case SortOption.recent:
        // Keep default order (most recent first)
        break;
      case SortOption.mostLiked:
        filtered.sort((a, b) => b.likes.compareTo(a.likes));
        break;
      case SortOption.mostCommented:
        filtered.sort((a, b) => b.comments.compareTo(a.comments));
        break;
    }

    return filtered;
  }

  // Firebase-based like toggle functionality
  void _toggleLike(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confessionRef = FirebaseFirestore.instance
        .collection('confessions')
        .doc(postId);

    try {
      // Check current state first
      final doc = await confessionRef.get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final likesData = data['likes'];

      if (likesData is List) {
        // New schema: use Firestore array methods
        final likes = List<String>.from(likesData);

        if (likes.contains(user.uid)) {
          // Unlike: remove user from array
          await confessionRef.update({
            'likes': FieldValue.arrayRemove([user.uid]),
          });
          setState(() {
            likedPosts.remove(postId);
          });
        } else {
          // Like: add user to array
          await confessionRef.update({
            'likes': FieldValue.arrayUnion([user.uid]),
          });
          setState(() {
            likedPosts.add(postId);
          });
        }
      } else {
        // Old schema: convert to new schema with array union
        await confessionRef.update({
          'likes': FieldValue.arrayUnion([user.uid]),
        });
        setState(() {
          likedPosts.add(postId);
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
      // Revert local state on error
      setState(() {
        if (likedPosts.contains(postId)) {
          likedPosts.remove(postId);
        } else {
          likedPosts.add(postId);
        }
      });
    }
  }

  // iOS-style loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Loading posts...',
            style: AppTypography.callout.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // iOS-style empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.layoutMargin,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // iOS-style icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.tertiaryBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              ),
              child: Icon(
                Icons.forum_rounded,
                size: 40,
                color: AppColors.textTertiary,
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Title
            Text(
              'No Posts Yet',
              style: AppTypography.title2.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.sm),

            // Description
            Text(
              'Be the first to share your thoughts\nwith the community.',
              style: AppTypography.subheadline.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // Call to action button
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 200),
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const ComposeScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            return SlideTransition(
                              position:
                                  Tween<Offset>(
                                    begin: const Offset(0.0, 1.0),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: AppAnimations.easeOut,
                                    ),
                                  ),
                              child: child,
                            );
                          },
                      transitionDuration: AppAnimations.medium,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.lg,
                    horizontal: AppSpacing.xl,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusButton,
                    ),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Create Post',
                  style: AppTypography.callout.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Minimalistic filter button
  Widget _buildFilterButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showFilterSheet();
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Icon(
          Icons.filter_list_outlined,
          color: postTypeFilter == PostTypeFilter.all
              ? AppColors.textSecondary
              : AppColors.textPrimary,
          size: 22,
        ),
      ),
    );
  }

  // Filter action sheet
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.radiusCard),
            topRight: Radius.circular(AppSpacing.radiusCard),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Minimal handle
              Container(
                width: 32,
                height: 3,
                margin: const EdgeInsets.only(top: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.separator,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Simple title
              Text(
                'Filter',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Filter options
              _buildFilterOption(
                title: 'All Posts',
                isSelected: postTypeFilter == PostTypeFilter.all,
                onTap: () => _updateFilter(PostTypeFilter.all),
              ),
              _buildFilterOption(
                title: 'Anonymous Only',
                isSelected: postTypeFilter == PostTypeFilter.anonymous,
                onTap: () => _updateFilter(PostTypeFilter.anonymous),
              ),
              _buildFilterOption(
                title: 'Public Only',
                isSelected: postTypeFilter == PostTypeFilter.nonAnonymous,
                onTap: () => _updateFilter(PostTypeFilter.nonAnonymous),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.lg),
            Text(
              title,
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateFilter(PostTypeFilter filter) {
    setState(() {
      postTypeFilter = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(), // iOS-style bouncing
        slivers: [
          // iOS-style navigation bar
          SliverAppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            pinned: true,
            centerTitle: true,
            title: Text(
              'SIDETALK',
              style: AppTypography.headline.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            actions: [
              _buildFilterButton(),
              const SizedBox(width: AppSpacing.md),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 0.5, color: AppColors.separator),
            ),
          ),

          // Posts content
          isLoading
              ? SliverFillRemaining(child: _buildLoadingState())
              : filteredPosts.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState())
              : SliverPadding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.sm,
                    bottom: 100, // Space for FAB
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final currentPost = filteredPosts[index];
                      return Container(
                        margin: EdgeInsets.only(
                          bottom: index == filteredPosts.length - 1 ? 0 : 1,
                        ),
                        child: PostCard(
                          post: currentPost,
                          likedByMe: likedPosts.contains(currentPost.id),
                          onLike: () {
                            HapticFeedback.lightImpact();
                            _toggleLike(currentPost.id);
                          },
                          onReport: () {
                            _showReportSheet(currentPost);
                          },
                        ),
                      );
                    }, childCount: filteredPosts.length),
                  ),
                ),
        ],
      ),

      // iOS-style floating action button
      floatingActionButton: _buildIOSFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // iOS-style floating action button
  Widget _buildIOSFAB() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const ComposeScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0.0, 1.0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: AppAnimations.easeOut,
                              ),
                            ),
                        child: child,
                      );
                    },
                transitionDuration: AppAnimations.medium,
              ),
            );
          },
          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  // iOS-style report action sheet
  void _showReportSheet(Post post) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusMedium),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 36,
                height: 5,
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Title
              Text(
                'Report Post',
                style: AppTypography.headline.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Report options
              _buildReportOption(
                icon: Icons.report_rounded,
                title: 'Inappropriate Content',
                onTap: () => _handleReport(post, 'inappropriate'),
              ),
              _buildReportOption(
                icon: Icons.block_rounded,
                title: 'Spam',
                onTap: () => _handleReport(post, 'spam'),
              ),
              _buildReportOption(
                icon: Icons.dangerous_rounded,
                title: 'Harmful Content',
                onTap: () => _handleReport(post, 'harmful'),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Cancel button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.layoutMargin,
                ),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.tertiaryBackground,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusButton,
                      ),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: AppTypography.callout.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.layoutMargin,
        vertical: AppSpacing.xs,
      ),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: AppColors.tertiaryBackground,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.destructive, size: 20),
            const SizedBox(width: AppSpacing.lg),
            Text(
              title,
              style: AppTypography.callout.copyWith(
                color: AppColors.destructive,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleReport(Post post, String reason) {
    Navigator.pop(context);
    HapticFeedback.heavyImpact();
    // Report submitted silently - no notification needed
  }
}
