import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryBlue = Color(0xFF0066FF);
  static const Color primaryDarkBlue = Color(0xFF004EC2);
  static const Color accentCyan = Color(0xFF00B4D8);

  // Background Gradients
  static const Color bgGradientTop = Color(0xFFE6EEFA);
  static const Color bgGradientMiddle = Color(0xFFD6E4F8);
  static const Color bgGradientBottom = Color(0xFFC5DAF7);
  static const Color surfaceColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Status Badges
  static const Color successGreen = Color(0xFF10B981);
  static const Color successBg = Color(0xFFE6F9F0);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFFFEE2E2);

  // Shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0xFF0F223D).withValues(alpha: 0.06),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF0F223D).withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: primaryBlue.withValues(alpha: 0.35),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static ThemeData get lightTheme {
    final interFont = GoogleFonts.inter().fontFamily;
    return ThemeData(
      useMaterial3: true,
      fontFamily: interFont,
      scaffoldBackgroundColor: surfaceColor,
      primaryColor: primaryBlue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: accentCyan,
        surface: surfaceColor,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(
          fontSize: 14,
          color: textMuted,
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBlue, width: 1.8),
        ),
      ),
    );
  }
}
