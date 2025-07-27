import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math';
import '../models/post.dart';
import 'post_detail_screen.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final bool likedByMe;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onReport;

  const PostCard({super.key, required this.post, required this.likedByMe, this.onLike, this.onComment, this.onReport});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  
  // Get improved background color based on post type
  Color get _getCardBackgroundColor {
    if (widget.post.isAnonymous) {
      return const Color(0xFF1F1F1F); // Anonymous background
    } else {
      return const Color(0xFF2A0000); // Public background
    }
  }

  // Get avatar widget for different post types
  Widget _buildAvatar() {
    if (widget.post.isAnonymous) {
      // For anonymous posts, randomly choose male or female avatar
      final random = Random(widget.post.id.hashCode); // Use post ID as seed for consistency
      final isMale = random.nextBool();
      
      // Choose a random avatar from the appropriate gender folder
      if (isMale) {
        final maleAvatarIndex = random.nextInt(5) + 1; // 1-5
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF333333),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SvgPicture.asset(
              'assets/avatar/anon_logos/male/male_$maleAvatarIndex.svg',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
          ),
        );
      } else {
        final femaleAvatarIndex = random.nextInt(6) + 1; // 1-6
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF333333),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SvgPicture.asset(
              'assets/avatar/anon_logos/female/female_$femaleAvatarIndex.svg',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
          ),
        );
      }
    } else {
      // For public posts, show red circle with initials or number
      String displayText = widget.post.username != null 
          ? widget.post.username!.length >= 2 
              ? widget.post.username!.substring(0, 2).toUpperCase()
              : widget.post.username!.substring(0, 1).toUpperCase()
          : '2';
      
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            displayText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  // Build metadata row with improved formatting and truncation
  Widget _buildMetadata() {
    String displayName = widget.post.isAnonymous 
        ? 'Anonymous'
        : '@${widget.post.username ?? 'unknown'}';
    
    return Row(
      children: [
        Flexible(
          child: Text(
            displayName,
            style: const TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Text(
          ' • ',
          style: TextStyle(
            color: Color(0xFFAAAAAA),
            fontSize: 13,
          ),
        ),
        Text(
          '${widget.post.timestamp} ago',
          style: const TextStyle(
            color: Color(0xFFAAAAAA),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12), // Reduced margin as specified
      padding: const EdgeInsets.all(16), // Consistent 16px padding
      decoration: BoxDecoration(
        color: _getCardBackgroundColor,
        borderRadius: BorderRadius.circular(12), // 12px border radius as specified
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info row (top line)
          Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetadata(),
              ),
            ],
          ),
          
          const SizedBox(height: 8), // Margin-top for post text
          
          // Post Content with improved typography and line limits
          Text(
            widget.post.content,
            style: const TextStyle(
              fontSize: 16, // Specified font size
              fontWeight: FontWeight.bold, // Bold as specified
              color: Colors.white,
              height: 1.4,
            ),
            maxLines: 3, // Max 2-3 lines as specified
            overflow: TextOverflow.ellipsis, // Ellipsis if needed
          ),
          
          const SizedBox(height: 4), // Margin-bottom for post text
          
          // Tags and Actions row - tags on left, actions on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Tags section with inline chips
              Wrap(
                spacing: 6, // margin-right: 6px as specified
                children: [
                  _buildTag('#general'),
                  if (!widget.post.isAnonymous) _buildTag('#public'),
                ],
              ),
              // Action buttons on the right
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionButton(
                    icon: widget.likedByMe ? '❤️' : '🤍',
                    count: widget.post.likes,
                    onTap: () {
                      if (widget.onLike != null) {
                        widget.onLike!();
                      }
                    },
                  ),
                  const SizedBox(width: 12), // Reduced spacing to save space
                  _ActionButton(
                    icon: '💬',
                    count: widget.post.comments,
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => 
                              PostDetailScreen(post: widget.post),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            // Use a slide transition with black background
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1.0, 0.0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOut,
                              )),
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 250),
                          settings: const RouteSettings(name: '/post-detail'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12), // Reduced spacing to save space
                  _ActionButton(
                    icon: '🚩',
                    onTap: widget.onReport ?? () {},
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build tag chips with specified styling
  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // padding: 2px 8px
      decoration: BoxDecoration(
        color: const Color(0xFF333333), // background: #333
        borderRadius: BorderRadius.circular(8), // border-radius: 8px
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: Color(0xFFBBBBBB), // color: #bbb
          fontSize: 12, // font-size: 12px
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String icon;
  final int? count;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: const TextStyle(
              fontSize: 14, // font-size: 14px as specified
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14, // Consistent font size
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}