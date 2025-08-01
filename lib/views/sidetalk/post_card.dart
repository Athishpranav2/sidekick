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

class _PostCardState extends State<PostCard> {
  bool _isPressed = false;

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
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () => _navigateToDetail(),
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
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
                      _buildActionButton(
                        icon: widget.likedByMe
                            ? Icons.favorite
                            : Icons.favorite_border,
                        count: widget.post.likes,
                        isActive: widget.likedByMe,
                        activeColor: AppColors.systemRed,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.onLike?.call();
                        },
                      ),

                      const SizedBox(width: AppSpacing.xl),

                      _buildActionButton(
                        icon: Icons.mode_comment_outlined,
                        count: widget.post.comments,
                        activeColor: AppColors.systemBlue,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _navigateToDetail();
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

  // Twitter-style action buttons
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
  void _navigateToDetail() {
    HapticFeedback.selectionClick();
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
