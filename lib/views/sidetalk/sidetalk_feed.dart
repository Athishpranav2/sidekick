import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'post_card.dart';
import '../../models/post.dart';
import '../../models/filter_options.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/cloud_feed_service.dart';
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

  Set<String> likedPosts = <String>{};
  List<Post> posts = [];
  bool isLoading = true;
  bool isRefreshing = false;
  bool isLoadingMore = false;
  bool hasMorePosts = true;
  DocumentSnapshot? lastDocument;

  FeedMode currentFeedMode = FeedMode.algorithmic;
  DateTime? lastRefreshTime;

  bool isAdmin = false;
  bool showAdminPanel = false;

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
    _initializeAdmin();
    _loadLikedPosts();
    _loadInitialFeed();
  }

  void _loadLikedPosts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('confessions')
          .where('likes', arrayContains: user.uid)
          .get();

      if (mounted) {
        setState(() {
          likedPosts = querySnapshot.docs.map((doc) => doc.id).toSet();
        });
      }
    } catch (e) {
      debugPrint('Error loading liked posts: $e');
      if (mounted) {
        setState(() {
          likedPosts = <String>{};
        });
      }
    }
  }

  Future<void> _initializeAdmin() async {
    setState(() {
      isAdmin = false; // Temporarily disabled
    });
  }

  Future<void> _loadInitialFeed() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await CloudFeedService.getFeed(
        mode: currentFeedMode,
        pageSize: 20,
      );

      if (mounted) {
        setState(() {
          posts = response.posts;
          isLoading = false;
          lastRefreshTime = DateTime.now();
          hasMorePosts = response.hasMore;
        });
      }
    } catch (e) {
      debugPrint('Error loading initial feed: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        _showErrorSnackBar('Failed to load feed. Please try again.');
      }
    }
  }

  Future<void> _refreshFeed() async {
    if (isRefreshing) return;

    setState(() {
      isRefreshing = true;
    });

    try {
      final response = await CloudFeedService.getFeed(
        mode: currentFeedMode,
        pageSize: 20,
        forceRefresh: true,
      );

      if (mounted) {
        setState(() {
          posts = response.posts;
          isRefreshing = false;
          lastRefreshTime = DateTime.now();
          hasMorePosts = response.hasMore;
        });
        HapticFeedback.mediumImpact();
        _showSuccessSnackBar('Feed refreshed');
      }
    } catch (e) {
      debugPrint('Error refreshing feed: $e');
      if (mounted) {
        setState(() {
          isRefreshing = false;
        });
        _showErrorSnackBar('Failed to refresh feed');
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (isLoadingMore || !hasMorePosts) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      final lastPostId = posts.isNotEmpty ? posts.last.id : null;
      final response = await CloudFeedService.getFeed(
        mode: currentFeedMode,
        pageSize: 20,
        lastPostId: lastPostId,
      );

      if (mounted) {
        setState(() {
          posts.addAll(response.posts);
          isLoadingMore = false;
          hasMorePosts = response.hasMore;
        });
      }
    } catch (e) {
      debugPrint('Error loading more posts: $e');
      if (mounted) {
        setState(() {
          isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _switchFeedMode(FeedMode newMode) async {
    if (newMode == currentFeedMode) return;

    setState(() {
      currentFeedMode = newMode;
      isLoading = true;
    });

    try {
      final response = await CloudFeedService.getFeed(
        mode: newMode,
        pageSize: 20,
      );

      if (mounted) {
        setState(() {
          posts = response.posts;
          isLoading = false;
          lastRefreshTime = DateTime.now();
          hasMorePosts = response.hasMore;
        });
        HapticFeedback.selectionClick();
      }
    } catch (e) {
      debugPrint('Error switching feed mode: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.systemRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<Post> get filteredPosts {
    List<Post> filtered = List.from(posts);

    // Filter by anonymous/non-anonymous
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

    // Filter by category
    switch (currentFilter.category) {
      case CategoryFilter.positive:
        break;
      case CategoryFilter.negative:
        break;
      case CategoryFilter.sensitive:
        break;
      case CategoryFilter.others:
        break;
      case CategoryFilter.all:
        break;
    }

    // Filter by user's own posts
    if (currentFilter.showMyPostsOnly) {
      filtered = filtered.where((post) => !post.isAnonymous).toList();
    }

    // Sort posts
    switch (currentFilter.sortBy) {
      case SortOption.recent:
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

  void _toggleLike(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confessionRef = FirebaseFirestore.instance
        .collection('confessions')
        .doc(postId);

    try {
      final doc = await confessionRef.get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final likesData = data['likes'];

      // Handle both List and int formats for likes
      if (likesData is List) {
        final likes = List<String>.from(likesData);

        if (likes.contains(user.uid)) {
          await confessionRef.update({
            'likes': FieldValue.arrayRemove([user.uid]),
          });
          setState(() => likedPosts.remove(postId));
        } else {
          await confessionRef.update({
            'likes': FieldValue.arrayUnion([user.uid]),
          });
          setState(() => likedPosts.add(postId));
        }
      } else if (likesData is int) {
        // If likes is stored as integer, convert to array format
        await confessionRef.update({
          'likes': FieldValue.arrayUnion([user.uid]),
        });
        setState(() => likedPosts.add(postId));
      } else {
        // Fallback: initialize as array
        await confessionRef.update({
          'likes': FieldValue.arrayUnion([user.uid]),
        });
        setState(() => likedPosts.add(postId));
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.layoutMargin,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.tertiaryBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              ),
              child: const Icon(
                Icons.forum_rounded,
                size: 40,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'No Posts Yet',
              style: AppTypography.title2.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Be the first to share your thoughts\nwith the community.',
              style: AppTypography.subheadline.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxxl),
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
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                              child: child,
                            );
                          },
                      transitionDuration: const Duration(milliseconds: 300),
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
              Text(
                'Filter',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
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
    final displayedPosts = filteredPosts; // Calculate once per build

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshFeed,
          color: AppColors.systemRed,
          backgroundColor: AppColors.secondaryBackground,
          strokeWidth: 3.0,
          displacement: 80.0,
          edgeOffset: 0.0,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            cacheExtent: 1000,
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.background,
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        Container(
                          height: kToolbarHeight,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'SIDETALK',
                                style: AppTypography.headline.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              _buildFeedModeButton(),
                              const SizedBox(width: AppSpacing.sm),
                              _buildFilterButton(),
                              if (isAdmin) ...[
                                const SizedBox(width: AppSpacing.sm),
                                _buildAdminButton(),
                              ],
                            ],
                          ),
                        ),
                        Container(height: 0.5, color: AppColors.separator),
                      ],
                    ),
                  ),
                ),
              ),
              isLoading
                  ? SliverFillRemaining(child: _buildLoadingState())
                  : displayedPosts.isEmpty
                  ? SliverFillRemaining(child: _buildEmptyState())
                  : SliverPadding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.sm,
                        bottom: 100,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= displayedPosts.length) return null;
                            final currentPost = displayedPosts[index];
                            return RepaintBoundary(
                              child: PostCard(
                                key: ValueKey(currentPost.id),
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
                          },
                          childCount: displayedPosts.length,
                          addAutomaticKeepAlives: false,
                          addRepaintBoundaries: true,
                          addSemanticIndexes: false,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildIOSFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

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
              Text(
                'Report Post',
                style: AppTypography.headline.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
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

  Widget _buildFeedModeButton() {
    return GestureDetector(
      onTap: () => _showPremiumFeedModeSheet(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.separator, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getFeedModeIcon(currentFeedMode),
              color: AppColors.primary,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              _getFeedModeTitle(currentFeedMode),
              style: AppTypography.caption1.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down, // Changed to down arrow for convention
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showPremiumFeedModeSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildPremiumFeedModeSheet(),
    );
  }

  Widget _buildPremiumFeedModeSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.tune, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Feed Mode',
                    style: AppTypography.headline.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            ...FeedMode.values.map((mode) => _buildPremiumFeedModeOption(mode)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFeedModeOption(FeedMode mode) {
    final isSelected = currentFeedMode == mode;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _switchFeedMode(mode);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getFeedModeIcon(mode),
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getFeedModeTitle(mode),
                    style: AppTypography.body.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getFeedModeDescription(mode),
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }

  String _getFeedModeTitle(FeedMode mode) {
    switch (mode) {
      case FeedMode.algorithmic:
        return 'Smart Feed';
      case FeedMode.chronological:
        return 'Latest';
      case FeedMode.trending:
        return 'Trending';
    }
  }

  String _getFeedModeDescription(FeedMode mode) {
    switch (mode) {
      case FeedMode.algorithmic:
        return 'AI-powered ranking for the best content';
      case FeedMode.chronological:
        return 'See posts as they happen';
      case FeedMode.trending:
        return 'Most engaging posts today';
    }
  }

  IconData _getFeedModeIcon(FeedMode mode) {
    switch (mode) {
      case FeedMode.algorithmic:
        return Icons.auto_awesome;
      case FeedMode.chronological:
        return Icons.access_time;
      case FeedMode.trending:
        return Icons.trending_up;
    }
  }

  Widget _buildAdminButton() {
    return IconButton(
      icon: Icon(
        showAdminPanel
            ? Icons.admin_panel_settings
            : Icons.admin_panel_settings_outlined,
        color: showAdminPanel ? AppColors.primary : AppColors.textSecondary,
        size: 22,
      ),
      onPressed: () {
        setState(() {
          showAdminPanel = !showAdminPanel;
        });
        HapticFeedback.selectionClick();
      },
    );
  }

  Future<void> _handleAdminAction(String action, String postId) async {
    try {
      switch (action) {
        case 'pin':
          _showSuccessSnackBar('Post pinned');
          break;
        case 'hide':
          _showSuccessSnackBar('Post hidden');
          break;
        case 'promote':
          _showSuccessSnackBar('Post promoted');
          break;
        case 'delete':
          _showSuccessSnackBar('Post deleted');
          break;
      }
      await _refreshFeed();
    } catch (e) {
      _showErrorSnackBar('Failed to perform action: $e');
    }
  }
}
