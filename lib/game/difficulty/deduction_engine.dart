import '../model/position.dart';
import '../model/puzzle.dart';
import '../validation/constraint_engine.dart';

/// Human-oriented logical deduction engine.
///
/// Performs constraint propagation without backtracking. Each deduction type
/// is a named technique with structured metadata (affected cells, suggested
/// move, explanation). The engine produces deductions for the *current
/// player state*, so it can serve both difficulty analysis (solving from
/// scratch) and live hint generation (during gameplay).

enum DeductionType {
  rowSingle,       // Only one legal cell left in an unsolved row.
  columnSingle,    // Only one legal cell left in an unsolved column.
  regionSingle,    // Only one legal cell left in an unsolved region.
  adjacencyElim,   // Adjacent cells eliminated.
  forcedFromRegion, // Row/col interaction with region.
}

extension DeductionTypeLabel on DeductionType {
  int get level {
    switch (this) {
      case DeductionType.rowSingle:
      case DeductionType.columnSingle:
      case DeductionType.regionSingle:
        return 1;
      case DeductionType.adjacencyElim:
        return 2;
      case DeductionType.forcedFromRegion:
        return 3;
    }
  }

  String get label {
    switch (this) {
      case DeductionType.rowSingle:
        return 'Row Single';
      case DeductionType.columnSingle:
        return 'Column Single';
      case DeductionType.regionSingle:
        return 'Region Single';
      case DeductionType.adjacencyElim:
        return 'Adjacency Elimination';
      case DeductionType.forcedFromRegion:
        return 'Region Interaction';
    }
  }
}

class Deduction {
  final String explanation;
  final List<Position> affectedCells;
  final Position? suggestedQueen;
  final DeductionType type;

  const Deduction({
    required this.explanation,
    required this.affectedCells,
    this.suggestedQueen,
    required this.type,
  });
}

class DeductionEngine {
  DeductionEngine._();

  /// One pass: all deductions for the current state.
  static List<Deduction> analyze(
    Puzzle puzzle,
    List<Position> currentPlacements,
    Set<Position> candidateMarks,
  ) {
    final deductions = <Deduction>[];
    final size = puzzle.size;

    // Build set of current placements for O(1) lookups.
    final placedRows = <int>{};
    final placedCols = <int>{};
    final placedRegions = <int>{};
    for (final p in currentPlacements) {
      placedRows.add(p.row);
      placedCols.add(p.col);
      placedRegions.add(puzzle.getRegionAt(p));
    }

    // Compute legal cells (not placed, not candidate-marked, passes
    // ConstraintEngine).
    List<Position> legalFor(int? row, int? col, int? region) {
      final result = <Position>[];
      for (int r = 0; r < size; r++) {
        if (row != null && r != row) continue;
        for (int c = 0; c < size; c++) {
          if (col != null && c != col) continue;
          if (region != null && puzzle.regionMap[r][c] != region) continue;
          final pos = Position(r, c);
          if (currentPlacements.contains(pos)) continue;
          if (candidateMarks.contains(pos)) continue;
          if (ConstraintEngine.isValidQueenPlacement(puzzle, pos, currentPlacements)) {
            result.add(pos);
          }
        }
      }
      return result;
    }

    // Row singles.
    for (int r = 0; r < size; r++) {
      if (placedRows.contains(r)) continue;
      final cells = legalFor(r, null, null);
      if (cells.length == 1) {
        deductions.add(Deduction(
          explanation:
              'Row ${r + 1} has only one possible position for a queen.',
          affectedCells: cells,
          suggestedQueen: cells.first,
          type: DeductionType.rowSingle,
        ));
      }
    }

    // Column singles.
    for (int c = 0; c < size; c++) {
      if (placedCols.contains(c)) continue;
      final cells = legalFor(null, c, null);
      if (cells.length == 1) {
        deductions.add(Deduction(
          explanation:
              'Column ${c + 1} has only one possible position for a queen.',
          affectedCells: cells,
          suggestedQueen: cells.first,
          type: DeductionType.columnSingle,
        ));
      }
    }

    // Region singles.
    for (int reg = 0; reg < size; reg++) {
      if (placedRegions.contains(reg)) continue;
      final cells = legalFor(null, null, reg);
      if (cells.length == 1) {
        deductions.add(Deduction(
          explanation:
              'Region ${reg + 1} has only one possible position for a queen.',
          affectedCells: cells,
          suggestedQueen: cells.first,
          type: DeductionType.regionSingle,
        ));
      }
    }

    return deductions;
  }

  /// Repeatedly applies deductions until the puzzle is solved or no new
  /// deduction can be made. Returns the ordered list of all deductions and
  /// the final placements achieved purely by logic.
  ///
  /// `guessesRequired` is the number of points where forced deduction stopped
  /// and the solver would need to guess (we don't actually guess here — we
  /// just count dead-end points where the forced chain stalls).
  static AnalysisResult analyzeFromScratch(Puzzle puzzle) {
    final placements = <Position>[];
    final marks = <Position>{};
    int guessesRequired = 0;

    while (placements.length < puzzle.size) {
      final deductions = analyze(puzzle, placements, marks);
      if (deductions.isEmpty) {
        guessesRequired++;
        break; // stuck, would need to guess
      }
      for (final d in deductions) {
        if (d.suggestedQueen != null &&
            !placements.contains(d.suggestedQueen)) {
          placements.add(d.suggestedQueen!);
          if (placements.length == puzzle.size) break;
        }
      }
    }

    final isSolved = ConstraintEngine.isSolved(puzzle, placements);
    return AnalysisResult(
      placements: placements,
      guessesRequired: guessesRequired,
      solvedByDeduction: isSolved && guessesRequired == 0,
    );
  }
}

class AnalysisResult {
  final List<Position> placements;
  final int guessesRequired;
  final bool solvedByDeduction;

  const AnalysisResult({
    required this.placements,
    required this.guessesRequired,
    required this.solvedByDeduction,
  });
}