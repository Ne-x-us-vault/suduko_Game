import 'package:flutter/material.dart';

import '../hints/hint_service.dart';

/// Persistent user settings.
@immutable
class GameSettings {
  final ThemeMode themeMode;
  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool autoMarks;
  final bool strictMode;
  final bool showMistakes;
  final bool highContrast;
  final bool reducedMotion;
  final HintLevel hintLevel;
  final double animationIntensity; // 0..1

  const GameSettings({
    this.themeMode = ThemeMode.system,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.autoMarks = true,
    this.strictMode = false,
    this.showMistakes = true,
    this.highContrast = false,
    this.reducedMotion = false,
    this.hintLevel = HintLevel.normal,
    this.animationIntensity = 1.0,
  });

  GameSettings copyWith({
    ThemeMode? themeMode,
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? autoMarks,
    bool? strictMode,
    bool? showMistakes,
    bool? highContrast,
    bool? reducedMotion,
    HintLevel? hintLevel,
    double? animationIntensity,
  }) {
    return GameSettings(
      themeMode: themeMode ?? this.themeMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      autoMarks: autoMarks ?? this.autoMarks,
      strictMode: strictMode ?? this.strictMode,
      showMistakes: showMistakes ?? this.showMistakes,
      highContrast: highContrast ?? this.highContrast,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      hintLevel: hintLevel ?? this.hintLevel,
      animationIntensity: animationIntensity ?? this.animationIntensity,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'soundEnabled': soundEnabled,
        'hapticsEnabled': hapticsEnabled,
        'autoMarks': autoMarks,
        'strictMode': strictMode,
        'showMistakes': showMistakes,
        'highContrast': highContrast,
        'reducedMotion': reducedMotion,
        'hintLevel': hintLevel.name,
        'animationIntensity': animationIntensity,
      };

  factory GameSettings.fromJson(Map<String, dynamic> json) => GameSettings(
        themeMode: _themeModeFromName(json['themeMode'] as String?),
        soundEnabled: json['soundEnabled'] as bool? ?? true,
        hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
        autoMarks: json['autoMarks'] as bool? ?? true,
        strictMode: json['strictMode'] as bool? ?? false,
        showMistakes: json['showMistakes'] as bool? ?? true,
        highContrast: json['highContrast'] as bool? ?? false,
        reducedMotion: json['reducedMotion'] as bool? ?? false,
        hintLevel: _hintLevelFromName(json['hintLevel'] as String?),
        animationIntensity:
            (json['animationIntensity'] as num?)?.toDouble() ?? 1.0,
      );

  static ThemeMode _themeModeFromName(String? name) {
    switch (name) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static HintLevel _hintLevelFromName(String? name) {
    switch (name) {
      case 'subtle':
        return HintLevel.subtle;
      case 'direct':
        return HintLevel.direct;
      default:
        return HintLevel.normal;
    }
  }
}