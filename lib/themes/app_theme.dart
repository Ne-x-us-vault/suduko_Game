import 'package:flutter/material.dart';

class BoardColors {
  final Color queen;
  final Color mark;
  final Color boardStroke;
  final Color cellStroke;
  final Color selected;
  final Color conflict;
  final Color hintHighlight;
  final Color completed;
  final List<Color> regionFills;
  final List<Color> regionStrokes;

  const BoardColors({
    required this.queen,
    required this.mark,
    required this.boardStroke,
    required this.cellStroke,
    required this.selected,
    required this.conflict,
    required this.hintHighlight,
    required this.completed,
    required this.regionFills,
    required this.regionStrokes,
  });
}

class AppTheme {
  AppTheme._();

  static const Color _lightBg = Color(0xFFF4F3F8);
  static const Color _darkBg = Color(0xFF101014);

  /// Region fill palette — soft, distinct hues (light theme + dark theme).
  static const List<Color> _lightRegionFills = [
    Color(0xFFFFDAD6), // blush
    Color(0xFFFFE8C5), // cream
    Color(0xFFB3E5C8), // mint
    Color(0xFFBCE7E4), // aqua
    Color(0xFFC5DBFB), // sky
    Color(0xFFD8D1FF), // lavender
    Color(0xFFF8C9E6), // pink
    Color(0xFFE7E0D9), // warm grey
    Color(0xFFD6E8C8), // sage
    Color(0xFFFFD9B8), // peach
  ];

  static const List<Color> _darkRegionFills = [
    Color(0xFF5C3A39),
    Color(0xFF5C4E2A),
    Color(0xFF2F4A3A),
    Color(0xFF2A4A48),
    Color(0xFF2F4261),
    Color(0xFF423C6B),
    Color(0xFF5E3658),
    Color(0xFF4A4641),
    Color(0xFF3A4A30),
    Color(0xFF5C442A),
  ];

  /// Strong region boundary colors (drawn on top of fills).
  static const List<Color> _lightStrokes = [
    Color(0xFFC95649),
    Color(0xFFB98A2E),
    Color(0xFF3E9A63),
    Color(0xFF3D8F8B),
    Color(0xFF3B74C2),
    Color(0xFF6C5BC5),
    Color(0xFFC24A9B),
    Color(0xFF6B6259),
    Color(0xFF5C8A3A),
    Color(0xFFBF7B2E),
  ];

  static ThemeData lightTheme = _build(
    Brightness.light,
    _lightBg,
    _lightRegionFills,
    _lightStrokes,
    const Color(0xFF1C1B22),
  );

  static ThemeData darkTheme = _build(
    Brightness.dark,
    _darkBg,
    _darkRegionFills,
    _lightStrokes,
    const Color(0xFFF2F1F7),
  );

  static ThemeData highContrastLight = _build(
    Brightness.light,
    const Color(0xFFFDFDFD),
    const [
      Color(0xFFFFD9D9),
      Color(0xFFFFF2B8),
      Color(0xFFC6FFD2),
      Color(0xFFD0F7F6),
      Color(0xFFC9E3FF),
      Color(0xFFE2D8FF),
      Color(0xFFFFD2EC),
      Color(0xFFF0E6D7),
      Color(0xFFDDF2C0),
      Color(0xFFFFE0C2),
    ],
    const [
      Color(0xFF8B0000),
      Color(0xFF8B6E00),
      Color(0xFF006400),
      Color(0xFF006D6B),
      Color(0xFF003C8F),
      Color(0xFF3D2A9B),
      Color(0xFF8B1A6B),
      Color(0xFF4A3B2C),
      Color(0xFF335E00),
      Color(0xFF8B4A00),
    ],
    const Color(0xFF000000),
  );

  static ThemeData highContrastDark = _build(
    Brightness.dark,
    const Color(0xFF000000),
    const [
      Color(0xFF4A1F1F),
      Color(0xFF4A3B12),
      Color(0xFF1E4026),
      Color(0xFF1E4240),
      Color(0xFF223652),
      Color(0xFF352A55),
      Color(0xFF4A2342),
      Color(0xFF3A332B),
      Color(0xFF2E4218),
      Color(0xFF4A3218),
    ],
    const [
      Color(0xFFFF6B6B),
      Color(0xFFFFD75E),
      Color(0xFF6BFF8E),
      Color(0xFF7DFBFF),
      Color(0xFF7FB3FF),
      Color(0xFFB49BFF),
      Color(0xFFFF8CE0),
      Color(0xFFD9C9B8),
      Color(0xFFB2F06B),
      Color(0xFFFFAC6B),
    ],
    const Color(0xFFFFFFFF),
  );

  static ThemeData _build(
    Brightness brightness,
    Color bg,
    List<Color> regionFills,
    List<Color> regionStrokes,
    Color highContrastForeground,
  ) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7C5BD0),
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: brightness == Brightness.light
            ? const Color(0xFFFFFFFF)
            : const Color(0xFF1A1A20),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(200, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.outlineVariant),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.surfaceContainerHighest),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
      ),
    );
  }

  /// Board colors for the current theme + settings.
  static BoardColors boardColors({
    required Brightness brightness,
    required bool highContrast,
  }) {
    final dark = brightness == Brightness.dark;
    return BoardColors(
      queen: dark ? const Color(0xFFF4F1FF) : const Color(0xFF1A1724),
      mark: (dark ? const Color(0xFFE8E6F0) : const Color(0xFF3A3547))
          .withValues(alpha: 0.85),
      boardStroke: dark ? const Color(0xFF3A3750) : const Color(0xFF2C2740),
      cellStroke: (dark ? const Color(0xFF2A2738) : const Color(0xFFE1DEEA))
          .withValues(alpha: highContrast ? 1.0 : 0.7),
      selected: const Color(0xFF9C7CF0).withValues(alpha: 0.45),
      conflict: const Color(0xFFE4484F).withValues(alpha: 0.55),
      hintHighlight: const Color(0xFFFFC94D).withValues(alpha: 0.45),
      completed: const Color(0xFF57C98A).withValues(alpha: 0.4),
      regionFills: List.of(dark ? _darkRegionFills : _lightRegionFills),
      regionStrokes: _lightStrokes,
    );
  }
}