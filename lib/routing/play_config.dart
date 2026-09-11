import '../game/model/difficulty.dart';
import '../game/model/game_mode.dart';

/// Parameters for starting a game.
class PlayConfig {
  final GameMode mode;
  final int? size;
  final Difficulty? difficulty;
  final int? seed;

  /// When true and an identical-mode session is active, resume it instead of
  /// generating a new puzzle.
  final bool resume;

  const PlayConfig({
    required this.mode,
    this.size,
    this.difficulty,
    this.seed,
    this.resume = false,
  });

  PlayConfig copyWith({bool? resume}) => PlayConfig(
        mode: mode,
        size: size,
        difficulty: difficulty,
        seed: seed,
        resume: resume ?? this.resume,
      );

  static const PlayConfig quickPlayDefault = PlayConfig(
    mode: GameMode.quickPlay,
    size: 6,
    difficulty: Difficulty.easy,
  );
}