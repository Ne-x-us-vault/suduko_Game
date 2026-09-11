import 'dart:math' as math;

import '../model/difficulty.dart';
import '../model/position.dart';
import '../model/puzzle.dart';
import '../validation/constraint_engine.dart';

/// A real constraint solver for QUEENS puzzles.
///
/// Strategy: per-row candidate propagation + most-constrained-row heuristic +
/// backtracking. Because every valid board has exactly one queen per row, the
/// search is row based; at each step the row with the fewest legal cells is
/// explored first. This is far cheaper than naive brute force while remaining
/// simple to reason about and to verify.
class QueensSolver {
  QueensSolver._();

  /// Finds one solution and returns it together with solve metrics.
  static SolverResult findOneSolution(Puzzle puzzle) {
    return _solve(puzzle, findFirst: true);
  }

  /// Counts solutions, stopping at [limit] (default 2).
  /// 0 = unsolvable, 1 = unique, >= limit = ambiguous.
  static int countSolutions(Puzzle puzzle, {int limit = 2}) {
    final result = _solve(puzzle, findFirst: false, countLimit: limit);
    return result.solutionCount;
  }

  /// True when the puzzle has exactly one solution.
  static bool isUniqueSolution(Puzzle puzzle) => countSolutions(puzzle) == 1;

  static SolverResult _solve(
    Puzzle puzzle, {
    required bool findFirst,
    int countLimit = 2,
  }) {
    final watch = Stopwatch()..start();
    final metrics = _MetricCollector();
    final placements = <Position>[];
    final solution = <Position>[];
    var solutionCount = 0;

    void backtrack() {
      metrics.recursiveCalls++;
      if (placements.length == puzzle.size) {
        if (findFirst) {
          solution.addAll(placements);
          metrics.maxSearchDepth =
              math.max(metrics.maxSearchDepth, placements.length);
          return;
        }
        solutionCount++;
        metrics.maxSearchDepth =
            math.max(metrics.maxSearchDepth, placements.length);
        return;
      }

      // Choose the most-constrained row (fewest legal candidates).
      int bestRow = -1;
      List<Position> bestCandidates = const [];
      for (int row = 0; row < puzzle.size; row++) {
        if (placements.any((p) => p.row == row)) continue;
        final candidates = <Position>[];
        for (int col = 0; col < puzzle.size; col++) {
          final pos = Position(row, col);
          if (ConstraintEngine.isValidQueenPlacement(puzzle, pos, placements)) {
            candidates.add(pos);
          }
        }
        metrics.branchCount += candidates.length;
        if (bestRow == -1 || candidates.length < bestCandidates.length) {
          bestRow = row;
          bestCandidates = candidates;
        }
      }

      if (bestRow == -1) return; // dead end

      metrics.propagationRounds++;
      if (bestCandidates.length == 1) metrics.forcedPlacements++;

      for (final pos in bestCandidates) {
        placements.add(pos);
        backtrack();
        placements.removeLast();
        if (findFirst && solution.isNotEmpty) return;
        if (!findFirst && solutionCount >= countLimit) return;
      }
    }

    backtrack();

    watch.stop();
    metrics.solveTime = watch.elapsed;

    return SolverResult(
      solution: findFirst && solution.isNotEmpty ? solution : null,
      solutionCount: solutionCount,
      metrics: metrics.build(),
    );
  }
}

class SolverResult {
  final List<Position>? solution;
  final int solutionCount;
  final SolverMetrics metrics;

  const SolverResult({
    required this.solution,
    required this.solutionCount,
    required this.metrics,
  });
}

class _MetricCollector {
  int recursiveCalls = 0;
  int maxSearchDepth = 0;
  int branchCount = 0;
  int forcedPlacements = 0;
  int propagationRounds = 0;
  Duration solveTime = Duration.zero;

  SolverMetrics build() => SolverMetrics(
        recursiveCalls: recursiveCalls,
        maxSearchDepth: maxSearchDepth,
        branchCount: branchCount,
        candidatesEliminated: branchCount,
        forcedPlacements: forcedPlacements,
        propagationRounds: propagationRounds,
        solveTime: solveTime,
      );
}