import '../model/difficulty.dart';
import '../model/puzzle.dart';
import '../solver/queens_solver.dart';
import 'deduction_engine.dart';

/// Computes a deterministic difficulty classification for a puzzle.
///
/// Difficulty is anchored to the board size (bigger boards demand more
/// placement + interaction steps) and adjusted by how much *reasoning* the
/// particular layout actually needs:
///
///  * candidate-pool width (loose vs. tightly constrained layouts),
///  * how deep the required deduction chain runs,
///  * whether the puzzle stalls and would need a guessed move at all.
class DifficultyEngine {
  DifficultyEngine._();

  /// Full classification. Pure function — always deterministic.
  static DifficultyScore classify(Puzzle puzzle) {
    // 1. Human difficulty via deduction analysis (primary signal).
    final analysis = DeductionEngine.analyzeFromScratch(puzzle);
    final humanRaw = _computeHumanScore(puzzle, analysis);

    // 2. Computational difficulty via solver metrics (secondary signal).
    final solverResult = QueensSolver.findOneSolution(puzzle);
    final compRaw = _computeComputationalScore(puzzle, solverResult.metrics);

    // 3. Combine for the numeric score; classification uses the human-
    //    oriented score so a large-but-logic-only board is still labelable as
    //    Hard/Expert while a guessy small board is not unfairly downgraded.
    final combined = humanRaw * 0.7 + compRaw * 0.3;
    final difficulty = _classify(humanRaw);

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

    // Size anchor: bigger boards are intrinsically more demanding.
    final anchor = 16 * (n - 5) + 4;

    // Reasoning deltas: a solved puzzle with a tight layout (small candidate
    // pools, few rounds) is easier; stale pools and long chains are harder.
    final poolDelta = (analysis.maxCandidateSetSize - (n + 3)) * 2.5;
    final roundsDelta = (analysis.rounds - 4) * 2.0;

    final reasoning = poolDelta + roundsDelta;

    if (!analysis.solvedByDeduction) {
      // Stalls: a player has to risk guessing. Heavily penalised.
      return ((anchor + reasoning) + 30).clamp(0.0, 100.0);
    }

    return (anchor + reasoning).clamp(1.0, 100.0);
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
      totalDeductions: analysis.totalDeductions,
      forcedPlacements: analysis.placements.length,
      forcedEliminations: analysis.eliminationCount,
      longestChain: analysis.longestChain,
      maxCandidateSetSize: analysis.maxCandidateSetSize,
      unresolvedChoices: analysis.guessesRequired,
      guessesRequired: analysis.guessesRequired,
      highestTechniqueLevel: analysis.guessesRequired > 0 ? 4 : 3,
      solvedByDeduction: analysis.solvedByDeduction,
    );
  }
}