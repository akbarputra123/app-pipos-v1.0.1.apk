import 'package:flutter/material.dart';

// =============================
// WARNA KONSTAN (LEGACY – JANGAN DIHAPUS)
// =============================
class AppColors {
  // Brand
  static const Color primary = Color(0xFFE43636);
  static const Color primaryHover = Color(0xFFD32F2F);
  static const Color primaryDark = Color(0xFFB71C1C);

  // Backgrounds (DARK DEFAULT)
  static const Color background = Color(0xFF0B0B0B);
  static const Color sidebar = Color(0xFF121212);
  static const Color card = Color(0xFF161212);
  static const Color cardSoft = Color(0xFF1C1616);

  // Text
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFBDBDBD);
  static const Color textMuted = Color(0xFF8A8A8A);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color danger = Color(0xFFE53935);

  // Input
  static const Color inputBg = Color(0xFF1F1A1A);
  static const Color border = Color(0xFF2C1F1F);
}

// ===================================================
// 🌙 DARK THEME (DEFAULT PROJECT KAMU)
// ===================================================
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,

  scaffoldBackgroundColor: AppColors.background,
  cardColor: AppColors.card,
  dividerColor: AppColors.border,

  colorScheme: ColorScheme.dark(
    primary: AppColors.primary,
    secondary: AppColors.warning,
    background: AppColors.background,
    surface: AppColors.card,
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onBackground: AppColors.textPrimary,
    onSurface: AppColors.textPrimary,
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
  ),

  cardTheme: CardThemeData(
    color: AppColors.card,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: AppColors.border),
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.inputBg,
    labelStyle: const TextStyle(color: AppColors.textSecondary),
    hintStyle: const TextStyle(color: AppColors.textMuted),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  ),

  textTheme: const TextTheme(
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
    bodyLarge: TextStyle(fontSize: 14, color: AppColors.textPrimary),
    bodyMedium: TextStyle(fontSize: 13, color: AppColors.textSecondary),
    bodySmall: TextStyle(fontSize: 12, color: AppColors.textMuted),
  ),

  iconTheme: const IconThemeData(
    color: AppColors.textSecondary,
    size: 20,
  ),
);

// ===================================================
// ☀️ LIGHT THEME (BARU – UNTUK TOGGLE)
// ===================================================
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,

  scaffoldBackgroundColor: const Color(0xFFF7F7F7),
  cardColor: Colors.white,
  dividerColor: Colors.grey.shade300,

  colorScheme: ColorScheme.light(
    primary: AppColors.primary,
    secondary: AppColors.warning,
    background: Colors.white,
    surface: Colors.white,
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onBackground: Colors.black,
    onSurface: Colors.black,
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0,
  ),

  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Colors.grey.shade300),
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey.shade100,
    labelStyle: const TextStyle(color: Colors.black54),
    hintStyle: const TextStyle(color: Colors.black45),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  ),

  textTheme: const TextTheme(
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    bodyLarge: TextStyle(fontSize: 14, color: Colors.black),
    bodyMedium: TextStyle(fontSize: 13, color: Colors.black87),
    bodySmall: TextStyle(fontSize: 12, color: Colors.black54),
  ),

  iconTheme: const IconThemeData(
    color: Colors.black54,
    size: 20,
  ),
);
