// FILE: views/side_table/matched_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MatchedScreen extends StatefulWidget {
  final Map<String, dynamic> matchData;
  const MatchedScreen({super.key, required this.matchData});

  @override
  State<MatchedScreen> createState() => _MatchedScreenState();
}

class _MatchedScreenState extends State<MatchedScreen> {
  bool _isRevealed = false;

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  void _revealColor() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isRevealed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final String timeSlot = widget.matchData['timeSlot'] ?? 'the canteen';
    final Color revealColor = _hexToColor(
      widget.matchData['revealColor'] ?? '#FFFFFF',
    );

    return Scaffold(
      backgroundColor: _isRevealed ? revealColor : Colors.black,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
          child: _isRevealed
              ? _buildRevealedState(size, revealColor)
              : _buildInitialState(size, timeSlot),
        ),
      ),
    );
  }

  Widget _buildInitialState(Size size, String timeSlot) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Icon(
          Icons.check_circle_outline_rounded,
          color: Colors.green,
          size: size.width * 0.2,
        ),
        SizedBox(height: size.height * 0.04),
        Text(
          'You\'ve been matched!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: size.width * 0.08,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: size.height * 0.02),
        Text(
          'Head to the canteen for your $timeSlot meetup. When you think you\'ve found your match, tap the button below to sync up.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: size.width * 0.045,
            color: Colors.grey[400],
            height: 1.5,
          ),
        ),
        const Spacer(),
        _buildRevealButton(size),
        SizedBox(height: size.height * 0.05),
      ],
    );
  }

  Widget _buildRevealedState(Size size, Color revealColor) {
    // Determine if the color is light or dark to set the text color
    final bool isColorLight = revealColor.computeLuminance() > 0.5;
    final Color textColor = isColorLight ? Colors.black87 : Colors.white;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Icon(
          Icons.visibility_rounded,
          color: textColor.withOpacity(0.8),
          size: size.width * 0.2,
        ),
        SizedBox(height: size.height * 0.04),
        Text(
          'Look for this color!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: size.width * 0.08,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        SizedBox(height: size.height * 0.02),
        Text(
          'Hold up your phone and find the other person with the same color screen.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: size.width * 0.045,
            color: textColor.withOpacity(0.8),
            height: 1.5,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () {
            // TODO: Implement logic to end the match and go back home
            Navigator.of(context).pop();
          },
          child: Text(
            'End Match',
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontSize: size.width * 0.04,
            ),
          ),
        ),
        SizedBox(height: size.height * 0.05),
      ],
    );
  }

  Widget _buildRevealButton(Size size) {
    return GestureDetector(
      onTap: _revealColor,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: size.height * 0.025),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(size.width * 0.045),
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
            'Reveal Sync Color',
            style: TextStyle(
              fontSize: size.width * 0.045,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
