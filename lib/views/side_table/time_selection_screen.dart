// FILE: views/side_table/time_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Import for iOS-style switch
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';

import 'match_progress_screen.dart';

// Data model for a time slot to hold the live count
class TimeSlot {
  final String time;
  final int waitingCount;
  final bool isUserWaiting; // New field to track if user is already waiting

  TimeSlot({
    required this.time,
    required this.waitingCount,
    this.isUserWaiting = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSlot &&
          runtimeType == other.runtimeType &&
          time == other.time;

  @override
  int get hashCode => time.hashCode;
}

class TimeSelectionScreen extends StatefulWidget {
  const TimeSelectionScreen({super.key});

  @override
  State<TimeSelectionScreen> createState() => _TimeSelectionScreenState();
}

class _TimeSelectionScreenState extends State<TimeSelectionScreen>
    with TickerProviderStateMixin {
  final List<TimeSlot> _selectedTimes = [];
  late DateTime _now;
  late Timer _timer;
  bool _isTestMode = false;
  bool _isJoiningQueue = false;
  bool _isUserMatched = false; // New field to track if user is already matched
  bool _isLoadingStatus = true; // Track loading state
  bool _matchOnlySameGender = false; // New state for the gender toggle
  late AnimationController _popupAnimationController;
  late AnimationController _scaleAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<TimeSlot> _availableTimes = [
    TimeSlot(time: '10:10 AM', waitingCount: Random().nextInt(5)),
    TimeSlot(time: '12:10 PM', waitingCount: Random().nextInt(15)),
    TimeSlot(time: '03:20 PM', waitingCount: Random().nextInt(8)),
    TimeSlot(time: '05:00 PM', waitingCount: Random().nextInt(3)),
  ];

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });

    // Initialize animation controllers
    _popupAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Create animations with smooth curves
    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _popupAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _popupAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _popupAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Check user's current status
    _checkUserStatus();
  }

  @override
  void dispose() {
    _timer.cancel();
    _popupAnimationController.dispose();
    _scaleAnimationController.dispose();
    super.dispose();
  }

  // New method to check if user is already matched or waiting in queue
  Future<void> _checkUserStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoadingStatus = false;
      });
      return;
    }

    try {
      // Check if user is already matched
      final matchQuery = await FirebaseFirestore.instance
          .collection('matches')
          .where('users', arrayContains: user.uid)
          .where(
            'status',
            isEqualTo: 'active',
          ) // or whatever status indicates active match
          .get();

      if (matchQuery.docs.isNotEmpty) {
        setState(() {
          _isUserMatched = true;
          _isLoadingStatus = false;
        });
        return;
      }

      // Check which time slots user is already waiting for
      final queueQuery = await FirebaseFirestore.instance
          .collection('matchingQueue')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'waiting')
          .get();

      final Set<String> userWaitingTimes = {};
      for (final doc in queueQuery.docs) {
        final data = doc.data();
        userWaitingTimes.add(data['timeSlot'] as String);
      }

      // Update available times with user's waiting status
      setState(() {
        _availableTimes = _availableTimes.map((slot) {
          return TimeSlot(
            time: slot.time,
            waitingCount: slot.waitingCount,
            isUserWaiting: userWaitingTimes.contains(slot.time),
          );
        }).toList();
        _isLoadingStatus = false;
      });
    } catch (e) {
      print('Error checking user status: $e');
      setState(() {
        _isLoadingStatus = false;
      });
    }
  }

  DateTime _parseTime(String time) {
    final format = DateFormat("h:mm a");
    final parsedTime = format.parse(time);
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      parsedTime.hour,
      parsedTime.minute,
    );
  }

  void _toggleTimeSelection(TimeSlot slot) {
    final DateTime slotTime = _parseTime(slot.time);
    final bool isPast = !_isTestMode && _now.isAfter(slotTime);

    // Prevent selection if user is matched, already waiting for this time, or time is past
    if (_isUserMatched || slot.isUserWaiting || isPast) {
      HapticFeedback.heavyImpact();
      _showStatusMessage(slot, isPast);
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedTimes.contains(slot)) {
        _selectedTimes.remove(slot);
      } else {
        _selectedTimes.add(slot);
      }
    });
  }

  // Updated _showStatusMessage to remove specific snackbars
  void _showStatusMessage(TimeSlot? slot, bool isPast) {
    String? message; // Use a nullable string

    // Only create a message if the user is already matched.
    if (_isUserMatched) {
      message = 'You are already matched! Complete your current session first.';
    }
    // For other conditions (isPast, isUserWaiting), the message remains null.

    // Only show a SnackBar if there is a message to display.
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1C1C1E),
          content: Text(message, style: const TextStyle(color: Colors.white)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _toggleTestMode() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isTestMode = !_isTestMode;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1C1C1E),
        content: Text(
          'Developer Mode: ${_isTestMode ? "ON" : "OFF"}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _showConfirmationDialog() {
    // Add haptic feedback for premium feel
    HapticFeedback.mediumImpact();

    // Reset and start animation
    _popupAnimationController.reset();
    _popupAnimationController.forward();

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container(); // Empty container, we'll use transitionBuilder
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              content: AnimatedBuilder(
                animation: _popupAnimationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildPopupContent(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopupContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Success icon with matte background
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.systemRed,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.systemRed.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),

          // Title with better typography
          const Text(
            'You\'re in the queue!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Subtitle with improved readability
          Text(
            'You will be matched with someone and we\'ll notify you when it\'s time to meet.',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Enhanced continue button with matte finish
          Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.systemRed,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.systemRed.withOpacity(0.15),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop(); // Close dialog
                  // NAVIGATE WITHOUT THE UNUSED PARAMETER - USING ORIGINAL NAVIGATION
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MatchProgressScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  alignment: Alignment.center,
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinMatchingQueue() async {
    if (_selectedTimes.isEmpty || _isJoiningQueue || _isUserMatched) return;

    setState(() {
      _isJoiningQueue = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: You are not logged in.')),
      );
      setState(() {
        _isJoiningQueue = false;
      });
      return;
    }

    try {
      final batch = FirebaseFirestore.instance.batch();
      final queueCollection = FirebaseFirestore.instance.collection(
        'matchingQueue',
      );

      for (final slot in _selectedTimes) {
        final docRef = queueCollection.doc();
        batch.set(docRef, {
          'userId': user.uid,
          'timeSlot': slot.time,
          'status': 'waiting',
          'createdAt': FieldValue.serverTimestamp(),
          // ADDED: Include the gender matching preference in the queue data
          'matchPreference': _matchOnlySameGender ? 'same_gender' : 'any',
        });
      }

      await batch.commit();

      if (mounted) {
        setState(() {
          _isJoiningQueue = false;
        });
        _showConfirmationDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to join queue: $e')));
        setState(() {
          _isJoiningQueue = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: GestureDetector(
          onLongPress: _toggleTestMode,
          child: Text(
            'Select Meetup Time',
            style: TextStyle(
              fontSize: size.width * 0.045,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoadingStatus
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.systemRed),
            )
          : _isUserMatched
          ? _buildMatchedUserScreen(size)
          : Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        SizedBox(height: size.height * 0.02),
                        _buildInfoHeader(size),
                        SizedBox(height: size.height * 0.05),
                        _buildSectionTitle('When are you free?', size),
                        SizedBox(height: size.height * 0.01),
                        Text(
                          'Select one or more time slots to join the queue.',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: size.width * 0.038,
                          ),
                        ),
                        SizedBox(height: size.height * 0.03),
                        _buildTimeGrid(size),
                      ],
                    ),
                  ),
                  // ADDED: Gender preference toggle
                  _buildGenderToggle(size),
                  _buildConfirmButton(size),
                  SizedBox(height: size.height * 0.05),
                ],
              ),
            ),
    );
  }

  // NEW WIDGET: For the gender preference toggle
  Widget _buildGenderToggle(Size size) {
    return Padding(
      padding: EdgeInsets.only(bottom: size.height * 0.02),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Match with my gender only',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: size.width * 0.04,
              fontWeight: FontWeight.w500,
            ),
          ),
          CupertinoSwitch(
            value: _matchOnlySameGender,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              setState(() {
                _matchOnlySameGender = value;
              });
            },
            activeColor: AppColors.systemRed,
            trackColor: const Color(0xFF2C2C2E),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchedUserScreen(Size size) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.systemRed,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.systemRed.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.people_rounded,
                color: Colors.white,
                size: 50,
              ),
            ),
            SizedBox(height: size.height * 0.04),
            Text(
              'You\'re Already Matched!',
              style: TextStyle(
                color: Colors.white,
                fontSize: size.width * 0.06,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: size.height * 0.02),
            Text(
              'You have an active match session. Complete your current meetup before joining a new queue.',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: size.width * 0.04,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: size.height * 0.04),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MatchProgressScreen(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: size.height * 0.022),
                decoration: BoxDecoration(
                  color: AppColors.systemRed,
                  borderRadius: BorderRadius.circular(size.width * 0.04),
                ),
                child: Center(
                  child: Text(
                    'Go to Current Match',
                    style: TextStyle(
                      fontSize: size.width * 0.042,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoHeader(Size size) {
    return Container(
      padding: EdgeInsets.all(size.width * 0.05),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(size.width * 0.04),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.security_rounded,
            color: Colors.grey[400],
            size: size.width * 0.08,
          ),
          SizedBox(width: size.width * 0.04),
          Expanded(
            child: Text(
              'All meetups are anonymous. You\'ll be matched with a fellow Sidekicker from campus.',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: size.width * 0.038,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Size size) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white,
        fontSize: size.width * 0.055,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTimeGrid(Size size) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.0,
        crossAxisSpacing: size.width * 0.03,
        mainAxisSpacing: size.width * 0.03,
      ),
      itemCount: _availableTimes.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return _buildTimeChip(_availableTimes[index], size);
      },
    );
  }

  Widget _buildTimeChip(TimeSlot slot, Size size) {
    final bool isSelected = _selectedTimes.contains(slot);
    final DateTime slotTime = _parseTime(slot.time);
    final bool isPast = !_isTestMode && _now.isAfter(slotTime);
    final bool isUserWaiting = slot.isUserWaiting;

    Color backgroundColor;
    Color borderColor;
    Color mainTextColor;
    Color subTextColor;

    if (isPast) {
      backgroundColor = const Color(0xFF1C1C1E);
      borderColor = Colors.transparent;
      mainTextColor = Colors.grey[700]!;
      subTextColor = Colors.grey[800]!;
    } else if (isUserWaiting) {
      backgroundColor = const Color(0xFF2D5016); // Dark green
      borderColor = const Color(0xFF4ADE80); // Light green
      mainTextColor = const Color(0xFF4ADE80);
      subTextColor = const Color(0xFF86EFAC);
    } else if (isSelected) {
      backgroundColor = AppColors.systemRed;
      borderColor = AppColors.systemRed;
      mainTextColor = Colors.white;
      subTextColor = Colors.white70;
    } else {
      backgroundColor = const Color(0xFF1C1C1E);
      borderColor = const Color(0xFF2C2C2E);
      mainTextColor = Colors.grey[300]!;
      subTextColor = Colors.grey[600]!;
    }

    return GestureDetector(
      onTap: () => _toggleTimeSelection(slot),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.04,
          vertical: size.height * 0.015,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(size.width * 0.035),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              slot.time,
              style: TextStyle(
                color: mainTextColor,
                fontSize: size.width * 0.045,
                fontWeight: (isSelected || isUserWaiting)
                    ? FontWeight.bold
                    : FontWeight.w500,
                decoration: isPast
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
            SizedBox(height: size.height * 0.008),
            isPast
                ? Text(
                    'Closed for today',
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: size.width * 0.03,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : isUserWaiting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: subTextColor,
                        size: size.width * 0.035,
                      ),
                      SizedBox(width: size.width * 0.01),
                      Text(
                        'You\'re waiting',
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: size.width * 0.03,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person,
                        color: subTextColor,
                        size: size.width * 0.035,
                      ),
                      SizedBox(width: size.width * 0.01),
                      Text(
                        '${slot.waitingCount} waiting',
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: size.width * 0.03,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  // Updated _buildConfirmButton method to check for past times
  Widget _buildConfirmButton(Size size) {
    // Check if any selected times are past
    final bool hasValidTimes =
        _selectedTimes.isNotEmpty &&
        _selectedTimes.every((slot) {
          final DateTime slotTime = _parseTime(slot.time);
          return _isTestMode || !_now.isAfter(slotTime);
        });

    final bool canConfirm = hasValidTimes && !_isUserMatched;

    String buttonText = 'Select a Time';
    if (_isUserMatched) {
      buttonText = 'Already Matched';
    } else if (_selectedTimes.isNotEmpty && !hasValidTimes) {
      buttonText = 'Selected Times Are Closed';
    } else if (canConfirm) {
      buttonText = 'Enter the Canteen';
    }

    return GestureDetector(
      onTap: (canConfirm && !_isJoiningQueue && !_isUserMatched)
          ? _joinMatchingQueue
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: size.height * 0.022),
        decoration: BoxDecoration(
          color: canConfirm ? AppColors.systemRed : Colors.grey[850],
          borderRadius: BorderRadius.circular(size.width * 0.04),
          boxShadow: !canConfirm
              ? []
              : [
                  BoxShadow(
                    color: AppColors.systemRed.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: -8,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: _isJoiningQueue
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  buttonText,
                  style: TextStyle(
                    fontSize: size.width * 0.042,
                    fontWeight: FontWeight.bold,
                    color: canConfirm ? Colors.white : Colors.grey[600],
                  ),
                ),
        ),
      ),
    );
  }
}
