import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/hints/hint_service.dart';
import '../game/settings/game_settings.dart';
import '../persistence/persistence_service.dart';

class SettingsController extends StateNotifier<GameSettings> {
  final PersistenceService _persistence;

  SettingsController(this._persistence, {GameSettings? initial})
      : super(initial ?? const GameSettings());

  Future<void> load() async {
    state = await _persistence.loadSettings();
  }

  void update(GameSettings settings) {
    state = settings;
    _persistence.saveSettings(settings);
  }

  void setThemeMode(ThemeMode mode) => update(state.copyWith(themeMode: mode));
  void setSoundEnabled(bool v) => update(state.copyWith(soundEnabled: v));
  void setHapticsEnabled(bool v) => update(state.copyWith(hapticsEnabled: v));
  void setAutoMarks(bool v) => update(state.copyWith(autoMarks: v));
  void setStrictMode(bool v) => update(state.copyWith(strictMode: v));
  void setShowMistakes(bool v) => update(state.copyWith(showMistakes: v));
  void setHighContrast(bool v) => update(state.copyWith(highContrast: v));
  void setReducedMotion(bool v) => update(state.copyWith(reducedMotion: v));
  void setHintLevel(HintLevel level) => update(state.copyWith(hintLevel: level));
  void setAnimationIntensity(double v) =>
      update(state.copyWith(animationIntensity: v));
}

/// Seed settings loaded synchronously at startup (overridden in main).
final initialSettingsProvider =
    Provider<GameSettings>((ref) => const GameSettings());

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, GameSettings>((ref) {
  final controller = SettingsController(
    ref.watch(persistenceProvider),
    initial: ref.watch(initialSettingsProvider),
  );
  return controller;
});

final persistenceProvider =
    Provider<PersistenceService>((ref) => throw UnimplementedError());