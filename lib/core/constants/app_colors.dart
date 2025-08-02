import 'package:flutter/material.dart';

/// iOS Native Premium Design System - Twitter-inspired
/// Sophisticated dark theme with proper iOS aesthetics
class AppColors {
  // Primary brand colors - softer red for better Android experience
  static const Color primary = Color(0xFFE53E3E); // Softer red
  static const Color primaryLight = Color(0xFFF56565); // Lighter soft red
  static const Color primaryDark = Color(0xFFC53030); // Darker soft red

  // iOS Dark theme backgrounds
  static const Color background = Color(0xFF000000); // Pure black
  static const Color secondaryBackground = Color(0xFF1C1C1E); // iOS secondary
  static const Color tertiaryBackground = Color(0xFF2C2C2E); // iOS tertiary
  static const Color groupedBackground = Color(0xFF000000); // iOS grouped

  // iOS card and surface colors - Ultra dark for premium look
  static const Color cardBackground = Color(0xFF0A0A0A); // Ultra dark card
  static const Color elevatedBackground = Color(
    0xFF1A1A1A,
  ); // Elevated surfaces

  // iOS text colors - proper hierarchy
  static const Color textPrimary = Color(0xFFFFFFFF); // Primary text
  static const Color textSecondary = Color(0xFF8E8E93); // Secondary text
  static const Color textTertiary = Color(0xFF48484A); // Tertiary text
  static const Color textQuaternary = Color(0xFF2C2C2E); // Quaternary text

  // iOS semantic colors
  static const Color systemRed = Color(0xFFE53E3E); // Softer red
  static const Color systemBlue = Color(0xFF007AFF);
  static const Color systemGreen = Color(0xFF34C759);
  static const Color systemOrange = Color(0xFFFF9500);
  static const Color systemYellow = Color(0xFFFFCC00);
  static const Color systemPurple = Color(0xFFAF52DE);

  // iOS borders and separators - Ultra subtle for dark cards
  static const Color separator = Color(0xFF1A1A1A); // Ultra subtle separator
  static const Color opaqueSeparator = Color(
    0xFF2A2A2A,
  ); // Subtle opaque separator

  // iOS interactive states
  static const Color link = Color(0xFF007AFF); // iOS link blue
  static const Color destructive = Color(0xFFE53E3E); // Softer destructive red

  // Shadows and elevation - Enhanced for ultra premium look
  static const Color shadow = Color(0x40000000); // Enhanced shadow
  static const Color shadowLight = Color(0x20000000); // Light shadow
  static const Color shadowHeavy = Color(0x60000000); // Ultra heavy shadow
  static const Color shadowUltra = Color(0x80000000); // Ultra premium shadow
}

/// iOS Native Typography System - SF Pro Display
class AppTypography {
  // iOS system font
  static const String systemFont = '.SF Pro Display';

  // iOS Large Title (iOS 11+)
  static const TextStyle largeTitle = TextStyle(
    fontFamily: systemFont,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
    height: 1.12,
  );

  // iOS Title 1
  static const TextStyle title1 = TextStyle(
    fontFamily: systemFont,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
    height: 1.14,
  );

  // iOS Title 2
  static const TextStyle title2 = TextStyle(
    fontFamily: systemFont,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
    height: 1.18,
  );

  // iOS Title 3 - for navigation titles
  static const TextStyle title3 = TextStyle(
    fontFamily: systemFont,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  // iOS Headline
  static const TextStyle headline = TextStyle(
    fontFamily: systemFont,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
    height: 1.29,
  );

  // iOS Body - main content text
  static const TextStyle body = TextStyle(
    fontFamily: systemFont,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
    height: 1.29,
  );

  // iOS Callout
  static const TextStyle callout = TextStyle(
    fontFamily: systemFont,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
    height: 1.31,
  );

  // iOS Subheadline
  static const TextStyle subheadline = TextStyle(
    fontFamily: systemFont,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
    height: 1.33,
  );

  // iOS Footnote
  static const TextStyle footnote = TextStyle(
    fontFamily: systemFont,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
    color: AppColors.textSecondary,
    height: 1.38,
  );

  // iOS Caption 1
  static const TextStyle caption1 = TextStyle(
    fontFamily: systemFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textSecondary,
    height: 1.33,
  );

  // iOS Caption 2
  static const TextStyle caption2 = TextStyle(
    fontFamily: systemFont,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    color: AppColors.textTertiary,
    height: 1.36,
  );
}

/// iOS Native Spacing System - Human Interface Guidelines
class AppSpacing {
  // iOS standard spacing values
  static const double xs = 4.0; // Minimal spacing
  static const double sm = 8.0; // Small spacing
  static const double md = 12.0; // Medium spacing
  static const double lg = 16.0; // Large spacing (iOS standard)
  static const double xl = 20.0; // Extra large spacing
  static const double xxl = 24.0; // Double extra large
  static const double xxxl = 32.0; // Triple extra large

  // iOS layout margins
  static const double layoutMargin = 20.0; // iOS standard layout margin
  static const double readableMargin = 20.0; // Readable content margin
  static const double systemSpacing = 8.0; // iOS system spacing

  // iOS component sizing
  static const double navigationBarHeight = 44.0; // iOS nav bar
  static const double tabBarHeight = 49.0; // iOS tab bar
  static const double toolBarHeight = 44.0; // iOS toolbar
  static const double searchBarHeight = 36.0; // iOS search bar
  static const double buttonHeight = 44.0; // iOS button minimum
  static const double cellHeight = 44.0; // iOS table cell minimum

  // Avatar and profile images
  static const double avatarSmall = 30.0;
  static const double avatarMedium = 40.0;
  static const double avatarLarge = 60.0;

  // iOS corner radius values
  static const double radiusSmall = 8.0; // Small corners
  static const double radiusMedium = 12.0; // Medium corners
  static const double radiusLarge = 16.0; // Large corners
  static const double radiusButton = 10.0; // iOS button radius
  static const double radiusCard = 12.0; // Card radius

  // Shadow and elevation
  static const double shadowOffset = 2.0;
  static const double shadowBlur = 8.0;
  static const double shadowSpread = 0.0;
}

/// iOS Native Animations - UIKit-inspired
class AppAnimations {
  // iOS standard durations
  static const Duration fast = Duration(milliseconds: 200); // Quick animations
  static const Duration medium = Duration(milliseconds: 300); // Standard
  static const Duration slow = Duration(milliseconds: 500); // Slow animations

  // iOS spring animations
  static const Duration spring = Duration(milliseconds: 400); // Spring duration
  static const Duration bounce = Duration(milliseconds: 600); // Bounce duration

  // iOS curves - matches UIKit animations
  static const Curve ease = Curves.easeInOut; // Standard ease
  static const Curve easeIn = Curves.easeIn; // Ease in
  static const Curve easeOut = Curves.easeOut; // Ease out
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn; // Material curve
  static const Curve springCurve = Curves.elasticOut; // Spring curve
}
