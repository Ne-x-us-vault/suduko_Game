import 'package:flutter/material.dart';

class AppColors {
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey900 = Color(0xFF111111);
  static const Color grey800 = Color(0xFF222222);
  static const Color grey700 = Color(0xFF333333);
  static const Color grey600 = Color(0xFF444444);
  static const Color grey500 = Color(0xFF666666);
  static const Color grey400 = Color(0xFF999999);
  static const Color grey300 = Color(0xFFCCCCCC);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey100 = Color(0xFFF5F5F5);

  static const Color gridThick = Color(0xFF000000);
  static const Color gridThin = Color(0xFFBDBDBD); // Slightly darker for better visibility on pure white

  static const Color cellUser = Color(0xFFFFFFFF);
  static const Color cellOriginal = Color(0xFFFFFFFF); // Pure white for consistency
  static const Color cellSelected = Color(0xFF000000); 
  static const Color cellSameNumber = Color(0xFFF2F2F2);
  static const Color cellError = Color(0xFFEEEEEE);
  static const Color cellHint = Color(0xFFF9F9F9);
}

ThemeData lightTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    surface: AppColors.white,
    primary: AppColors.black,
    onPrimary: AppColors.white,
    secondary: AppColors.black,
    onSecondary: AppColors.white,
    error: AppColors.black,
    onError: AppColors.white,
    surfaceTint: AppColors.black,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      color: AppColors.black,
      letterSpacing: -1.2,
      height: 1.1,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.black,
      letterSpacing: -0.4,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.black,
      letterSpacing: 0.1,
    ),
    bodyLarge: TextStyle(
      fontSize: 15,
      color: AppColors.black, // Changed from grey700 to black
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 13,
      color: AppColors.black, // Changed from grey500 to black
      height: 1.4,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.white,
      letterSpacing: 0.2,
    ),
  ),
  scaffoldBackgroundColor: AppColors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.black,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppColors.black,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(AppColors.black),
      foregroundColor: WidgetStatePropertyAll(AppColors.white),
      elevation: const WidgetStatePropertyAll(0),
      padding: WidgetStatePropertyAll(
        const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
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
    color: AppColors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
    surfaceTintColor: Colors.transparent,
  ),
);

ThemeData darkTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    surface: AppColors.black,
    primary: AppColors.white,
    onPrimary: AppColors.black,
    secondary: AppColors.white,
    onSecondary: AppColors.black,
    error: AppColors.white,
    onError: AppColors.black,
    surfaceTint: AppColors.white,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      color: AppColors.white,
      letterSpacing: -1.2,
      height: 1.1,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.white,
      letterSpacing: -0.4,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.white,
      letterSpacing: 0.1,
    ),
    bodyLarge: TextStyle(
      fontSize: 15,
      color: AppColors.white, // Changed from grey300 to white
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 13,
      color: AppColors.white, // Changed from grey500 to white
      height: 1.4,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.black,
      letterSpacing: 0.2,
    ),
  ),
  scaffoldBackgroundColor: AppColors.black,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppColors.white,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(AppColors.white),
      foregroundColor: WidgetStatePropertyAll(AppColors.black),
      elevation: const WidgetStatePropertyAll(0),
      padding: WidgetStatePropertyAll(
        const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
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
    color: AppColors.black,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
    surfaceTintColor: Colors.transparent,
  ),
);
