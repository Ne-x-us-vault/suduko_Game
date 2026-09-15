import 'package:flutter/material.dart';

/// Color palette for Gridline Sudoku
class AppColors {
  static const Color ivory = Color(0xFFFFF8E7);
  static const Color graphite = Color(0xFF2A2A2E);
  static const Color teal = Color(0xFF006D77);
  static const Color coral = Color(0xFFF08080);
  static const Color gold = Color(0xFFFFD700);
  static const Color gridLine = Color(0xFFB0B0B0);
  static const Color cellSurface = Color(0xFFFFFFFF);
  static const Color errorBackground = Color(0xFFFFF0F0);
  static const Color errorText = Color(0xFFFF0000);
}

/// Light theme data
ThemeData lightTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    surface: AppColors.ivory,
    primary: AppColors.teal,
    onPrimary: Colors.white,
    secondary: AppColors.gold,
    onSecondary: AppColors.graphite,
    error: AppColors.coral,
    onError: Colors.white,
    surfaceTint: AppColors.teal,
  ),
  textTheme: TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w300,
      color: AppColors.graphite,
      letterSpacing: -0.5,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      color: AppColors.graphite,
      letterSpacing: -0.3,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.graphite,
      letterSpacing: 0.15,
    ),
    bodyLarge: TextStyle(
      fontSize: 14,
      color: AppColors.graphite,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 12,
      color: AppColors.graphite,
      height: 1.4,
    ),
    labelLarge: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
  ),
  scaffoldBackgroundColor: AppColors.ivory,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.graphite,
    elevation: 0,
    titleTextStyle: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w300,
      color: AppColors.graphite,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(AppColors.teal),
      foregroundColor: WidgetStatePropertyAll(Colors.white),
      padding: WidgetStatePropertyAll(const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.cellSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.gridLine),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.gridLine),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.teal, width: 2),
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.cellSurface,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
);

ThemeData darkTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    surface: AppColors.graphite,
    primary: AppColors.teal,
    onPrimary: Colors.white,
    secondary: AppColors.gold,
    onSecondary: AppColors.graphite,
    error: AppColors.coral,
    onError: Colors.white,
    surfaceTint: AppColors.teal,
  ),
  textTheme: TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w300,
      color: AppColors.ivory,
      letterSpacing: -0.5,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      color: AppColors.ivory,
      letterSpacing: -0.3,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.ivory,
      letterSpacing: 0.15,
    ),
    bodyLarge: TextStyle(
      fontSize: 14,
      color: AppColors.ivory,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 12,
      color: AppColors.ivory,
      height: 1.4,
    ),
    labelLarge: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: AppColors.teal,
    ),
  ),
  scaffoldBackgroundColor: AppColors.graphite,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.ivory,
    elevation: 0,
    titleTextStyle: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w300,
      color: AppColors.ivory,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(AppColors.teal),
      foregroundColor: WidgetStatePropertyAll(Colors.white),
      padding: WidgetStatePropertyAll(const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.cellSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.gridLine),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.gridLine),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.teal, width: 2),
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.cellSurface,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
);