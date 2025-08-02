import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import './match_progress_logic.dart';
import '../chat/chat_screen.dart'; // Import for the new chat screen

class MatchProgressScreen extends StatefulWidget {
  const MatchProgressScreen({super.key});

  @override
  State<MatchProgressScreen> createState() => _MatchProgressScreenState();
}

class _MatchProgressScreenState extends State<MatchProgressScreen>
    with TickerProviderStateMixin {
  late final MatchProgressController _controller;
  late ScrollController _scrollController;
  late AnimationController _loadingAnimController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Dark mode with red accent color palette
  static const Color primaryAction = Color(0xFFFF3B30);
  static const Color surfacePrimary = Color(0xFF000000);
  static const Color surfaceSecondary = Color(0xFF111111);
  static const Color surfaceTertiary = Color(0xFF1C1C1E);
  static const Color strokeLight = Color(0xFF2C2C2E);
  static const Color strokeMedium = Color(0xFF3A3A3C);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textTertiary = Color(0xFF666666);
  static const Color successColor = Color(0xFF32D74B);
  static const Color warningColor = Color(0xFFFFCC02);
  static const Color criticalColor = Color(0xFFFF3B30);

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

    _loadingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _controller.initialize(context);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    _loadingAnimController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // Responsive helper methods
  double _getScreenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;
  double _getScreenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  bool _isTablet(BuildContext context) => _getScreenWidth(context) >= 768;
  bool _isLargeScreen(BuildContext context) => _getScreenWidth(context) >= 1024;

  double _getHorizontalPadding(BuildContext context) {
    final width = _getScreenWidth(context);
    if (width >= 1024) return 48; // Large screens
    if (width >= 768) return 32; // Tablets
    return 20; // Phones
  }

  double _getCardPadding(BuildContext context) {
    final width = _getScreenWidth(context);
    if (width >= 1024) return 40; // Large screens
    if (width >= 768) return 36; // Tablets
    return 32; // Phones
  }

  double _getMaxWidth(BuildContext context) {
    final width = _getScreenWidth(context);
    if (width >= 1024) return 800; // Max width for large screens
    return width; // Use full width for smaller screens
  }

  Future<void> _navigateToChat(String matchId, String otherUserId) async {
    HapticFeedback.selectionClick();

    try {
      // Get match details to retrieve meeting time
      final matchDoc = await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .get();

      if (!matchDoc.exists) {
        _showErrorSnackBar('Match not found');
        return;
      }

      final matchData = matchDoc.data() as Map<String, dynamic>;
      final timeSlot = matchData['timeSlot'] ?? '12:00 PM';

      // Navigate to the ChatScreen with the meeting time
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            matchId: matchId,
            otherUserId: otherUserId,
            meetingTime: timeSlot,
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to open chat');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFFE53E3E), // Softer red
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _truncateName(String name, {int maxLength = 20}) {
    final adjustedLength = _isTablet(context) ? maxLength + 10 : maxLength;
    if (name.length <= adjustedLength) return name;
    return '${name.substring(0, adjustedLength)}…';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfacePrimary,
      body: SafeArea(
        child: Center(
          child: Container(
            width: _getMaxWidth(context),
            child: _controller.isLoading
                ? _buildLoadingState()
                : _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final loadingSize = _isTablet(context) ? 160.0 : 120.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _loadingAnimController,
            builder: (context, child) {
              return CustomPaint(
                painter: _MinimalLoadingPainter(_loadingAnimController.value),
                child: SizedBox(width: loadingSize, height: loadingSize),
              );
            },
          ),
          SizedBox(height: _isTablet(context) ? 56 : 48),
          Text(
            'Finding your connection',
            style: TextStyle(
              color: textSecondary,
              fontSize: _isTablet(context) ? 19 : 17,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final buttonSize = _isTablet(context) ? 52.0 : 44.0;
    final iconSize = _isTablet(context) ? 22.0 : 18.0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: surfacePrimary,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false, // Use our custom back button
            leadingWidth: buttonSize + _getHorizontalPadding(context),
            leading: Center(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    color: surfaceSecondary,
                    borderRadius: BorderRadius.circular(
                      _isTablet(context) ? 16 : 12,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: textPrimary,
                    size: iconSize,
                  ),
                ),
              ),
            ),
            title: Text(
              'Activity',
              style: TextStyle(
                fontSize: _isTablet(context) ? 22 : 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            actions: [
              SizedBox(width: buttonSize + _getHorizontalPadding(context)),
            ],
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: _isTablet(context) ? 12 : 8),
          ),
          SliverToBoxAdapter(child: _buildCurrentStatusSection()),
          SliverToBoxAdapter(
            child: SizedBox(height: _isTablet(context) ? 48 : 40),
          ),
          _buildSectionSliver('Queue', _buildActiveQueueSection()),
          SliverToBoxAdapter(
            child: SizedBox(height: _isTablet(context) ? 40 : 32),
          ),
          _buildSectionSliver('Active', _buildActiveMatchesSection()),
          SliverToBoxAdapter(
            child: SizedBox(height: _isTablet(context) ? 40 : 32),
          ),
          _buildSectionSliver('Recent', _buildRecentMatchesSection()),
          SliverToBoxAdapter(
            child: SizedBox(height: _isTablet(context) ? 120 : 100),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionSliver(String title, Widget content) {
    final horizontalPadding = _getHorizontalPadding(context);

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: _isTablet(context) ? 6 : 4,
                bottom: _isTablet(context) ? 16 : 12,
              ),
              child: Text(
                title,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: _isTablet(context) ? 15 : 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: surfaceSecondary,
                borderRadius: BorderRadius.circular(
                  _isTablet(context) ? 20 : 16,
                ),
                border: Border.all(color: strokeLight, width: 0.5),
              ),
              child: content,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatusSection() {
    if (_controller.user == null) return const SizedBox.shrink();

    final horizontalPadding = _getHorizontalPadding(context);
    final cardHeight = _isTablet(context) ? 220.0 : 180.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: StreamBuilder<QuerySnapshot>(
        stream: _controller.queueStatusStream,
        builder: (context, queueSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: _controller.activeMatchStream,
            builder: (context, matchSnapshot) {
              if (matchSnapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  height: cardHeight,
                  decoration: BoxDecoration(
                    color: surfaceSecondary,
                    borderRadius: BorderRadius.circular(
                      _isTablet(context) ? 24 : 20,
                    ),
                    border: Border.all(color: strokeLight, width: 0.5),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: _isTablet(context) ? 28 : 24,
                      height: _isTablet(context) ? 28 : 24,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(primaryAction),
                      ),
                    ),
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
    final cardPadding = _getCardPadding(context);
    final iconSize = _isTablet(context) ? 80.0 : 64.0;
    final iconInnerSize = _isTablet(context) ? 34.0 : 28.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: surfaceSecondary,
        borderRadius: BorderRadius.circular(_isTablet(context) ? 24 : 20),
        border: Border.all(color: strokeLight, width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: primaryAction.withOpacity(0.1),
              borderRadius: BorderRadius.circular(_isTablet(context) ? 24 : 20),
            ),
            child: Icon(
              Icons.search_rounded,
              color: primaryAction,
              size: iconInnerSize,
            ),
          ),
          SizedBox(height: _isTablet(context) ? 28 : 24),
          Text(
            'Searching',
            style: TextStyle(
              color: textPrimary,
              fontSize: _isTablet(context) ? 28 : 24,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: _isTablet(context) ? 12 : 8),
          Text(
            'Looking for someone to join $timeSlot',
            style: TextStyle(
              color: textSecondary,
              fontSize: _isTablet(context) ? 18 : 16,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.1,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: _isTablet(context) ? 40 : 32),
          Container(
            height: _isTablet(context) ? 5 : 4,
            decoration: BoxDecoration(
              color: strokeLight,
              borderRadius: BorderRadius.circular(_isTablet(context) ? 2.5 : 2),
            ),
            child: AnimatedBuilder(
              animation: _controller.pulseController,
              builder: (context, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (_controller.pulseController.value * 0.6) + 0.2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: primaryAction,
                      borderRadius: BorderRadius.circular(
                        _isTablet(context) ? 2.5 : 2,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMatchCard(Map<String, dynamic> data, String matchId) {
    final meetupLocation = data['meetupLocation'] ?? 'Main Canteen';
    final timeSlot = data['timeSlot'] ?? '12:00 PM';
    final otherUserId = (List<String>.from(
      data['users'] ?? [],
    )).firstWhere((id) => id != _controller.user?.uid, orElse: () => '');

    final cardPadding = _getCardPadding(context);
    final iconSize = _isTablet(context) ? 80.0 : 64.0;
    final iconInnerSize = _isTablet(context) ? 34.0 : 28.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: surfaceSecondary,
        borderRadius: BorderRadius.circular(_isTablet(context) ? 24 : 20),
        border: Border.all(color: strokeLight, width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(_isTablet(context) ? 24 : 20),
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: successColor,
              size: iconInnerSize,
            ),
          ),
          SizedBox(height: _isTablet(context) ? 28 : 24),
          FutureBuilder<DocumentSnapshot>(
            future: _controller.getUserDetails(otherUserId),
            builder: (context, snapshot) {
              String matchText = 'Connected';
              String subtitle = 'You have a new match';

              if (snapshot.hasData && snapshot.data!.exists) {
                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final userName = userData['displayName'] ?? 'Someone';
                final truncatedName = _truncateName(userName, maxLength: 15);
                matchText = 'Meeting $truncatedName';
                subtitle = 'Your connection is ready';
              }

              return Column(
                children: [
                  Text(
                    matchText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: _isTablet(context) ? 28 : 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: _isTablet(context) ? 12 : 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: _isTablet(context) ? 18 : 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: _isTablet(context) ? 40 : 32),
          _buildInfoRow(Icons.location_on_outlined, meetupLocation),
          SizedBox(height: _isTablet(context) ? 16 : 12),
          _buildInfoRow(Icons.schedule_outlined, 'Meeting at $timeSlot'),
          SizedBox(height: _isTablet(context) ? 40 : 32),
          Row(
            children: [
              Expanded(
                child: _buildPrimaryButton(
                  'Chat',
                  Icons.chat_bubble_outline_rounded,
                  () => _navigateToChat(matchId, otherUserId),
                ),
              ),
              SizedBox(width: _isTablet(context) ? 16 : 12),
              Expanded(
                child: _buildSecondaryButton(
                  'Cancel',
                  () => _controller.cancelMatch(matchId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIdleCard() {
    final cardPadding = _getCardPadding(context);
    final iconSize = _isTablet(context) ? 80.0 : 64.0;
    final iconInnerSize = _isTablet(context) ? 34.0 : 28.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: surfaceSecondary,
        borderRadius: BorderRadius.circular(_isTablet(context) ? 24 : 20),
        border: Border.all(color: strokeLight, width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: strokeLight,
              borderRadius: BorderRadius.circular(_isTablet(context) ? 24 : 20),
            ),
            child: Icon(
              Icons.people_outline_rounded,
              color: textTertiary,
              size: iconInnerSize,
            ),
          ),
          SizedBox(height: _isTablet(context) ? 28 : 24),
          Text(
            'Ready to connect?',
            style: TextStyle(
              color: textPrimary,
              fontSize: _isTablet(context) ? 28 : 24,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: _isTablet(context) ? 12 : 8),
          Text(
            'Join the queue to meet new people on campus',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textSecondary,
              fontSize: _isTablet(context) ? 18 : 16,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.1,
            ),
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
          return _buildEmptyState('No active queues');
        }

        return ListView.separated(
          itemCount: snapshot.data!.docs.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: strokeLight,
            indent: _isTablet(context) ? 72 : 60,
            endIndent: _isTablet(context) ? 24 : 20,
          ),
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            return _buildQueueItem(doc.data() as Map<String, dynamic>, doc.id);
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
          return _buildEmptyState('No active matches');
        }

        return ListView.separated(
          itemCount: snapshot.data!.docs.length,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: strokeLight,
            indent: _isTablet(context) ? 72 : 60,
            endIndent: _isTablet(context) ? 24 : 20,
          ),
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            return _buildMatchItem(doc.data() as Map<String, dynamic>, doc.id);
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
          return _buildEmptyState('No recent activity');
        }

        return ListView.separated(
          itemCount: snapshot.data!.docs.length,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: strokeLight,
            indent: _isTablet(context) ? 72 : 60,
            endIndent: _isTablet(context) ? 24 : 20,
          ),
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            return _buildMatchItem(doc.data() as Map<String, dynamic>, doc.id);
          },
        );
      },
    );
  }

  Widget _buildQueueItem(Map<String, dynamic> data, String docId) {
    final timeSlot = data['timeSlot'] ?? 'Unknown';
    final joinedAt =
        (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    final horizontalPadding = _getHorizontalPadding(context);
    final iconSize = _isTablet(context) ? 48.0 : 40.0;
    final iconInnerSize = _isTablet(context) ? 24.0 : 20.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: _isTablet(context) ? 20 : 16,
      ),
      child: Row(
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(_isTablet(context) ? 16 : 12),
            ),
            child: Icon(
              Icons.schedule_outlined,
              color: warningColor,
              size: iconInnerSize,
            ),
          ),
          SizedBox(width: _isTablet(context) ? 20 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeSlot,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: _isTablet(context) ? 18 : 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.1,
                  ),
                ),
                SizedBox(height: _isTablet(context) ? 4 : 2),
                Text(
                  'Joined ${_controller.getTimeAgo(joinedAt)}',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: _isTablet(context) ? 16 : 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _controller.cancelQueue(docId);
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: _isTablet(context) ? 16 : 12,
                vertical: _isTablet(context) ? 8 : 6,
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: criticalColor,
                  fontSize: _isTablet(context) ? 17 : 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchItem(Map<String, dynamic> data, String docId) {
    final status = data['status'] ?? 'unknown';
    final timeSlot = data['timeSlot'] ?? '12:00 PM';
    final otherUserId = (List<String>.from(
      data['users'] ?? [],
    )).firstWhere((id) => id != _controller.user?.uid, orElse: () => '');
    final matchedAt =
        (data['matchedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    IconData iconData;
    Color iconColor;
    Color backgroundColor;

    switch (status) {
      case 'active':
        iconData = Icons.chat_bubble_outline_rounded;
        iconColor = successColor;
        backgroundColor = successColor.withOpacity(0.1);
        break;
      case 'completed':
        iconData = Icons.check_circle_outline_rounded;
        iconColor = successColor;
        backgroundColor = successColor.withOpacity(0.1);
        break;
      case 'cancelled':
      case 'expired': // Handle expired status
        iconData = Icons.cancel_outlined;
        iconColor = criticalColor;
        backgroundColor = criticalColor.withOpacity(0.1);
        break;
      default:
        iconData = Icons.help_outline_rounded;
        iconColor = textTertiary;
        backgroundColor = strokeLight;
    }

    final horizontalPadding = _getHorizontalPadding(context);
    final iconSize = _isTablet(context) ? 48.0 : 40.0;
    final iconInnerSize = _isTablet(context) ? 24.0 : 20.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: _isTablet(context) ? 20 : 16,
      ),
      child: Row(
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(_isTablet(context) ? 16 : 12),
            ),
            child: Icon(iconData, color: iconColor, size: iconInnerSize),
          ),
          SizedBox(width: _isTablet(context) ? 20 : 16),
          Expanded(
            child: FutureBuilder<DocumentSnapshot>(
              future: _controller.getUserDetails(otherUserId),
              builder: (context, snapshot) {
                String title = 'Someone';
                if (snapshot.hasData && snapshot.data!.exists) {
                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  title = _truncateName(userData['displayName'] ?? 'Someone');
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: _isTablet(context) ? 18 : 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.1,
                      ),
                    ),
                    SizedBox(height: _isTablet(context) ? 4 : 2),
                    Text(
                      _controller.getTimeAgo(matchedAt),
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: _isTablet(context) ? 16 : 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (status == 'active') ...[
            GestureDetector(
              onTap: () => _navigateToChat(docId, otherUserId),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _isTablet(context) ? 20 : 16,
                  vertical: _isTablet(context) ? 12 : 8,
                ),
                decoration: BoxDecoration(
                  color: primaryAction,
                  borderRadius: BorderRadius.circular(
                    _isTablet(context) ? 10 : 8,
                  ),
                ),
                child: Text(
                  'Chat',
                  style: TextStyle(
                    color: surfacePrimary,
                    fontSize: _isTablet(context) ? 16 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            SizedBox(width: _isTablet(context) ? 12 : 8),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _controller.cancelMatch(docId);
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _isTablet(context) ? 16 : 12,
                  vertical: _isTablet(context) ? 8 : 6,
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: criticalColor,
                    fontSize: _isTablet(context) ? 16 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _isTablet(context) ? 40 : 32),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: textTertiary,
            fontSize: _isTablet(context) ? 17 : 15,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: textSecondary, size: _isTablet(context) ? 22 : 18),
        SizedBox(width: _isTablet(context) ? 12 : 8),
        Text(
          text,
          style: TextStyle(
            color: textSecondary,
            fontSize: _isTablet(context) ? 17 : 15,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    final buttonHeight = _isTablet(context) ? 56.0 : 48.0;
    final iconSize = _isTablet(context) ? 22.0 : 18.0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onPressed();
      },
      child: Container(
        height: buttonHeight,
        decoration: BoxDecoration(
          color: primaryAction,
          borderRadius: BorderRadius.circular(_isTablet(context) ? 16 : 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: surfacePrimary, size: iconSize),
            SizedBox(width: _isTablet(context) ? 12 : 8),
            Text(
              text,
              style: TextStyle(
                color: surfacePrimary,
                fontSize: _isTablet(context) ? 18 : 16,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(String text, VoidCallback onPressed) {
    final buttonHeight = _isTablet(context) ? 56.0 : 48.0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onPressed();
      },
      child: Container(
        height: buttonHeight,
        decoration: BoxDecoration(
          color: surfaceTertiary,
          borderRadius: BorderRadius.circular(_isTablet(context) ? 16 : 12),
          border: Border.all(color: strokeLight, width: 0.5),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: textPrimary,
              fontSize: _isTablet(context) ? 18 : 16,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _MinimalLoadingPainter extends CustomPainter {
  final double animationValue;

  _MinimalLoadingPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final paint = Paint()
      ..color = _MatchProgressScreenState.primaryAction
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    const startAngle = -1.57; // Start from top
    final sweepAngle = 1.57 * animationValue; // Quarter circle sweep

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );

    final backgroundPaint = Paint()
      ..color = _MatchProgressScreenState.strokeLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, radius, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
