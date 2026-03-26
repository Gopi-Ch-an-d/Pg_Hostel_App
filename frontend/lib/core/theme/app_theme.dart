import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF1D9E75);
  static const Color primaryLight = Color(0xFFE1F5EE);
  static const Color primaryDark = Color(0xFF085041);
  static const Color accent = Color(0xFF378ADD);
  static const Color warning = Color(0xFFBA7517);
  static const Color warningLight = Color(0xFFFAEEDA);
  static const Color danger = Color(0xFFA32D2D);
  static const Color dangerLight = Color(0xFFFCEBEB);
  static const Color background = Color(0xFFF5F5F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF8F8F6);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color border = Color(0xFFE0E0E0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary, secondary: accent, error: danger, surface: surface),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary, foregroundColor: Colors.white, elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary, side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: border, width: 0.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: GoogleFonts.inter(fontSize: 13, color: textSecondary),
        hintStyle: GoogleFonts.inter(fontSize: 13, color: textTertiary),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 0.5),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface, selectedItemColor: primary, unselectedItemColor: textTertiary, elevation: 0,
      ),
    );
  }

  static Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID': return primary;
      case 'PENDING': return warning;
      case 'OVERDUE': return danger;
      case 'RESOLVED': return primary;
      case 'IN_PROGRESS': return warning;
      case 'OCCUPIED': return danger;
      case 'AVAILABLE': return primary;
      case 'PARTIAL': return warning;
      default: return textSecondary;
    }
  }

  static Color statusBgColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID': case 'RESOLVED': case 'AVAILABLE': return primaryLight;
      case 'PENDING': case 'IN_PROGRESS': case 'PARTIAL': return warningLight;
      case 'OVERDUE': case 'OCCUPIED': return dangerLight;
      default: return background;
    }
  }
}
