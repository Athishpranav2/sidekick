import 'package:flutter/material.dart';

class FilterButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterButton({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 36, // Fixed height for consistent alignment
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // px-12 py-6 as specified
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFAA1C1C) : Colors.transparent,
          borderRadius: BorderRadius.circular(24), // 24px border radius as specified
          border: Border.all(
            color: isSelected ? const Color(0xFFAA1C1C) : Colors.white.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFFAA1C1C).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Center( // Center the text properly
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(isSelected ? 1.0 : 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center, // Ensure text is centered
          ),
        ),
      ),
    );
  }
}