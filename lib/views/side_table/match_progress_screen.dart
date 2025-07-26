import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

// This will be your logic file.
import './match_progress_logic.dart';

class MatchProgressScreen extends StatefulWidget {
  const MatchProgressScreen({super.key});

  @override
  State<MatchProgressScreen> createState() => _MatchProgressScreenState();
}

class _MatchProgressScreenState extends State<MatchProgressScreen>
    with TickerProviderStateMixin {
  late final MatchProgressController _controller;
  late ScrollController _scrollController;
  // Controller for the new loading animation
  late AnimationController _loadingAnimController;

  // Refined color palette with a full black background
  static const Color primaryRed = Color(0xFFFF453A);
  static const Color backgroundColor = Color(
    0xFF000000,
  ); // Full black background
  static const Color cardColor = Color(0xFF1C1C1E); // Kept for cards
  static const Color secondaryCardColor = Color(0xFF2C2C2E);
  static const Color borderColor = Color(0xFF38383A);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF98989E);
  static const Color textTertiary = Color(0xFF646468);
  static const Color successColor = Color(0xFF32D74B);
  static const Color warningColor = Color(0xFFFF9F0A);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _controller = MatchProgressController(
      vsync: this,
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );
    // Initialize the new loading animation controller
    _loadingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _controller.initialize(context);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    _loadingAnimController.dispose(); // Dispose the new controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: _controller.isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: textPrimary,
          size: 22,
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
        },
      ),
      title: const Text(
        'Activity Hub',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: borderColor.withOpacity(0.5), height: 1.0),
      ),
    );
  }

  // --- NEW LOADING STATE WIDGET ---
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // The new custom animation
          AnimatedBuilder(
            animation: _loadingAnimController,
            builder: (context, child) {
              return CustomPaint(
                painter: _RadarPainter(_loadingAnimController.value),
                child: const SizedBox(width: 150, height: 150),
              );
            },
          ),
          const SizedBox(height: 48),
          // Updated text
          const Text(
            'Finding your Sidekicker...',
            style: TextStyle(
              color: textSecondary,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return FadeTransition(
      opacity: _controller.fadeAnimation,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: _buildCurrentStatusSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
          _buildSectionSliver('The Lineup', _buildActiveQueueSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          _buildSectionSliver('Active Hangouts', _buildActiveMatchesSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          _buildSectionSliver('Past Hangouts', _buildRecentMatchesSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildSectionSliver(String title, Widget content) {
    final horizontalPadding = _getResponsivePadding(
      MediaQuery.of(context).size.width,
    );

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 12),
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: content,
            ),
          ],
        ),
      ),
    );
  }

  double _getResponsivePadding(double screenWidth) {
    if (screenWidth > 600) return 40;
    return 16;
  }

  Widget _buildCurrentStatusSection() {
    if (_controller.user == null) return const SizedBox.shrink();
    final horizontalPadding = _getResponsivePadding(
      MediaQuery.of(context).size.width,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: StreamBuilder<QuerySnapshot>(
        stream: _controller.queueStatusStream,
        builder: (context, queueSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: _controller.activeMatchStream,
            builder: (context, matchSnapshot) {
              if (matchSnapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(color: primaryRed),
                  ),
                );
              }
              if (matchSnapshot.hasData &&
                  matchSnapshot.data!.docs.isNotEmpty) {
                final matchDoc = matchSnapshot.data!.docs.first;
                return _buildActiveMatchCard(
                  matchDoc.data() as Map<String, dynamic>,
                  matchDoc.id,
                );
              }
              if (queueSnapshot.hasData &&
                  queueSnapshot.data!.docs.isNotEmpty) {
                return _buildSearchingCard(
                  queueSnapshot.data!.docs.first.data() as Map<String, dynamic>,
                );
              }
              return _buildIdleCard();
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchingCard(Map<String, dynamic> data) {
    final timeSlot = data['timeSlot'] ?? 'Unknown';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Finding your Sidekicker...",
            style: TextStyle(
              color: textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "For the $timeSlot hangout. Stay tuned!",
            style: const TextStyle(
              color: textSecondary,
              fontSize: 16,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _controller.pulseController,
            builder: (context, child) {
              return Opacity(
                opacity: (_controller.pulseController.value * 0.5) + 0.5,
                child: child,
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation(primaryRed),
                backgroundColor: secondaryCardColor,
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMatchCard(Map<String, dynamic> data, String matchId) {
    final meetupLocation = data['meetupLocation'] ?? 'Main Canteen';
    final otherUserId = (List<String>.from(
      data['users'] ?? [],
    )).firstWhere((id) => id != _controller.user?.uid, orElse: () => '');

    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor.withOpacity(0.75),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            children: [
              const Text(
                "It's a Vibe!",
                style: TextStyle(
                  color: successColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<DocumentSnapshot>(
                future: _controller.getUserDetails(otherUserId),
                builder: (context, snapshot) {
                  String matchText = "You've got a match!";
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final userData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    final userName = userData['displayName'] ?? 'Someone';
                    matchText = "You're meeting ${userName}!";
                  } else if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    matchText = "Loading your match...";
                  }
                  return Text(
                    matchText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildInfoRow(Icons.location_on_rounded, meetupLocation),
              const SizedBox(height: 10),
              _buildInfoRow(Icons.access_time_filled_rounded, "Happening Now"),
              const SizedBox(height: 24),
              _buildCancelButton(
                onPressed: () => _controller.cancelMatch(matchId),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdleCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.emoji_people_rounded, color: textSecondary, size: 48),
          SizedBox(height: 16),
          Text(
            "Ready to Hangout?",
            style: TextStyle(
              color: textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Jump into The Lineup to meet new people on campus.",
            textAlign: TextAlign.center,
            style: TextStyle(color: textSecondary, fontSize: 16, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveQueueSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _controller.activeQueueStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyListItem('No active lineups');
        }
        return ListView.separated(
          itemCount: snapshot.data!.docs.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: borderColor.withOpacity(0.7),
            indent: 56,
          ),
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            return _buildQueueCard(doc.data() as Map<String, dynamic>, doc.id);
          },
        );
      },
    );
  }

  Widget _buildActiveMatchesSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _controller.allActiveMatchesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyListItem('No active hangouts');
        }
        return ListView.separated(
          itemCount: snapshot.data!.docs.length,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: borderColor.withOpacity(0.7),
            indent: 56,
          ),
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            return _buildMatchCard(doc.data() as Map<String, dynamic>, doc.id);
          },
        );
      },
    );
  }

  Widget _buildRecentMatchesSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _controller.recentMatchesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyListItem('No past hangouts yet');
        }
        return ListView.separated(
          itemCount: snapshot.data!.docs.length,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: borderColor.withOpacity(0.7),
            indent: 56,
          ),
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            return _buildMatchCard(doc.data() as Map<String, dynamic>, doc.id);
          },
        );
      },
    );
  }

  Widget _buildQueueCard(Map<String, dynamic> data, String docId) {
    final timeSlot = data['timeSlot'] ?? 'Unknown';
    final joinedAt =
        (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              const SizedBox(width: 4),
              const Icon(
                Icons.hourglass_bottom_rounded,
                color: primaryRed,
                size: 24,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeSlot,
                      style: const TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Joined ${_controller.getTimeAgo(joinedAt)}",
                      style: const TextStyle(
                        color: textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _controller.cancelQueue(docId);
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: primaryRed,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> data, String docId) {
    final status = data['status'] ?? 'unknown';
    final otherUserId = (List<String>.from(
      data['users'] ?? [],
    )).firstWhere((id) => id != _controller.user?.uid, orElse: () => '');
    final matchedAt =
        (data['matchedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    IconData statusIconData;
    Color statusIconColor;

    switch (status) {
      case 'active':
        statusIconData = Icons.circle;
        statusIconColor = successColor;
        break;
      case 'completed':
        statusIconData = Icons.check_circle_rounded;
        statusIconColor = textTertiary;
        break;
      case 'cancelled':
        statusIconData = Icons.cancel_rounded;
        statusIconColor = warningColor;
        break;
      default:
        statusIconData = Icons.help_outline_rounded;
        statusIconColor = textTertiary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          const SizedBox(width: 4),
          Icon(statusIconData, color: statusIconColor, size: 24),
          const SizedBox(width: 20),
          Expanded(
            child: FutureBuilder<DocumentSnapshot>(
              future: _controller.getUserDetails(otherUserId),
              builder: (context, snapshot) {
                String title = 'A Sidekicker';
                if (snapshot.hasData && snapshot.data!.exists) {
                  title =
                      (snapshot.data!.data()
                          as Map<String, dynamic>)['displayName'] ??
                      'A Sidekicker';
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _controller.getTimeAgo(matchedAt),
                      style: const TextStyle(
                        color: textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (status == 'active')
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _controller.cancelMatch(docId);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: primaryRed,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildEmptyListItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: textSecondary, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: textSecondary, size: 18),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            color: textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCancelButton({required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: secondaryCardColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          HapticFeedback.mediumImpact();
          onPressed();
        },
        child: const Text(
          'Cancel Hangout',
          style: TextStyle(
            color: primaryRed,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// --- CUSTOM PAINTER FOR THE NEW LOADING ANIMATION ---
class _RadarPainter extends CustomPainter {
  final double animationValue;

  _RadarPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // We draw 3 circles with different animation offsets for the sonar effect
    for (int i = 0; i < 3; i++) {
      final tick = (animationValue + (i * 0.33)) % 1.0;
      final radius = maxRadius * Curves.easeOut.transform(tick);
      final opacity = (1.0 - tick) * 0.7; // Fade out as it expands

      final paint = Paint()
        ..color = _MatchProgressScreenState.primaryRed.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      if (opacity > 0) {
        // Only draw if visible
        canvas.drawCircle(center, radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Repaint on every frame
  }
}
