import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MatchProgressController {
  // --- Dependencies & State ---
  final TickerProvider vsync;
  final VoidCallback onStateChanged;
  late final BuildContext _context;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  User? user;
  bool isLoading = true;

  // --- Animation ---
  late AnimationController pulseController;
  late Animation<double> pulseAnimation;
  late AnimationController fadeController;
  late Animation<double> fadeAnimation;

  // --- Constructor ---
  MatchProgressController({required this.vsync, required this.onStateChanged});

  // --- Initialization & Disposal ---

  /// Initializes the controller, gets the current user, and sets up animations.
  void initialize(BuildContext context) {
    _context = context;
    user = _auth.currentUser;
    _setupAnimations();
    _loadData();
  }

  /// Sets up all the necessary animation controllers.
  void _setupAnimations() {
    pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: vsync,
    )..repeat(reverse: true); // Start pulsing animation immediately
    pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: pulseController, curve: Curves.easeInOut),
    );

    fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: vsync,
    );
    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: fadeController, curve: Curves.easeOut));
  }

  /// Simulates an initial data load, then updates the state and starts animations.
  Future<void> _loadData() async {
    await Future.delayed(const Duration(milliseconds: 400));
    isLoading = false;
    onStateChanged(); // Notify the UI to rebuild
    fadeController.forward();
  }

  /// Disposes of animation controllers to prevent memory leaks.
  void dispose() {
    pulseController.dispose();
    fadeController.dispose();
  }

  // --- Firestore Streams ---

  /// Stream for the user's current 'waiting' status in the queue.
  Stream<QuerySnapshot> get queueStatusStream {
    if (user == null) return Stream.empty();
    return _firestore
        .collection('matchingQueue')
        .where('userId', isEqualTo: user!.uid)
        .where('status', isEqualTo: 'waiting')
        .snapshots();
  }

  /// Stream for the user's most recent 'active' match.
  Stream<QuerySnapshot> get activeMatchStream {
    if (user == null) return Stream.empty();
    return _firestore
        .collection('matches')
        .where('users', arrayContains: user!.uid)
        .where('status', isEqualTo: 'active')
        .orderBy('matchedAt', descending: true)
        .limit(1)
        .snapshots();
  }

  /// Stream for all queues the user is currently in.
  Stream<QuerySnapshot> get activeQueueStream {
    if (user == null) return Stream.empty();
    return _firestore
        .collection('matchingQueue')
        .where('userId', isEqualTo: user!.uid)
        .where('status', isEqualTo: 'waiting')
        .snapshots();
  }

  /// Stream for all 'active' matches for the current user.
  Stream<QuerySnapshot> get allActiveMatchesStream {
    if (user == null) return Stream.empty();
    return _firestore
        .collection('matches')
        .where('users', arrayContains: user!.uid)
        .where('status', isEqualTo: 'active')
        .orderBy('matchedAt', descending: true)
        .snapshots();
  }

  /// Stream for recent matches (last 3 days) that are completed or cancelled.
  Stream<QuerySnapshot> get recentMatchesStream {
    if (user == null) return Stream.empty();
    final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
    return _firestore
        .collection('matches')
        .where('users', arrayContains: user!.uid)
        .where(
          'matchedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(threeDaysAgo),
        )
        .where('status', whereIn: ['completed', 'cancelled'])
        .orderBy('matchedAt', descending: true)
        .limit(10)
        .snapshots();
  }

  // --- Public Methods ---

  /// Fetches a user's profile data from Firestore.
  Future<DocumentSnapshot> getUserDetails(String userId) {
    return _firestore.collection('users').doc(userId).get();
  }

  /// Cancels a user's entry in the matching queue.
  Future<void> cancelQueue(String docId) async {
    HapticFeedback.mediumImpact();

    try {
      await _firestore.collection('matchingQueue').doc(docId).delete();

      ScaffoldMessenger.of(_context).showSnackBar(
        SnackBar(
          content: const Text('Queue cancelled'),
          backgroundColor: const Color(0xFF2C2C2E), // secondaryCardColor
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(_context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel queue: $e'),
          backgroundColor: const Color(0xFFFF3B30), // primaryRed
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        ),
      );
    }
  }

  /// **[NEW]** Cancels an active match by updating its status.
  Future<void> cancelMatch(String matchId) async {
    HapticFeedback.mediumImpact();

    try {
      await _firestore.collection('matches').doc(matchId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(_context).showSnackBar(
        SnackBar(
          content: const Text('Match cancelled'),
          backgroundColor: const Color(0xFF2C2C2E), // secondaryCardColor
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(_context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel match: $e'),
          backgroundColor: const Color(0xFFFF3B30), // primaryRed
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        ),
      );
    }
  }

  /// Utility function to format a DateTime into a relative time string (e.g., "5m", "2h").
  String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}
