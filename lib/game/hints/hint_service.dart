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
  /// already force. Returns null if no deduction applies (puzzle solved or
  /// no useful clue at the current state).
  static HintResult? getHint(
    Puzzle puzzle,
    List<Position> placements,
    Set<Position> marks, {
    HintLevel level = HintLevel.normal,
  }) {
    final deductions = DeductionEngine.analyze(puzzle, placements, marks);
    if (deductions.isEmpty) return null;

    // Prefer a deduction that suggests a concrete move.
    Deduction best = deductions.first;
    for (final d in deductions.skip(1)) {
      if (d.suggestedQueen != null) {
        best = d;
        break;
      }
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