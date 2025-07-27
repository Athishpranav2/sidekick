import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../core/services/comment_service.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;

  bool get _hasInputText => _commentController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(() {
      setState(() {}); // Rebuild to update send button state
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _sendComment() async {
    if (_hasInputText && !_isLoading) {
      setState(() {
        _isLoading = true;
      });

      final success = await CommentService.addComment(
        postId: widget.post.id,
        content: _commentController.text.trim(),
        isAnonymous: false, // For now, always post as named user
      );

      setState(() {
        _isLoading = false;
      });

      if (success) {
        _commentController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comment added successfully!'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add comment. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF000000),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar (Header)
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post.isAnonymous ? 'Anonymous Post' : '${widget.post.username}\'s Post',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${widget.post.timestamp} ago',
                            style: const TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 14,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Post Section with card-style container
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E), // Slightly darker card for contrast
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User info row with improved layout
                            Row(
                              children: [
                                _buildAvatar(),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.post.isAnonymous 
                                            ? 'Anonymous' 
                                            : '@${widget.post.username}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.post.timestamp,
                                        style: const TextStyle(
                                          color: Color(0xFF888888),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Post content
                            Text(
                              widget.post.content,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                height: 1.5,
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Tags
                            Wrap(
                              spacing: 6,
                              children: [
                                _buildTag('#general'),
                                if (!widget.post.isAnonymous) _buildTag('#public'),
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
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        height: 1,
                        color: const Color(0xFF333333),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Comments Section with StreamBuilder
                      StreamBuilder<List<Comment>>(
                        stream: CommentService.getCommentsStream(widget.post.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
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
                              // Comments Section Header
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.comment_outlined,
                                      color: Colors.grey[400],
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Comments (${comments.length})',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Comments List
                              if (comments.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Center(
                                    child: Text(
                                      'No comments yet. Be the first to comment!',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: comments.length,
                                  itemBuilder: (context, index) {
                                    return _buildCommentItem(comments[index]);
                                  },
                                ),
                            ],
                          );
                        },
                      ),
                      
                      const SizedBox(height: 80), // Space for input bar
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Input Bar (Bottom) - Sticky
        bottomNavigationBar: Container(
          color: const Color(0xFF000000),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(context).padding.bottom + 8,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F), // Slightly lighter background
              borderRadius: BorderRadius.circular(20), // Increased border radius
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add a comment…', // Removed emoji from placeholder
                      hintStyle: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.comment_outlined,
                        color: Colors.grey[600],
                        size: 18,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12), // Improved padding
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: (_hasInputText && !_isLoading) ? _sendComment : null,
                  child: Container(
                    padding: const EdgeInsets.all(6), // Smaller send button
                    decoration: BoxDecoration(
                      color: (_hasInputText && !_isLoading) ? const Color(0xFFDC2626) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            Icons.send,
                            color: (_hasInputText && !_isLoading) ? Colors.white : const Color(0xFF666666),
                            size: 18, // Smaller icon size
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
      margin: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Username with avatar
          Row(
            children: [
              _buildCommentAvatar(comment),
              const SizedBox(width: 8),
              Text(
                comment.isAnonymous ? 'Anonymous' : comment.username,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          
          // Comment bubble with improved styling
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C), // Updated background color
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  comment.timestamp,
                  style: const TextStyle(
                    color: Color(0xFF999999), // Lighter gray for timestamp
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build comment avatars
  Widget _buildCommentAvatar(Comment comment) {
    if (comment.isAnonymous) {
      // For anonymous comments, use the same SVG avatar with grey background
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.grey[600], // Grey background for the SVG
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2), // Reduced padding to make SVG bigger
          child: SvgPicture.asset(
            'assets/avatar/anon_user.svg',
            width: 16, // Increased from 14 to 16
            height: 16, // Increased from 14 to 16
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn), // Make SVG white
          ),
        ),
      );
    } else {
      // For named users, show initials in colored circle
      String initials = comment.username.isNotEmpty 
          ? comment.username.length >= 2 
              ? comment.username.substring(0, 2).toUpperCase()
              : comment.username.substring(0, 1).toUpperCase()
          : 'U';
      
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }
}
