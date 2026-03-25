import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Semantic Colors
  static const Color primaryTeal = Color(0xFF0F766E);
  static const Color accentTerracotta = Color(0xFFDD6B20);
  static const Color bgOffWhite = Color(0xFFF7F5F0);
  static const Color textCharcoal = Color(0xFF1E293B);
  
  static const Color statusError = Color(0xFFDC2626); // Deep Crimson
  static const Color statusWarning = Color(0xFFD97706); // Amber
  static const Color statusSuccess = Color(0xFF059669); // Emerald Green

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgOffWhite,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        primary: primaryTeal,
        secondary: accentTerracotta,
        surface: Colors.white,
        background: bgOffWhite,
        error: statusError,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textCharcoal,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentTerracotta,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 60), // Large touch targets
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 60),
          side: const BorderSide(color: textCharcoal, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(20), // Large touch targets
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: textCharcoal, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black26, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryTeal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: statusError, width: 2),
        ),
      ),
      textTheme: TextTheme(
        titleLarge: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: textCharcoal),
        titleMedium: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: textCharcoal),
        bodyLarge: GoogleFonts.inter(fontSize: 18, color: textCharcoal),
        bodyMedium: GoogleFonts.inter(fontSize: 16, color: textCharcoal),
      ),
    );
  }
}
