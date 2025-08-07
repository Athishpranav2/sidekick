// FILE: views/side_table/side_table_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'time_selection_screen.dart'; // Import the new screen
import 'match_progress_screen.dart'; // Import the match progress screen
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';

class SideTableScreen extends StatefulWidget {
  const SideTableScreen({super.key});

  @override
  State<SideTableScreen> createState() => _SideTableScreenState();
}

class _SideTableScreenState extends State<SideTableScreen> {
  bool _hasActiveQueue = false;
  bool _hasRecentMatches = false;
  StreamSubscription<QuerySnapshot>? _queueSubscription;
  StreamSubscription<QuerySnapshot>? _matchesSubscription;
  StreamSubscription<QuerySnapshot>? _chatSubscription;

  @override
  void initState() {
    super.initState();
    _setupRealTimeListeners();
  }

  @override
  void dispose() {
    _queueSubscription?.cancel();
    _matchesSubscription?.cancel();
    _chatSubscription?.cancel();
    super.dispose();
  }

  void _setupRealTimeListeners() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Listen for active queue entries in real-time
      _queueSubscription = FirebaseFirestore.instance
          .collection('matchingQueue')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'waiting')
          .snapshots()
          .listen((snapshot) {
            if (mounted) {
              setState(() {
                _hasActiveQueue = snapshot.docs.isNotEmpty;
              });
            }
          });

      // Listen for recent active matches in real-time
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      _matchesSubscription = FirebaseFirestore.instance
          .collection('matches')
          .where('users', arrayContains: user.uid)
          .where('status', isEqualTo: 'active')
          .where(
            'matchedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .snapshots()
          .listen((snapshot) {
            if (mounted) {
              _updateRecentMatchesStatus(snapshot.docs.isNotEmpty);
            }
          });

      // Listen for recent active matches in real-time
      _chatSubscription = FirebaseFirestore.instance
          .collection('matches')
          .where('users', arrayContains: user.uid)
          .where('status', isEqualTo: 'active')
          .snapshots()
          .listen((snapshot) {
            if (mounted) {
              _checkForRecentMessages(snapshot.docs);
            }
          });
    } catch (e) {
      print('Error setting up real-time listeners: $e');
    }
  }

  void _updateRecentMatchesStatus(bool hasMatches) {
    if (mounted) {
      setState(() {
        _hasRecentMatches = hasMatches;
      });
    }
  }

  void _checkForRecentMessages(List<QueryDocumentSnapshot> matchDocs) {
    if (matchDocs.isEmpty) {
      if (mounted) {
        setState(() {
          _hasRecentMatches = false;
        });
      }
      return;
    }

    // Check for recent active matches only (exclude cancelled/expired matches)
    for (var matchDoc in matchDocs) {
      final matchData = matchDoc.data() as Map<String, dynamic>;
      final status = matchData['status'] as String?;
      final matchedAt = matchData['matchedAt'] as Timestamp?;

      // Only consider active matches for the green indicator
      if (status == 'active' && matchedAt != null) {
        final matchTime = matchedAt.toDate();
        final now = DateTime.now();

        // If match was created in the last 24 hours and is still active, consider it recent
        if (now.difference(matchTime).inHours < 24) {
          if (mounted) {
            setState(() {
              _hasRecentMatches = true;
            });
          }
          return;
        }
      }
    }

    // If no recent active matches found, set to false
    if (mounted) {
      setState(() {
        _hasRecentMatches = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for adaptive sizing
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
          // Using a ListView to make the content scrollable
          child: ListView(
            // Adding BouncingScrollPhysics for a more fluid, iOS-style scroll
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            children: [
              // Top section with notification icon
              SizedBox(height: size.height * 0.02),
              SizedBox(height: size.height * 0.06),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Side Table',
                    style: TextStyle(
                      fontSize: size.width * 0.045, // Adaptive font size
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  _buildNotificationBell(context, size),
                ],
              ),
              SizedBox(height: size.height * 0.015), // Adaptive spacing
              Text(
                'Share a Table, Share a Story',
                // textAlign is removed to inherit start alignment
                style: TextStyle(
                  fontSize: size.width * 0.085, // Adaptive font size
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              SizedBox(height: size.height * 0.06), // Reduced spacing
              _buildInfoCard(size),
              SizedBox(height: size.height * 0.06), // Reduced spacing
              _buildJoinButton(context, size),
              SizedBox(height: size.height * 0.07), // Adaptive spacing
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBell(BuildContext context, Size size) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const MatchProgressScreen()),
        );
      },
      child: Container(
        width: size.width * 0.11,
        height: size.width * 0.11,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(size.width * 0.055),
          border: Border.all(color: const Color(0xFF2C2C2E), width: 1),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.notifications_none_rounded,
                color: Colors.white70,
                size: size.width * 0.055,
              ),
            ),
            // Show indicator dot only when there's actual activity
            if (_hasActiveQueue || (_hasRecentMatches && !_hasActiveQueue))
              Positioned(
                top: size.width * 0.015,
                right: size.width * 0.015,
                child: Container(
                  width: size.width * 0.03,
                  height: size.width * 0.03,
                  decoration: BoxDecoration(
                    color: _hasActiveQueue
                        ? AppColors
                              .systemRed // Red for active queue
                        : const Color(0xFF10B981), // Green for recent matches
                    borderRadius: BorderRadius.circular(size.width * 0.015),
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_hasActiveQueue
                                    ? AppColors.systemRed
                                    : const Color(0xFF10B981))
                                .withOpacity(0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Size size) {
    return Container(
      padding: EdgeInsets.all(size.width * 0.06), // Adaptive padding
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(
          size.width * 0.06,
        ), // Adaptive radius
        border: Border.all(color: const Color(0xFF2C2C2E), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOW IT WORKS',
            style: TextStyle(
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
              fontSize: size.width * 0.032, // Adaptive font size
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: size.height * 0.025), // Adaptive spacing
          _buildStep(
            size,
            icon: Icons.login,
            title: 'Join the Queue',
            subtitle: 'Let us know you\'re heading to the canteen.',
          ),
          SizedBox(height: size.height * 0.025), // Adaptive spacing
          _buildStep(
            size,
            icon: Icons.people_alt_outlined,
            title: 'Get Matched Anonymously',
            subtitle: 'We\'ll pair you with another student.',
          ),
          SizedBox(height: size.height * 0.025), // Adaptive spacing
          _buildStep(
            size,
            icon: Icons.waving_hand_outlined,
            title: 'Say Hi!',
            subtitle: 'Find your match and start a conversation.',
          ),
        ],
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
          width: size.width * 0.1, // Adaptive size
          height: size.width * 0.1, // Adaptive size
          decoration: BoxDecoration(
            color: AppColors.systemRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(
              size.width * 0.03,
            ), // Adaptive radius
          ),
          child: Icon(
            icon,
            color: AppColors.systemRed,
            size: size.width * 0.05,
          ), // Adaptive size
        ),
        SizedBox(width: size.width * 0.04), // Adaptive spacing
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size.width * 0.04, // Adaptive font size
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: size.height * 0.005), // Adaptive spacing
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: size.width * 0.035, // Adaptive font size
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJoinButton(BuildContext context, Size size) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        // Navigate to the TimeSelectionScreen
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const TimeSelectionScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: size.height * 0.025,
        ), // Adaptive padding
        decoration: BoxDecoration(
          color: AppColors.systemRed,
          borderRadius: BorderRadius.circular(
            size.width * 0.045,
          ), // Adaptive radius
          boxShadow: [
            BoxShadow(
              color: AppColors.systemRed.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: -8,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Join a Table',
            style: TextStyle(
              fontSize: size.width * 0.045, // Adaptive font size
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
