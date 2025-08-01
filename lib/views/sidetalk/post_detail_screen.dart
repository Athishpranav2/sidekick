import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/post.dart';
import '../../models/comment.dart';
import '../../core/services/comment_service.dart';
import '../../core/constants/app_colors.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen>
    with TickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isCommentFocused = false;
  late AnimationController _inputAnimationController;
  late Animation<double> _inputAnimation;

  @override
  void initState() {
    super.initState();
    // Remove the setState listener - we'll use ValueListenableBuilder instead

    // Initialize animation controller
    _inputAnimationController = AnimationController(
      duration: AppAnimations.medium,
      vsync: this,
    );
    _inputAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _inputAnimationController,
        curve: AppAnimations.easeOut,
      ),
    );

    // Set up focus listeners for keyboard handling
    _commentFocusNode.addListener(() {
      setState(() {
        _isCommentFocused = _commentFocusNode.hasFocus;
      });

      if (_commentFocusNode.hasFocus) {
        _inputAnimationController.forward();
        // Auto-scroll to bottom when keyboard appears
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: AppAnimations.medium,
              curve: AppAnimations.easeOut,
            );
          }
        });
      } else {
        _inputAnimationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _scrollController.dispose();
    _inputAnimationController.dispose();
    super.dispose();
  }

  // Isolated send button with no external rebuilds
  Widget _buildSendButton() {
    return StatefulBuilder(
      builder: (context, setButtonState) {
        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: _commentController,
          builder: (context, textValue, child) {
            final hasText = textValue.text.trim().isNotEmpty;
            
            return AnimatedScale(
              scale: _isCommentFocused ? 1.1 : 1.0,
              duration: AppAnimations.fast,
              child: GestureDetector(
                onTap: (hasText && !_isLoading)
                    ? () async {
                        HapticFeedback.mediumImpact();
                        setButtonState(() {
                          _isLoading = true;
                        });

                        final success = await CommentService.addComment(
                          postId: widget.post.id,
                          content: textValue.text.trim(),
                          isAnonymous: false,
                        );

                        setButtonState(() {
                          _isLoading = false;
                        });

                        if (success) {
                          HapticFeedback.lightImpact();
                          _commentController.clear();
                        } else {
                          HapticFeedback.heavyImpact();
                        }
                      }
                    : null,
                child: Container(
                  padding: EdgeInsets.all(
                    _isCommentFocused ? AppSpacing.md : AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    gradient: (hasText && !_isLoading)
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primaryDark,
                            ],
                          )
                        : null,
                    color: (hasText && !_isLoading)
                        ? null
                        : AppColors.tertiaryBackground,
                    borderRadius: BorderRadius.circular(
                      _isCommentFocused
                          ? AppSpacing.radiusLarge
                          : AppSpacing.radiusButton,
                    ),
                    boxShadow: (hasText && !_isLoading && _isCommentFocused)
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color: (hasText && !_isLoading)
                              ? Colors.white
                              : AppColors.textSecondary,
                          size: _isCommentFocused ? 22 : 18,
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: GestureDetector(
            onTap: () {
              // Dismiss keyboard when tapping outside
              if (_commentFocusNode.hasFocus) {
                _commentFocusNode.unfocus();
              }
            },
            child: Stack(
              children: [
                // Main content with scroll controller
                Column(
                  children: [
                    // Premium iOS-style header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.separator,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                            },
                            icon: Icon(
                              Icons.close_rounded,
                              color: AppColors.textPrimary,
                              size: 24,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.tertiaryBackground,
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.post.isAnonymous
                                      ? 'Anonymous Post'
                                      : '${widget.post.username}\'s Post',
                                  style: AppTypography.headline.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: EdgeInsets.only(
                          left: AppSpacing.lg,
                          right: AppSpacing.lg,
                          top: AppSpacing.lg,
                          bottom: 120, // Space for floating comment input
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Premium post content card
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(
                                bottom: AppSpacing.lg,
                              ),
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusCard,
                                ),
                                border: Border.all(
                                  color: AppColors.separator,
                                  width: 0.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadowLight,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Premium user info row
                                  Row(
                                    children: [
                                      _buildAvatar(),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    widget.post.isAnonymous
                                                        ? 'Anonymous'
                                                        : widget
                                                                  .post
                                                                  .username ??
                                                              'User',
                                                    style: AppTypography.callout
                                                        .copyWith(
                                                          color: AppColors
                                                              .textPrimary,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (!widget
                                                    .post
                                                    .isAnonymous) ...[
                                                  const SizedBox(
                                                    width: AppSpacing.xs,
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'PUBLIC',
                                                      style: AppTypography
                                                          .caption2
                                                          .copyWith(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w600,
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
                                              style: AppTypography.footnote
                                                  .copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: AppSpacing.lg),

                                  // Premium post content
                                  Text(
                                    widget.post.content,
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.textPrimary,
                                      height: 1.5,
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Tags
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      _buildTag('#general'),
                                      if (!widget.post.isAnonymous)
                                        _buildTag('#public'),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Post stats with emoji icons
                                  Row(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.favorite,
                                            color: Colors.red,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${widget.post.likes}',
                                            style: const TextStyle(
                                              color: Color(0xFF888888),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 20),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.comment_outlined,
                                            color: Colors.grey[400],
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${widget.post.comments}',
                                            style: const TextStyle(
                                              color: Color(0xFF888888),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Separator line with proper padding
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              height: 1,
                              color: const Color(0xFF333333),
                            ),

                            const SizedBox(height: 20),

                            // Comments Section with StreamBuilder
                            StreamBuilder<List<Comment>>(
                              stream: CommentService.getCommentsStream(
                                widget.post.id,
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFFDC2626),
                                      ),
                                    ),
                                  );
                                }

                                final comments = snapshot.data ?? [];

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Premium Comments Section Header
                                    Container(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.lg,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondaryBackground,
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusCard,
                                        ),
                                        border: Border.all(
                                          color: AppColors.separator,
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.mode_comment_outlined,
                                            color: AppColors.textSecondary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Text(
                                            'Comments (${comments.length})',
                                            style: AppTypography.callout
                                                .copyWith(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: AppSpacing.lg),

                                    // Comments List
                                    if (comments.isEmpty)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(
                                          AppSpacing.xxl,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.cardBackground,
                                          borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusCard,
                                          ),
                                          border: Border.all(
                                            color: AppColors.separator,
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Center(
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons
                                                    .chat_bubble_outline_rounded,
                                                color: AppColors.textTertiary,
                                                size: 32,
                                              ),
                                              const SizedBox(
                                                height: AppSpacing.md,
                                              ),
                                              Text(
                                                'No comments yet',
                                                style: AppTypography.callout
                                                    .copyWith(
                                                      color:
                                                          AppColors.textPrimary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              const SizedBox(
                                                height: AppSpacing.xs,
                                              ),
                                              Text(
                                                'Be the first to comment!',
                                                style: AppTypography.footnote
                                                    .copyWith(
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: comments.length,
                                        itemBuilder: (context, index) {
                                          return _buildCommentItem(
                                            comments[index],
                                          );
                                        },
                                      ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Floating comment input
                _buildFloatingCommentInput(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Perfect floating comment input
  Widget _buildFloatingCommentInput() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedBuilder(
        animation: _inputAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _isCommentFocused ? 0 : 0),
            child: Container(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.md,
                bottom: MediaQuery.of(context).viewInsets.bottom > 0
                    ? AppSpacing.md
                    : MediaQuery.of(context).padding.bottom + AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(
                    color: _isCommentFocused
                        ? AppColors.primary.withOpacity(0.3)
                        : AppColors.separator,
                    width: _isCommentFocused ? 1.0 : 0.5,
                  ),
                ),
                boxShadow: _isCommentFocused
                    ? [
                        BoxShadow(
                          color: AppColors.shadowLight,
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                          spreadRadius: 0,
                        ),
                      ]
                    : [],
              ),
              child: AnimatedContainer(
                duration: AppAnimations.fast,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(
                    _isCommentFocused
                        ? AppSpacing.radiusLarge
                        : AppSpacing.radiusButton,
                  ),
                  border: Border.all(
                    color: _isCommentFocused
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.separator,
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: _isCommentFocused ? 12 : 6,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: _isCommentFocused ? AppSpacing.md : AppSpacing.sm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 120, // Max height for multiline
                        ),
                        child: TextField(
                          controller: _commentController,
                          focusNode: _commentFocusNode,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            hintText: _isCommentFocused
                                ? 'Share your thoughts...'
                                : 'Add a comment…',
                            hintStyle: AppTypography.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: _isCommentFocused ? AppSpacing.sm : 0,
                              vertical: AppSpacing.xs,
                            ),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.newline,
                          keyboardType: TextInputType.multiline,
                        ),
                      ),
                    ),
                                        const SizedBox(width: AppSpacing.md),
                    // Fully isolated send button - no rebuilds during typing
                    _buildSendButton(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar() {
    if (widget.post.isAnonymous) {
      // Premium anonymous avatar
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
          size: 24,
        ),
      );
    } else {
      String displayText = widget.post.username != null
          ? widget.post.username!.length >= 2
                ? widget.post.username!.substring(0, 2).toUpperCase()
                : widget.post.username!.substring(0, 1).toUpperCase()
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
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: Color(0xFFBBBBBB),
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.separator, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium comment header
          Row(
            children: [
              _buildCommentAvatar(comment),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.isAnonymous ? 'Anonymous' : comment.username,
                          style: AppTypography.callout.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!comment.isAnonymous) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.systemBlue,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'COMMENTER',
                              style: AppTypography.caption2.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      comment.timestamp,
                      style: AppTypography.caption2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Premium comment content
          Text(
            comment.content,
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Premium comment avatar
  Widget _buildCommentAvatar(Comment comment) {
    if (comment.isAnonymous) {
      return Container(
        width: AppSpacing.avatarSmall,
        height: AppSpacing.avatarSmall,
        decoration: BoxDecoration(
          color: AppColors.tertiaryBackground,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.separator, width: 0.5),
        ),
        child: Icon(
          Icons.account_circle_rounded,
          color: AppColors.textTertiary,
          size: 16,
        ),
      );
    } else {
      String initials = comment.username.isNotEmpty
          ? comment.username.substring(0, 1).toUpperCase()
          : 'U';

      return Container(
        width: AppSpacing.avatarSmall,
        height: AppSpacing.avatarSmall,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.systemBlue,
              AppColors.systemBlue.withOpacity(0.8),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 2,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            initials,
            style: AppTypography.caption2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ),
      );
    }
  }
}
