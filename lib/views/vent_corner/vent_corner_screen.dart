import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidekick/providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sidekick/views/compose/compose_screen.dart';
import 'package:sidekick/sidetalk/filter_button.dart';
import 'package:sidekick/sidetalk/post_card.dart';
import 'package:sidekick/models/post.dart';
import 'package:sidekick/views/vent_corner/comment_thread_modal.dart';

// ========== STYLE CONSTANTS ==========
const Color kBlack = Colors.black;
const Color kWhite = Colors.white;
const Color kRed = Color(0xFFDC2626);
const Color kGray = Color(0xFF8E8E93);
const Color kDarkGray = Color(0xFF1E1E1E);

// ========== MAIN SCREEN ==========
class VentCornerScreen extends StatefulWidget {
  const VentCornerScreen({super.key});

  @override
  State<VentCornerScreen> createState() => _VentCornerScreenState();
}

class _VentCornerScreenState extends State<VentCornerScreen> {
  String _selectedFilter = 'ALL';
  final _scrollController = ScrollController();
  bool _showHowItWorks = true; // Controls visibility of the how it works overlay

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _hideHowItWorks() {
    setState(() {
      _showHowItWorks = false;
    });
  }

  Widget _buildHowItWorksOverlay() {
    final size = MediaQuery.of(context).size;
    
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.9),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.06, vertical: size.height * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'SIDETALK',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: size.width * 0.03,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontFamily: 'BebasNeue',
                          ),
                        ),
                        SizedBox(height: size.height * 0.01),
                        Text(
                          'Your safe space to be unhinged.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size.width * 0.07,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: size.height * 0.04),
                  
                  // How It Works Window
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(size.width * 0.06),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(size.width * 0.04),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HOW IT WORKS',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: size.width * 0.04,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.1,
                          ),
                        ),
                        SizedBox(height: size.height * 0.04),
                        _buildStep(
                          size,
                          icon: Icons.edit_note_rounded,
                          title: 'Post Confessions',
                          subtitle: 'Share your thoughts anonymously or publicly with the community.',
                        ),
                        SizedBox(height: size.height * 0.04),
                        _buildStep(
                          size,
                          icon: Icons.favorite_border_rounded,
                          title: 'Engage & Connect',
                          subtitle: 'Like, comment, and interact with posts from other students.',
                        ),
                        SizedBox(height: size.height * 0.04),
                        _buildStep(
                          size,
                          icon: Icons.filter_alt_outlined,
                          title: 'Filter Your Feed',
                          subtitle: 'Switch between all, anonymous, or public confessions.',
                        ),
                      ],
                    ),
                  ),
                  
                  // Get Started Button (below the window)
                  SizedBox(height: size.height * 0.06),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _hideHowItWorks,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kRed,
                        padding: EdgeInsets.symmetric(
                          vertical: size.height * 0.022,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(size.width * 0.04),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'GET STARTED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.width * 0.042,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(
    Size size, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: size.width * 0.14,
          height: size.width * 0.14,
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(size.width * 0.03),
          ),
          child: Icon(
            icon,
            color: kRed,
            size: size.width * 0.07,
          ),
        ),
        SizedBox(width: size.width * 0.04),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size.width * 0.045,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: size.height * 0.005),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: size.width * 0.038,
                  height: 1.4,
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
    return Stack(
      children: [
        Scaffold(
      backgroundColor: kBlack,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(child: _buildConfessionsList()),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 28.0, right: 20.0),
        child: SizedBox(
          height: 68,
          width: 68,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ComposeScreen()),
              );
            },
            backgroundColor: kRed,
            child: const Icon(Icons.add, color: kWhite, size: 36),
            elevation: 8,
            shape: const CircleBorder(),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    ),
    if (_showHowItWorks) _buildHowItWorksOverlay(),
    ],
    );
  }

  // ========== TOP APP BAR ==========
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: kBlack,
      elevation: 0,
      centerTitle: false,
      title: const Padding(
        padding: EdgeInsets.only(left: 8.0),
        child: Text(
          'SIDETALK',
          style: TextStyle(
            color: kGray, // subtle grey
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ),
      actions: [],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1.0),
        child: Divider(color: kDarkGray, height: 1, thickness: 1),
      ),
    );
  }

  // ========== FILTER BAR ==========
  Widget _buildFilterBar() {
    final filters = ['ALL', 'ANONYMOUS', 'PUBLIC'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterButton(
                      text: filter,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedFilter = filter),
                    ),
                  );
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: kWhite, size: 26),
            onPressed: () {/* TODO: Open filters/settings */},
            tooltip: 'More filters',
          ),
        ],
      ),
    );
  }

  // ========== CONFESSIONS STREAM ==========
  Widget _buildConfessionsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('confessions')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: kRed, strokeWidth: 2),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'NO CONFESSIONS YET\nBE THE FIRST TO VENT',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kGray,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          );
        }

        // Filter confessions according to selected filter
        final filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final isAnonymous = data['isAnonymous'] ?? true;
          if (_selectedFilter == 'PUBLIC') return isAnonymous == false;
          if (_selectedFilter == 'ANONYMOUS') return isAnonymous == true;
          return true;
        }).toList();

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            return _buildConfessionCard(doc.data() as Map<String, dynamic>, doc.id);
          },
        );
      },
    );
  }

  // ========== CONFESSION CARD ==========
  Widget _buildConfessionCard(Map<String, dynamic> data, String docId) {
    // Safely parse data with defaults
    final isAnonymous = data['isAnonymous'] ?? true;
    final username = data['username']?.toString();
    final text = data['text']?.toString() ?? '';
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    // Parse likes (handle both list and int formats)
    final List likesList = data['likes'] is List ? data['likes'] as List : [];
    final int likes = likesList.length;
    // Parse comments (handle both list and int formats)
    final List commentsList = data['comments'] is List ? data['comments'] as List : [];
    final int comments = commentsList.length;
    // Card color: assign a pastel/grunge color based on username hash
    // Grey for anonymous, faded red for public
    final cardColor = isAnonymous
        ? const Color(0xFF232326) // dark grey
        : const Color(0x33DC2626); // faded red with alpha
    // Compose Sidetalk Post model
    final post = Post(
      id: docId,
      content: text,
      isAnonymous: isAnonymous,
      username: username,
      timestamp: _formatTimestamp(timestamp),
      likes: likes,
      comments: comments,
      cardColor: cardColor,
    );
    // Use FirebaseAuth for userId if available
    final userId = null; // TODO: Replace with FirebaseAuth.instance.currentUser?.uid
    final userName = null; // TODO: Replace with FirebaseAuth.instance.currentUser?.displayName
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: kDarkGray,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      post.isAnonymous
                          ? 'Anonymous · ${post.timestamp}'
                          : '@${post.username} · ${post.timestamp}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        child: PostCard(
          post: post,
          likedByMe: likesList.contains(userId),
          onLike: () async {
            final docRef = FirebaseFirestore.instance.collection('confessions').doc(docId);
            if (likesList.contains(userId)) {
              await docRef.update({'likes': FieldValue.arrayRemove([userId])});
            } else {
              await docRef.update({'likes': FieldValue.arrayUnion([userId])});
            }
          },
          onComment: () {
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            final user = userProvider.user;
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.black,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) {
                return CommentThreadModal(
                  confessionText: post.content,
                  comments: data['comments'] ?? [],
                  userId: user?.uid ?? '',
                  userName: user?.username ?? '',
                  onAddComment: (commentText) async {
                    if (commentText.trim().isNotEmpty) {
                      final commentObj = {
                        'userId': user?.uid ?? '',
                        'username': user?.username ?? '',
                        'text': commentText.trim(),
                        'timestamp': DateTime.now().toIso8601String(),
                      };
                      await FirebaseFirestore.instance.collection('confessions').doc(docId).update({
                        'comments': FieldValue.arrayUnion([commentObj]),
                      });
                    }
                  },
                );
              },
            );
          },
          onReport: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: kDarkGray,
                title: const Text('Report Confession', style: TextStyle(color: kWhite)),
                content: const Text('Are you sure you want to report this confession?', style: TextStyle(color: kWhite)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Report'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await FirebaseFirestore.instance.collection('confessions').doc(docId).update({
                'reports': FieldValue.arrayUnion([userId]),
              });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reported.')));
            }
          },
        ),
      ),
    );
  }

  // ========== ACTION BUTTON ==========
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: kWhite, size: 20),
      label: Text(
        label,
        style: const TextStyle(
          color: kWhite,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  // ========== UTILS ==========
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) return 'NOW';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    if (difference.inDays < 30) return '${difference.inDays}d';
    
    return DateFormat('MMM d').format(timestamp);
  }
}
