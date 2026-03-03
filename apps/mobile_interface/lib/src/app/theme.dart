import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);

    final headingFont = GoogleFonts.inter();
    final bodyFont = GoogleFonts.publicSans();

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.primaryBg,

      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: AppColors.accent,
        secondary: AppColors.accent2,
        surface: AppColors.surface,
        error: AppColors.failure,
      ),

      textTheme: TextTheme(
        // Headings (Inter)
        headlineLarge: headingFont.copyWith(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          height: 1.05,
        ),
        headlineMedium: headingFont.copyWith(
          color: AppColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          height: 1.05,
        ),
        titleMedium: headingFont.copyWith(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),

        // Body (Public Sans)
        bodyLarge: bodyFont.copyWith(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: bodyFont.copyWith(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        hintStyle: bodyFont.copyWith(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        labelStyle: bodyFont.copyWith(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        errorStyle: bodyFont.copyWith(
          color: AppColors.failure,
          fontSize: 12,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide:
              const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide:
              const BorderSide(color: AppColors.failure),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.action,
          foregroundColor: const Color(0xFF101828),
          textStyle: headingFont.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}