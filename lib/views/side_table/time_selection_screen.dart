// FILE: views/side_table/time_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math'; // For generating mock data

// Data model for a time slot to hold the live count
class TimeSlot {
  final String time;
  final int waitingCount;

  TimeSlot({required this.time, required this.waitingCount});

  // Override for proper comparison in the List
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
  // Use a List to store multiple selected times
  final List<TimeSlot> _selectedTimes = [];

  // Mock data for available time slots with live counts
  final List<TimeSlot> _availableTimes = [
    TimeSlot(
      time: '10:10 AM',
      waitingCount: Random().nextInt(5),
    ), // Generates a random number 0-4
    TimeSlot(
      time: '12:10 PM',
      waitingCount: Random().nextInt(15),
    ), // More popular time
    TimeSlot(time: '03:20 PM', waitingCount: Random().nextInt(8)),
    TimeSlot(time: '05:00 PM', waitingCount: Random().nextInt(3)),
  ];

  // Toggle selection logic
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
        title: Text(
          'Select Meetup Time',
          style: TextStyle(
            fontSize: size.width * 0.045,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      // Using a Column with an Expanded ListView to fix overflow issues
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
            // The button is now outside the scrollable area, preventing overflow
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
        // Vertically center the icon and text
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
    return GestureDetector(
      onTap: () => _toggleTimeSelection(slot),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.04,
          vertical: size.height * 0.015,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDC2626) : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(size.width * 0.035),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFDC2626)
                : const Color(0xFF2C2C2E),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              slot.time,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[300],
                fontSize: size.width * 0.045,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            SizedBox(height: size.height * 0.008),
            // The new "live count" indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person,
                  color: isSelected ? Colors.white70 : Colors.grey[600],
                  size: size.width * 0.035,
                ),
                SizedBox(width: size.width * 0.01),
                Text(
                  '${slot.waitingCount} waiting',
                  style: TextStyle(
                    color: isSelected ? Colors.white70 : Colors.grey[600],
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

    // Changed button text for a more engaging feel
    String buttonText = 'Select a Time';
    if (canConfirm) {
      buttonText = 'Enter the Canteen';
    }

    return GestureDetector(
      onTap: canConfirm
          ? () {
              // TODO: Implement logic to enter the matching queue with selected times
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: size.height * 0.022,
        ), // Reduced padding
        decoration: BoxDecoration(
          color: canConfirm ? const Color(0xFFDC2626) : Colors.grey[850],
          borderRadius: BorderRadius.circular(
            size.width * 0.04,
          ), // Adjusted radius
          boxShadow: !canConfirm
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: -8,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            buttonText,
            style: TextStyle(
              fontSize: size.width * 0.042, // Adjusted font size
              fontWeight: FontWeight.bold,
              color: canConfirm ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}
