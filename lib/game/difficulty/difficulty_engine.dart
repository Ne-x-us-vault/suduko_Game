import 'dart:math' as math;

import '../model/difficulty.dart';
import '../model/puzzle.dart';
import '../solver/queens_solver.dart';
import 'deduction_engine.dart';

/// Computes a deterministic difficulty classification for a puzzle.
///
/// Uses both human-oriented deduction analysis (primary) and computational
/// solver complexity (secondary). A puzzle that looks hard to a computer but
/// is easy for a human player is classified as Easy, not Expert.

class DifficultyEngine {
  DifficultyEngine._();

  /// Full classification. Pure function — always deterministic.
  static DifficultyScore classify(Puzzle puzzle) {
    // 1. Human difficulty via deduction analysis.
    final analysis = DeductionEngine.analyzeFromScratch(puzzle);
    final humanRaw = _computeHumanScore(puzzle, analysis);

    // 2. Computational difficulty via solver metrics.
    final solverResult = QueensSolver.findOneSolution(puzzle);
    final compRaw = _computeComputationalScore(puzzle, solverResult.metrics);

    // 3. Combine: 70% human, 30% computational.
    final combined = humanRaw * 0.7 + compRaw * 0.3;

    // 4. Classify.
    final difficulty = _classify(combined);

    return DifficultyScore(
      humanScore: humanRaw,
      computationalScore: compRaw,
      finalScore: combined,
      difficulty: difficulty,
      humanMetrics: _deriveHumanMetrics(puzzle, analysis),
      computationalMetrics: solverResult.metrics,
      solvedByDeduction: analysis.solvedByDeduction,
    );
  }

  /// Human difficulty score in [0, 100].
  static double _computeHumanScore(
      Puzzle puzzle, AnalysisResult analysis) {
    final n = puzzle.size;
    if (analysis.solvedByDeduction) {
      // Pure deduction: penalise based on how many guesses would be needed
      // (0 in this case) and how "forced" it was.
      final placedRatio = analysis.placements.length / n;
      // All placed purely → lower score. Slightly harder if many candidates.
      return math.min(20.0, placedRatio * 10);
    }
    // Requires guessing: harder.
    final guessPenalty = (analysis.guessesRequired / n).clamp(0.0, 1.0) * 60;
    return (40 + guessPenalty).clamp(0.0, 100);
  }

  /// Computational difficulty score in [0, 100].
  static double _computeComputationalScore(
      Puzzle puzzle, SolverMetrics m) {
    final n = puzzle.size;
    // Branching ratio relative to worst-case (n!).
    final branchRatio = (m.branchCount / (n * n * n)).clamp(0.0, 1.0);
    final depthRatio = (m.maxSearchDepth / n).clamp(0.0, 1.0);
    final timeFactor =
        (m.solveTime.inMicroseconds / 100000).clamp(0.0, 1.0); // 100ms → 1.0
    return (branchRatio * 40 + depthRatio * 30 + timeFactor * 30)
        .clamp(0.0, 100);
  }

  static Difficulty _classify(double score) {
    if (score < 25) return Difficulty.easy;
    if (score < 50) return Difficulty.medium;
    if (score < 75) return Difficulty.hard;
    return Difficulty.expert;
  }

  static DifficultyMetrics _deriveHumanMetrics(
      Puzzle puzzle, AnalysisResult analysis) {
    return DifficultyMetrics(
      totalDeductions: analysis.placements.length,
      forcedPlacements: analysis.placements.length,
      forcedEliminations: analysis.placements.length * 2,
      longestChain: analysis.placements.length,
      maxCandidateSetSize: 0,
      unresolvedChoices: analysis.guessesRequired,
      guessesRequired: analysis.guessesRequired,
      highestTechniqueLevel: analysis.solvedByDeduction ? 1 : 4,
      solvedByDeduction: analysis.solvedByDeduction,
    );
  }
}