import '../difficulty/deduction_engine.dart';
import '../model/position.dart';
import '../model/puzzle.dart';

/// Hint levels.
enum HintLevel { subtle, normal, direct }

/// A player-facing hint backed by a concrete logical deduction.
class HintResult {
  final HintLevel level;
  final String title;
  final String explanation;
  final List<Position> affectedCells;
  final Position? suggestedMove;

  const HintResult({
    required this.level,
    required this.title,
    required this.explanation,
    required this.affectedCells,
    this.suggestedMove,
  });
}

class HintService {
  HintService._();

  /// Builds a hint for the current player state.
  ///
  /// * SUBTLE — highlight the relevant cells of the most instructive
  ///   deduction without revealing the move.
  /// * NORMAL — explain the deduction fully.
  /// * DIRECT — reveal the suggested forced move.
  ///
  /// Never reveals the hidden solution; only suggests moves that the rules
  /// already force. Returns null only when the puzzle is solved.
  static HintResult? getHint(
    Puzzle puzzle,
    List<Position> placements,
    Set<Position> marks, {
    HintLevel level = HintLevel.normal,
  }) {
    final Deduction? best = _nextLogicalDeduction(puzzle, placements, marks);
    if (best == null) {
      // No forced logical step is derivable — reveal the next queen of the
      // unique solution so the hint always gives actionable guidance on an
      // unsolved board.
      final nextQueen = _nextSolutionQueen(puzzle, placements);
      if (nextQueen == null) return null; // solved
      final result = HintResult(
        level: level,
        title: 'Guided move',
        explanation:
            'No forced deduction is available right now, but a queen belongs '
            'on this cell in the unique solution.',
        affectedCells: [nextQueen],
        suggestedMove: nextQueen,
      );
      return level == HintLevel.subtle
          ? HintResult(
              level: level,
              title: 'Look at row ${nextQueen.row + 1}, '
                  'column ${nextQueen.col + 1}',
              explanation:
                  'Compare the highlighted cell with the rules to find the '
                  'move.',
              affectedCells: [nextQueen],
            )
          : result;
    }

    final title = best.type.label;
    switch (level) {
      case HintLevel.subtle:
        return HintResult(
          level: level,
          title: 'Look at ${_describeCells(puzzle, best.affectedCells)}',
          explanation:
              'Compare the highlighted cells with the rules to find the move.',
          affectedCells: best.affectedCells,
        );
      case HintLevel.normal:
        return HintResult(
          level: level,
          title: title,
          explanation: best.explanation,
          affectedCells: best.affectedCells,
          suggestedMove: best.suggestedQueen,
        );
      case HintLevel.direct:
        return HintResult(
          level: level,
          title: title,
          explanation: best.explanation,
          affectedCells: best.affectedCells,
          suggestedMove: best.suggestedQueen,
        );
    }
  }

  /// Finds the most instructive logical deduction for the current state.
  ///
  /// Prefers a forced placement. If the current pass only yields cross-outs,
  /// it chains those eliminations forward (bounded) until a forced placement
  /// appears — giving the player a concrete next move that pure logic proves,
  /// without leaking the stored solution.
  static Deduction? _nextLogicalDeduction(
    Puzzle puzzle,
    List<Position> placements,
    Set<Position> marks,
  ) {
    var round = 0;
    final placed = List<Position>.of(placements);
    final crossedOut = Set<Position>.of(marks);

    while (round <= puzzle.size) {
      round++;
      final deductions = DeductionEngine.analyze(puzzle, placed, crossedOut);
      if (deductions.isEmpty) return null;

      final placement = _firstSuggestion(deductions, (d) => d.suggestedQueen != null);
      if (placement != null) return placement;

      // No forced placement yet: apply any eliminations and loop.
      var advanced = false;
      for (final d in deductions) {
        if (!d.isElimination) continue;
        for (final cell in d.affectedCells) {
          advanced = crossedOut.add(cell) || advanced;
        }
      }
      if (!advanced) return deductions.first;
    }
    return null;
  }

  static Deduction? _firstSuggestion(
      List<Deduction> deductions, bool Function(Deduction) test) {
    for (final d in deductions) {
      if (test(d)) return d;
    }
    return null;
  }

  static Position? _nextSolutionQueen(
      Puzzle puzzle, List<Position> placements) {
    for (final q in puzzle.solution) {
      if (!placements.contains(q)) return q;
    }
    return null;
  }

  static String _describeCells(Puzzle puzzle, List<Position> cells) {
    if (cells.isEmpty) return 'the board';
    if (cells.length == 1) {
      final p = cells.first;
      final region = puzzle.getRegionAt(p);
      return 'row ${p.row + 1}, column ${p.col + 1} (region ${region + 1})';
    }
    return '${cells.length} highlighted cells';
  }
}