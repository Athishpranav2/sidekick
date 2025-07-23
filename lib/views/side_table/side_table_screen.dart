// FILE: views/side_table/side_table_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'time_selection_screen.dart'; // Import the new screen

class SideTableScreen extends StatelessWidget {
  const SideTableScreen({super.key});

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
              // Using SizedBox for spacing instead of Spacer
              SizedBox(height: size.height * 0.08), // Reduced top spacing
              Text(
                'Side Table',
                style: TextStyle(
                  fontSize: size.width * 0.045, // Adaptive font size
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
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
            color: const Color(0xFFDC2626).withOpacity(0.1),
            borderRadius: BorderRadius.circular(
              size.width * 0.03,
            ), // Adaptive radius
          ),
          child: Icon(
            icon,
            color: const Color(0xFFDC2626),
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
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(
            size.width * 0.045,
          ), // Adaptive radius
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDC2626).withOpacity(0.4),
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
