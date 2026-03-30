// lib/utils/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF1B8A2E);      // Deep Green (nature/agro)
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color secondary = Color(0xFFFF6F00);    // Amber/Orange (fun/water)
  static const Color accent = Color(0xFF0288D1);       // Blue (water)
  static const Color background = Color(0xFFF5F9F5);
  static const Color surface = Colors.white;
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A2E1A);
  static const Color textMedium = Color(0xFF4A6741);
  static const Color textLight = Color(0xFF8BAF88);
  static const Color danger = Color(0xFFE53935);
  static const Color gold = Color(0xFFFFC107);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      surface: surface,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FCF8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardBg,
    ),
  );
}

class AppStrings {
  static const String appName = 'Janki Agro Tourism';
  static const String tagline = 'निसर्ग रम्य आनंद यात्रा';
}
