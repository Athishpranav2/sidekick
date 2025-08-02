import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/post.dart';
import '../../core/constants/app_colors.dart';
import 'post_detail_screen.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final bool likedByMe;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onReport;

  const PostCard({
    super.key,
    required this.post,
    required this.likedByMe,
    this.onLike,
    this.onComment,
    this.onReport,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  // Local state for optimistic updates
  late bool _isLiked;
  late int _likeCount;
  bool _isProcessing = false;

  // Simple animation controller for heart
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize local state
    _isLiked = widget.likedByMe;
    _likeCount = widget.post.likes;

    // Simple scale animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Sync with parent when not processing
    if (!_isProcessing) {
      if (mounted &&
          (oldWidget.likedByMe != widget.likedByMe ||
              oldWidget.post.likes != widget.post.likes)) {
        setState(() {
          _isLiked = widget.likedByMe;
          _likeCount = widget.post.likes;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Handle like with optimistic update
  void _handleLike() {
    if (_isProcessing || widget.onLike == null) return;

    // Immediate UI update
    setState(() {
      _isProcessing = true;
      _isLiked = !_isLiked;
      _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
    });

    // Immediate feedback
    HapticFeedback.lightImpact();

    // Animate if liked
    if (_isLiked) {
      _animationController.forward().then(
        (_) => _animationController.reverse(),
      );
    }

    // Call parent callback
    widget.onLike!();

    // Reset processing state after delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  // iOS-style avatar with proper sizing
  Widget _buildAvatar() {
    if (widget.post.isAnonymous) {
      return Container(
        width: AppSpacing.avatarMedium,
        height: AppSpacing.avatarMedium,
        decoration: BoxDecoration(
          color: AppColors.tertiaryBackground,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.separator, width: 0.5),
        ),
        child: Icon(
          Icons.account_circle_rounded,
          color: AppColors.textTertiary,
          size: 20,
        ),
      );
    } else {
      String displayText = widget.post.username != null
          ? widget.post.username!.substring(0, 1).toUpperCase()
          : 'U';

      return Container(
        width: AppSpacing.avatarMedium,
        height: AppSpacing.avatarMedium,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 4,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            displayText,
            style: AppTypography.callout.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
  }

  // Twitter-style metadata with proper hierarchy
  Widget _buildHeader() {
    String displayName = widget.post.isAnonymous
        ? 'Anonymous'
        : widget.post.username ?? 'User';

    return Row(
      children: [
        _buildAvatar(),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      style: AppTypography.callout.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!widget.post.isAnonymous) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PUBLIC',
                        style: AppTypography.caption2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.post.timestamp} ago',
                style: AppTypography.footnote.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          _navigateToDetail(context);
        },
        splashColor: AppColors.primary.withOpacity(0.1),
        highlightColor: AppColors.primary.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.separator, width: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Twitter-style header
              _buildHeader(),

              const SizedBox(height: AppSpacing.sm),

              // Post content with proper typography
              Text(
                widget.post.content,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Twitter-style action row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildLikeButton(),

                      const SizedBox(width: AppSpacing.xl),

                      _buildActionButton(
                        icon: Icons.mode_comment_outlined,
                        count: widget.post.comments,
                        activeColor: AppColors.systemBlue,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _navigateToDetail(context);
                        },
                      ),
                    ],
                  ),

                  // Report button
                  _buildActionButton(
                    icon: Icons.report_outlined,
                    activeColor: AppColors.systemOrange,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onReport?.call();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Enhanced like button with simple animation
  Widget _buildLikeButton() {
    return GestureDetector(
      onTap: _handleLike,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          color: _isLiked
              ? AppColors.systemRed.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                    color: _isLiked
                        ? AppColors.systemRed
                        : AppColors.textSecondary,
                  ),
                );
              },
            ),

            if (_likeCount > 0) ...[
              const SizedBox(width: AppSpacing.xs),
              Text(
                _likeCount.toString(),
                style: AppTypography.footnote.copyWith(
                  color: _isLiked
                      ? AppColors.systemRed
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Regular action buttons
  Widget _buildActionButton({
    required IconData icon,
    int? count,
    bool isActive = false,
    Color activeColor = Colors.blue,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? activeColor : AppColors.textSecondary,
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: AppSpacing.xs),
              Text(
                count.toString(),
                style: AppTypography.footnote.copyWith(
                  color: isActive ? activeColor : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // iOS-style navigation to detail screen
  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PostDetailScreen(post: widget.post),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
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
  }
}
