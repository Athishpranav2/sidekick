import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/post.dart';
import '../../core/constants/app_colors.dart';
import 'post_detail_screen.dart';

class PostCard extends StatelessWidget {
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

  // iOS-style avatar with proper sizing
  Widget _buildAvatar() {
    if (post.isAnonymous) {
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
      String displayText = post.username != null
          ? post.username!.substring(0, 1).toUpperCase()
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
    String displayName = post.isAnonymous
        ? 'Anonymous'
        : post.username ?? 'User';

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
                  if (!post.isAnonymous) ...[
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
                '${post.timestamp} ago',
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
                post.content,
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
                        icon: likedByMe
                            ? Icons.favorite
                            : Icons.favorite_border,
                        count: post.likes,
                        isActive: likedByMe,
                        activeColor: AppColors.systemRed,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onLike?.call();
                        },
                      ),

                      const SizedBox(width: AppSpacing.xl),

                      _buildActionButton(
                        icon: Icons.mode_comment_outlined,
                        count: post.comments,
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
                      onReport?.call();
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
  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PostDetailScreen(post: post),
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
