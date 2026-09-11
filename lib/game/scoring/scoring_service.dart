import 'dart:math' as math;

import '../model/difficulty.dart';
import '../model/game_mode.dart';
import '../model/puzzle.dart';

/// Deterministic scoring system.
///
/// The exact same (puzzle, time, mistakes, hints, streak, mode) always yields
/// the same total score. Mistakes and hints can only decrease the score.
class ScoreBreakdown {
  final int baseScore;
  final int difficultyBonus;
  final int speedBonus;
  final int mistakePenalty;
  final int hintPenalty;
  final int streakBonus;
  final int finalScore;
  final int queensPlaced;
  final bool perfect;
  final int mistakes;
  final int hintsUsed;

  const ScoreBreakdown({
    required this.baseScore,
    required this.difficultyBonus,
    required this.speedBonus,
    required this.mistakePenalty,
    required this.hintPenalty,
    required this.streakBonus,
    required this.finalScore,
    required this.queensPlaced,
    required this.perfect,
    required this.mistakes,
    required this.hintsUsed,
  });

  Map<String, dynamic> toJson() => {
        'baseScore': baseScore,
        'difficultyBonus': difficultyBonus,
        'speedBonus': speedBonus,
        'mistakePenalty': mistakePenalty,
        'hintPenalty': hintPenalty,
        'streakBonus': streakBonus,
        'finalScore': finalScore,
        'queensPlaced': queensPlaced,
        'perfect': perfect,
        'mistakes': mistakes,
        'hintsUsed': hintsUsed,
      };

  factory ScoreBreakdown.fromJson(Map<String, dynamic> json) => ScoreBreakdown(
        baseScore: json['baseScore'] as int? ?? 0,
        difficultyBonus: json['difficultyBonus'] as int? ?? 0,
        speedBonus: json['speedBonus'] as int? ?? 0,
        mistakePenalty: json['mistakePenalty'] as int? ?? 0,
        hintPenalty: json['hintPenalty'] as int? ?? 0,
        streakBonus: json['streakBonus'] as int? ?? 0,
        finalScore: json['finalScore'] as int? ?? 0,
        queensPlaced: json['queensPlaced'] as int? ?? 0,
        perfect: json['perfect'] as bool? ?? false,
        mistakes: json['mistakes'] as int? ?? 0,
        hintsUsed: json['hintsUsed'] as int? ?? 0,
      );
}

class ScoringService {
  ScoringService._();

  static ScoreBreakdown compute({
    required Puzzle puzzle,
    required Duration elapsed,
    required int mistakes,
    required int hintsUsed,
    required List<dynamic> queensPlaced,
    required int streak,
    required GameMode mode,
  }) {
    final size = puzzle.size;
    final difficulty = puzzle.difficulty;

    // Base by size.
    final baseScore = size * 100;

    // Difficulty bonus.
    final diffFactor = switch (difficulty) {
      Difficulty.easy => 1.0,
      Difficulty.medium => 1.25,
      Difficulty.hard => 1.5,
      Difficulty.expert => 2.0,
    };
    final difficultyBonus = (baseScore * (diffFactor - 1)).round();

    // Speed bonus: faster is better; higher on bigger boards.
    final seconds = elapsed.inSeconds.clamp(1, 3600);
    final reference = size * 25; // ~reference seconds
    final speedRatio = (reference / seconds).clamp(0.0, 2.0);
    final speedBonus = (baseScore * speedRatio * 0.35).round();

    // Penalties (never negative for the player).
    final mistakePenalty = math.min(size * 20 * mistakes, baseScore ~/ 2);
    final hintPenalty = math.min(size * 15 * hintsUsed, baseScore ~/ 3);

    // Streak bonus.
    final streakBonus = math.min(streak * 25, 250);

    final queenCount = queensPlaced.length;
    final perfect = mistakes == 0 && hintsUsed == 0;
    final perfectBonus = perfect ? 100 : 0;

    final finalScore = (baseScore +
            difficultyBonus +
            speedBonus +
            streakBonus +
            perfectBonus)
        .clamp(0, 100000) -
        mistakePenalty -
        hintPenalty;

    return ScoreBreakdown(
      baseScore: baseScore,
      difficultyBonus: difficultyBonus,
      speedBonus: speedBonus,
      mistakePenalty: mistakePenalty,
      hintPenalty: hintPenalty,
      streakBonus: streakBonus,
      finalScore: math.max(0, finalScore),
      queensPlaced: queenCount,
      perfect: perfect,
      mistakes: mistakes,
      hintsUsed: hintsUsed,
    );
  }
}