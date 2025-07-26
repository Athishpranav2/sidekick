// FILE: views/side_table/time_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'match_progress_screen.dart';

// Data model for a time slot to hold the live count
class TimeSlot {
  final String time;
  final int waitingCount;

  TimeSlot({required this.time, required this.waitingCount});

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

class _TimeSelectionScreenState extends State<TimeSelectionScreen> {
  final List<TimeSlot> _selectedTimes = [];
  late DateTime _now;
  late Timer _timer;
  bool _isTestMode = false;
  bool _isJoiningQueue = false;

  final List<TimeSlot> _availableTimes = [
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
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
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
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedTimes.contains(slot)) {
        _selectedTimes.remove(slot);
      } else {
        _selectedTimes.add(slot);
      }
    });
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 20),
              const Text(
                'You\'re in the queue!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'You will be matched with someone and we\'ll notify you when it\'s time to meet.',
                style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    // NAVIGATE WITHOUT THE UNUSED PARAMETER
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MatchProgressScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _joinMatchingQueue() async {
    if (_selectedTimes.isEmpty || _isJoiningQueue) return;

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
      body: Padding(
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
            _buildConfirmButton(size),
            SizedBox(height: size.height * 0.05),
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

    Color backgroundColor = isSelected
        ? const Color(0xFFDC2626)
        : const Color(0xFF1C1C1E);
    Color borderColor = isSelected
        ? const Color(0xFFDC2626)
        : const Color(0xFF2C2C2E);
    Color mainTextColor = isSelected ? Colors.white : Colors.grey[300]!;
    Color subTextColor = isSelected ? Colors.white70 : Colors.grey[600]!;

    if (isPast) {
      backgroundColor = const Color(0xFF1C1C1E);
      borderColor = Colors.transparent;
      mainTextColor = Colors.grey[700]!;
      subTextColor = Colors.grey[800]!;
    }

    return GestureDetector(
      onTap: isPast ? null : () => _toggleTimeSelection(slot),
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
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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

  Widget _buildConfirmButton(Size size) {
    final bool canConfirm = _selectedTimes.isNotEmpty;
    String buttonText = 'Select a Time';
    if (canConfirm) {
      buttonText = 'Enter the Canteen';
    }

    return GestureDetector(
      onTap: canConfirm && !_isJoiningQueue ? _joinMatchingQueue : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: size.height * 0.022),
        decoration: BoxDecoration(
          color: canConfirm ? const Color(0xFFDC2626) : Colors.grey[850],
          borderRadius: BorderRadius.circular(size.width * 0.04),
          boxShadow: !canConfirm
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withOpacity(0.4),
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
