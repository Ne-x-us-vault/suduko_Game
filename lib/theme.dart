import 'package:flutter/material.dart';

/// Design system: a "printed puzzle sheet" identity.
///
/// Warm-neutral paper, muted ink typography and a single indigo accent used
/// only where it carries meaning (selection, active state, primary action).
/// The board itself stays sharp-edged to keep the precise grid feel, while
/// controls get soft radii for a tactile finish.
class AppColors {
  // Surfaces
  static const paper = Color(0xFFF6F6F4); // app background (light)
  static const surface = Color(0xFFFFFFFF); // cards & board (light)
  static const paperDark = Color(0xFF101114); // app background (dark)
  static const surfaceDark = Color(0xFF1B1D22); // cards & board (dark)
  static const raisedDark = Color(0xFF25282E); // elevated tiles (dark)

  // Ink
  static const ink = Color(0xFF1A1C20);
  static const inkMuted = Color(0xFF6E737B);
  static const inkDark = Color(0xFFF2F3F5);
  static const inkMutedDark = Color(0xFFA7ACB5);

  // Accent
  static const accent = Color(0xFF4059E8);
  static const accentDark = Color(0xFF7C93FF);
  static const onAccent = Color(0xFFFFFFFF);
  static const accentSoft = Color(0xFFECEFFD); // peer / selected tint (light)
  static const accentSoftDark = Color(0xFF232946); // peer tint (dark)

  // Lines
  static const line = Color(0xFFE4E5EA); // thin rules (light)
  static const lineStrong = Color(0xFFC7CAD2); // box separators (light)
  static const lineDark = Color(0xFF2A2D34); // thin rules (dark)
  static const lineStrongDark = Color(0xFF454A54); // box separators (dark)

  // Feedback
  static const error = Color(0xFFE5484D);
  static const errorDark = Color(0xFFFF6369);
  static const errorSoft = Color(0xFFFDECEC);
  static const errorSoftDark = Color(0xFF3A2225);

  // Hints
  static const hintInk = Color(0xFFB45309);
  static const hintInkDark = Color(0xFFF0B429);
  static const hintSoft = Color(0xFFFFF3D6);
  static const hintSoftDark = Color(0xFF33290F);
}

extension AppColorContext on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get paper =>
      isDarkMode ? AppColors.paperDark : AppColors.paper;
  Color get surface =>
      isDarkMode ? AppColors.surfaceDark : AppColors.surface;
  Color get ink => isDarkMode ? AppColors.inkDark : AppColors.ink;
  Color get inkMuted =>
      isDarkMode ? AppColors.inkMutedDark : AppColors.inkMuted;
  Color get accent =>
      isDarkMode ? AppColors.accentDark : AppColors.accent;
  Color get accentSoft =>
      isDarkMode ? AppColors.accentSoftDark : AppColors.accentSoft;
  Color get line => isDarkMode ? AppColors.lineDark : AppColors.line;
  Color get lineStrong =>
      isDarkMode ? AppColors.lineStrongDark : AppColors.lineStrong;
  Color get error => isDarkMode ? AppColors.errorDark : AppColors.error;
  Color get errorSoft =>
      isDarkMode ? AppColors.errorSoftDark : AppColors.errorSoft;
  Color get hintInk => isDarkMode ? AppColors.hintInkDark : AppColors.hintInk;
  Color get hintSoft =>
      isDarkMode ? AppColors.hintSoftDark : AppColors.hintSoft;
}

ThemeData lightTheme() => _buildTheme(Brightness.light);

ThemeData darkTheme() => _buildTheme(Brightness.dark);

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: AppColors.accent,
    onPrimary: AppColors.onAccent,
    secondary: isDark ? AppColors.accentDark : AppColors.accent,
    onSecondary: AppColors.onAccent,
    surface: isDark ? AppColors.paperDark : AppColors.paper,
    onSurface: isDark ? AppColors.inkDark : AppColors.ink,
    error: isDark ? AppColors.errorDark : AppColors.error,
    onError: Colors.white,
    surfaceContainerHighest: isDark ? AppColors.surfaceDark : AppColors.surface,
    surfaceTint: Colors.transparent,
    outline: isDark ? AppColors.lineStrongDark : AppColors.lineStrong,
    outlineVariant: isDark ? AppColors.lineDark : AppColors.line,
  );

  final ink = isDark ? AppColors.inkDark : AppColors.ink;
  final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMuted;

  const radius = 12.0;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        color: ink,
        letterSpacing: -1.6,
        height: 1.05,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: ink,
        letterSpacing: -0.4,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: ink,
        letterSpacing: 0.1,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ink,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: ink,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 13,
        color: inkMuted,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.onAccent,
        letterSpacing: 0.2,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: ink,
        letterSpacing: -0.2,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        elevation: 0,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        side: BorderSide(color: inkMuted.withValues(alpha: 0.55), width: 1.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.lineDark : AppColors.line,
          width: 1,
        ),
      ),
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: DividerThemeData(
      color: isDark ? AppColors.lineDark : AppColors.line,
      thickness: 1,
      space: 1,
    ),
  );
}