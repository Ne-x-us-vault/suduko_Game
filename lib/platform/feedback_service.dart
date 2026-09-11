import 'package:flutter/services.dart';

import '../game/settings/game_settings.dart';

/// Haptic + sound feedback service. Both are gated by settings and fail
/// gracefully on unsupported devices.
class FeedbackService {
  static void queenPlace(GameSettings settings) {
    if (settings.hapticsEnabled) HapticFeedback.selectionClick();
    if (settings.soundEnabled) SystemSound.play(SystemSoundType.click);
  }

  static void queenRemove(GameSettings settings) {
    if (settings.hapticsEnabled) HapticFeedback.selectionClick();
    if (settings.soundEnabled) SystemSound.play(SystemSoundType.click);
  }

  static void invalidMove(GameSettings settings) {
    if (settings.hapticsEnabled) HapticFeedback.mediumImpact();
    // No unpleasant sound for errors.
  }

  static void undo(GameSettings settings) {
    if (settings.hapticsEnabled) HapticFeedback.lightImpact();
  }

  static void completion(GameSettings settings) {
    if (settings.hapticsEnabled) HapticFeedback.heavyImpact();
    if (settings.soundEnabled) SystemSound.play(SystemSoundType.alert);
  }
}