import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // Brand — corporate navy
  static const primary = Color(0xFF14315E);
  static const primaryLight = Color(0xFF1E4A8A);
  static const primarySurface = Color(0xFFE8EEF7);

  // Navigation
  static const navBg = Color(0xFF0D1B2A);

  // Backgrounds
  static const background = Color(0xFFF4F6FA);
  static const surface = Colors.white;
  static const surfaceVariant = Color(0xFFF0F4F9);

  // Text
  static const textPrimary = Color(0xFF0D1B2A);
  static const textSecondary = Color(0xFF4A5568);
  static const textMuted = Color(0xFF94A3B8);

  // Border
  static const border = Color(0xFFE2E8F0);
  static const borderFocus = Color(0xFF14315E);

  // Semantic
  static const success = Color(0xFF16A34A);
  static const successLight = Color(0xFFF0FDF4);
  static const warning = Color(0xFFD97706);
  static const warningLight = Color(0xFFFFF7ED);
  static const error = Color(0xFFDC2626);
  static const errorLight = Color(0xFFFEF2F2);
  static const info = Color(0xFF0284C7);
  static const infoLight = Color(0xFFF0F9FF);

  // Status chip colors
  static const statusAvailableBg = Color(0xFFF0FDF4);
  static const statusAvailableText = Color(0xFF16A34A);
  static const statusBlockedBg = Color(0xFFFFFBEB);
  static const statusBlockedText = Color(0xFFD97706);
  static const statusOccupiedBg = Color(0xFFFEF2F2);
  static const statusOccupiedText = Color(0xFFDC2626);
  static const statusPendingBg = Color(0xFFFFF7ED);
  static const statusPendingText = Color(0xFFD97706);
  static const statusConfirmedBg = Color(0xFFF0FDF4);
  static const statusConfirmedText = Color(0xFF16A34A);
  static const statusRejectedBg = Color(0xFFFEF2F2);
  static const statusRejectedText = Color(0xFFDC2626);
  static const statusCompletedBg = Color(0xFFF0FDF4);
  static const statusCompletedText = Color(0xFF16A34A);
  static const statusPaidBg = Color(0xFFF0FDF4);
  static const statusPaidText = Color(0xFF16A34A);
  static const statusCancelledBg = Color(0xFFF0F4F9);
  static const statusCancelledText = Color(0xFF4A5568);
  static const statusMaintenanceBg = Color(0xFFF0F9FF);
  static const statusMaintenanceText = Color(0xFF0284C7);

  // Nav bar
  static const navUnselected = Color(0xFF6B7B8D);
  static const navBorderTop = Color(0xFF1E2D3D);
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get pageTitle => GoogleFonts.inter(
      fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary);

  static TextStyle get sectionTitle => GoogleFonts.inter(
      fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  static TextStyle get cardTitle => GoogleFonts.inter(
      fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  static TextStyle get bodyMedium => GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary);

  static TextStyle get bodySmall => GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary);

  static TextStyle get labelMedium => GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary);

  static TextStyle get tableText => GoogleFonts.inter(
      fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textPrimary);

  static TextStyle get tableHeader => GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
      letterSpacing: 0.5);

  static TextStyle get metricValue => GoogleFonts.inter(
      fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.2);

  static TextStyle get metricLabel => GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted, height: 1.2);

  static TextStyle get buttonText =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500);

  static TextStyle get caption => GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textMuted);

  static TextStyle get label => GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
      letterSpacing: 0.5);
}

class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        surface: AppColors.surface,
        surfaceContainerHighest: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.inter().fontFamily,
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.borderFocus, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle:
            GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
        hintStyle:
            GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      dividerTheme: const DividerThemeData(
          color: AppColors.border, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
    );
  }
}
