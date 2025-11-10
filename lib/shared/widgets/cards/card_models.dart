import 'package:flutter/material.dart';

/// Data model for dashboard statistics cards
class DashboardCardData {
  final String title;
  final String count;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const DashboardCardData({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

/// Helper class for responsive card sizing
class ResponsiveCardSize {
  static double getCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      // Mobile: 180px width
      return 180;
    } else if (screenWidth < 900) {
      // Small tablet: 200px
      return 200;
    } else {
      // Desktop/large tablet: 220px
      return 220;
    }
  }

  static double getCardHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      // Mobile: 120px height
      return 120;
    } else if (screenWidth < 900) {
      // Small tablet: 130px
      return 130;
    } else {
      // Desktop/large tablet: 140px
      return 140;
    }
  }

  static double getCardSpacing() {
    // Space between cards: 16px
    return 16;
  }
}
