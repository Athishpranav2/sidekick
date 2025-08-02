import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CommentThreadModal extends StatefulWidget {
  final String confessionText;
  final List comments;
  final Future<void> Function(String) onAddComment;
  final String userId;
  final String userName;

  const CommentThreadModal({
    Key? key,
    required this.confessionText,
    required this.comments,
    required this.onAddComment,
    this.userId = '',
    this.userName = '',
  }) : super(key: key);

  @override
  State<CommentThreadModal> createState() => _CommentThreadModalState();
}

class _CommentThreadModalState extends State<CommentThreadModal> {
  final TextEditingController _controller = TextEditingController();
  bool _posting = false;
  late List commentsLocal = [];

  @override
  void initState() {
    super.initState();
    commentsLocal = List.from(widget.comments ?? []);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addLocalComment(Map comment) {
    setState(() {
      commentsLocal.add(comment);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.confessionText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Comments',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: commentsLocal.isEmpty
                ? const Center(
                    child: Text(
                      'No comments yet.',
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : ListView.separated(
                    itemCount: commentsLocal.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white12, height: 16),
                    itemBuilder: (context, i) {
                      final c = commentsLocal[i];
                      return GestureDetector(
                        onTap: () {
                          // Placeholder: expand thread
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: Colors.black,
                              title: Text(
                                c['username'] ?? 'Anonymous',
                                style: const TextStyle(color: Colors.white),
                              ),
                              content: Text(
                                c['text'] ?? '',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (c['username'] != null &&
                                      c['username']
                                          .toString()
                                          .trim()
                                          .isNotEmpty)
                                  ? c['username']
                                  : 'Unknown',
                              style: const TextStyle(
                                color: AppColors.systemRed, // Softer red accent
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                fontFamily: 'BebasNeue',
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFF232326),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                c['text'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Color(0xFF232326),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
              ),
              const SizedBox(width: 8),
              _posting
                  ? const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.systemRed,
                    )
                  : IconButton(
                      icon: const Icon(Icons.send, color: AppColors.systemRed),
                      onPressed: () async {
                        final text = _controller.text.trim();
                        if (text.isEmpty) return;
                        setState(() => _posting = true);
                        // Add local comment immediately for instant UI update
                        final commentObj = {
                          'userId': widget.userId,
                          'username': widget.userName,
                          'text': text,
                          'timestamp': DateTime.now().toIso8601String(),
                        };
                        _addLocalComment(commentObj);
                        await widget.onAddComment(text);
                        setState(() => _posting = false);
                        _controller.clear();
                        // Keep focus after posting
                        FocusScope.of(context).requestFocus(FocusNode());
                      },
                    ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
