import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF407056); // Main Green
  static const Color primaryLight = Color(0x4D407056); // Light Green
  static const Color background = Color(0xFFF8F8F8); // Light Gray
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA000);
  static const Color info = Color(0xFF29B6F6);
  static const Color error = Color(0xFFF44336);

  // Role Based Colors (example)
  static const Color admin = Color(0xFF673AB7);
  static const Color estimation = Color(0xFF009688);
  static const Color accounts = Color(0xFFFF5722);
  static const Color store = Color(0xFF3F51B5);
  static const Color production = Color(0xFF795548);
  static const Color delivery = Color(0xFF607D8B);
  static const Color marketing = Color(0xFFE91E63);
  static const Color sales = Color(0xFF2196F3);

  // Text Colors
  static const Color textPrimary = Color(0xFF222222);
  static const Color textSecondary = Color(0xFF757575);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  // Others
  static const Color border = Color(0xFFE0E0E0);

  // Shadows for cards or panels
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
  ];
}
