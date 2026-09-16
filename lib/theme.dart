import 'package:flutter/material.dart';

class AppColors {
  static const Color cream = Color(0xFFF7F5F0);
  static const Color paper = Color(0xFFFDFCFA);
  static const Color ink = Color(0xFF1B1F2B);
  static const Color inkLight = Color(0xFF3D4255);
  static const Color slate = Color(0xFF6B7280);
  static const Color muted = Color(0xFF9CA3AF);
  static const Color teal = Color(0xFF0E7C6B);
  static const Color tealSoft = Color(0xFFD1FAE5);
  static const Color amber = Color(0xFFD97706);
  static const Color amberSoft = Color(0xFFFEF3C7);
  static const Color rose = Color(0xFFE11D48);
  static const Color roseSoft = Color(0xFFFEE2E2);
  static const Color gridThick = Color(0xFF1B1F2B);
  static const Color gridThin = Color(0xFFD1D5DB);
  static const Color cellUser = Color(0xFFFFFFFF);
  static const Color cellOriginal = Color(0xFFF0F4F8);
  static const Color cellSelected = Color(0xFFD1FAE5);
  static const Color cellSameNumber = Color(0xFFECFDF5);
  static const Color cellError = Color(0xFFFEE2E2);
  static const Color cellHint = Color(0xFFFEF3C7);
}

ThemeData lightTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    surface: AppColors.cream,
    primary: AppColors.teal,
    onPrimary: Colors.white,
    secondary: AppColors.amber,
    onSecondary: AppColors.ink,
    error: AppColors.rose,
    onError: Colors.white,
    surfaceTint: AppColors.teal,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
      letterSpacing: -1.2,
      height: 1.1,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
      letterSpacing: -0.4,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
      letterSpacing: 0.1,
    ),
    bodyLarge: TextStyle(
      fontSize: 15,
      color: AppColors.inkLight,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 13,
      color: AppColors.slate,
      height: 1.4,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      letterSpacing: 0.2,
    ),
  ),
  scaffoldBackgroundColor: AppColors.cream,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.ink,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(AppColors.teal),
      foregroundColor: WidgetStatePropertyAll(Colors.white),
      elevation: const WidgetStatePropertyAll(2),
      padding: WidgetStatePropertyAll(
        const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.paper,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    surfaceTintColor: Colors.transparent,
  ),
);

ThemeData darkTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    surface: Color(0xFF12141A),
    primary: AppColors.teal,
    onPrimary: Colors.white,
    secondary: AppColors.amber,
    onSecondary: Colors.white,
    error: AppColors.rose,
    onError: Colors.white,
    surfaceTint: AppColors.teal,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      color: Color(0xFFE5E7EB),
      letterSpacing: -1.2,
      height: 1.1,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Color(0xFFE5E7EB),
      letterSpacing: -0.4,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Color(0xFFE5E7EB),
      letterSpacing: 0.1,
    ),
    bodyLarge: TextStyle(
      fontSize: 15,
      color: Color(0xFFD1D5DB),
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 13,
      color: Color(0xFF9CA3AF),
      height: 1.4,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      letterSpacing: 0.2,
    ),
  ),
  scaffoldBackgroundColor: const Color(0xFF12141A),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: Color(0xFFE5E7EB),
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Color(0xFFE5E7EB),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(AppColors.teal),
      foregroundColor: WidgetStatePropertyAll(Colors.white),
      elevation: const WidgetStatePropertyAll(2),
      padding: WidgetStatePropertyAll(
        const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF1E2028),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    surfaceTintColor: Colors.transparent,
  ),
);
