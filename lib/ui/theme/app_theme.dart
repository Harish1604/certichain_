// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF6A5AE0); // Purple
  static const Color secondaryColor = Color(0xFF8E82F9);
  static const Color backgroundColor = Color(0xFF0A0E21);

  static ThemeData get theme {
    return ThemeData(
      scaffoldBackgroundColor: primaryColor,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
    );
  }
}
