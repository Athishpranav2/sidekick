import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      // For anonymous posts, use the single SVG avatar with grey background
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey[600], // Grey background for the SVG
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4), // Reduced padding to make SVG bigger
          child: SvgPicture.asset(
            'assets/avatar/anon_user.svg',
            width: 24, // Increased from 20 to 24
            height: 24, // Increased from 20 to 24
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn), // Make SVG white
          ),
        ),
      );
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
                    icon: widget.likedByMe ? Icons.favorite : Icons.favorite_border,
                    iconColor: widget.likedByMe ? Colors.red : Colors.grey[400],
                    count: widget.post.likes,
                    onTap: () {
                      if (widget.onLike != null) {
                        widget.onLike!();
                      }
                    },
                  ),
                  const SizedBox(width: 16), // Increased spacing between like and comment
                  _ActionButton(
                    icon: Icons.comment_outlined,
                    iconColor: Colors.grey[400],
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
                  const SizedBox(width: 24), // Much larger spacing before report button
                  _ActionButton(
                    icon: Icons.flag_outlined,
                    iconColor: Colors.grey[400],
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
  final dynamic icon; // Can be either String (emoji) or IconData
  final Color? iconColor;
  final int? count;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    this.iconColor,
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
          icon is IconData
              ? Icon(
                  icon as IconData,
                  size: 16,
                  color: iconColor ?? Colors.grey[400],
                )
              : Text(
                  icon as String,
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