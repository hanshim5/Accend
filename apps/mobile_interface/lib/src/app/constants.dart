import 'package:flutter/material.dart';

/// Design tokens + shared app constants.
/// Keep "source of truth" colors/spacing here.
/// Widgets should NOT hardcode colors—pull from Theme.of(context) instead.
class AppColors {
  // Primary background: #0E172A (Deep Midnight)
  static const primaryBg = Color(0xFF0E172A);

  // Card & Surface: #1E293B (Slate Navy)
  static const surface = Color(0xFF1E293B);

  // Primary Accent: #06B6D4 (Ocean)
  static const accent = Color(0xFF06B6D4);

  // Secondary Accent: #38BDF8 (Sky Blue)
  static const accent2 = Color(0xFF38BDF8);

  // Success: #4ADE80 (Vibrant Mint)
  static const success = Color(0xFF4ADE80);

  // Text (Primary): #F8FAFC (Arctic White)
  static const textPrimary = Color(0xFFF8FAFC);

  // Text (Secondary): #94A3B8 (Cool Grey)
  static const textSecondary = Color(0xFF94A3B8);

  // Action Highlight: #F6B17A (Sunset Orange)
  static const action = Color(0xFFF6B17A);

  // Failures: #E5484D (Crimson Red)
  static const failure = Color(0xFFE5484D);

  // Tip (tinted): #8FA8FC
  static const tip = Color(0xFF8FA8FC);

  // Practical extras for UI components
  static const border = Color(0xFF24344D);
  static const inputFill = Color(0xFF121F35);
}

class AppSpacing {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
}

class AppRadii {
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 16;
}

/// App-wide strings & asset paths.
/// (Keep this minimal for now; expand as needed.)
class AppStrings {
  static const appName = 'Accend';
}

/// Supabase Storage bucket names and path helpers.
class AppStorage {
  static const phonemeBucket = 'phoneme-audio';

  /// Returns the storage path for a phoneme audio clip, e.g. "iy.m4a".
  static String phonemeAudioPath(String symbol) => '${symbol.toLowerCase()}.m4a';
}