import '../model/position.dart';
import '../model/puzzle.dart';

/// Authoritative constraint engine for the QUEENS game rules.
///
/// All game modes use these exact functions — the UI NEVER duplicates them.
class ConstraintEngine {
  ConstraintEngine._();

  /// Exactly one queen in every row.
  static bool isRowSatisfied(Puzzle puzzle, List<Position> placements) {
    if (placements.length != puzzle.size) return false;
    final rows = List<bool>.filled(puzzle.size, false);
    for (final p in placements) {
      rows[p.row] = true;
    }
    return rows.every((v) => v);
  }

  /// Exactly one queen in every column.
  static bool isColumnSatisfied(Puzzle puzzle, List<Position> placements) {
    if (placements.length != puzzle.size) return false;
    final cols = List<bool>.filled(puzzle.size, false);
    for (final p in placements) {
      cols[p.col] = true;
    }
    return cols.every((v) => v);
  }

  /// Exactly one queen in every region.
  static bool isRegionSatisfied(Puzzle puzzle, List<Position> placements) {
    if (placements.length != puzzle.size) return false;
    final regions = List<bool>.filled(puzzle.size, false);
    for (final p in placements) {
      regions[puzzle.getRegionAt(p)] = true;
    }
    return regions.every((v) => v);
  }

  /// Whether [pos] shares an 8-neighbor with any queen in [placements].
  /// [pos] itself must not be in [placements] for this to matter (caller
  /// should filter).
  static bool hasAdjacentQueen(Position pos, List<Position> placements) {
    for (final p in placements) {
      if (p == pos) continue;
      if (pos.isKingAdjacentTo(p)) return true;
    }
    return false;
  }

  /// Is [pos] a legal queen placement given current [placements]?
  /// Checks row, column, region, and 8-neighbor adjacency — all four rule
  /// types.
  static bool isValidQueenPlacement(
      Puzzle puzzle, Position pos, List<Position> placements) {
    for (final p in placements) {
      if (p.row == pos.row) return false;
      if (p.col == pos.col) return false;
      if (puzzle.getRegionAt(p) == puzzle.getRegionAt(pos)) return false;
      if (pos.isKingAdjacentTo(p)) return false;
    }
    return true;
  }

  static bool isValidPlacement(
          Puzzle puzzle, Position pos, List<Position> placements) =>
      isValidQueenPlacement(puzzle, pos, placements);

  /// Returns the set of all conflicting positions in [placements].
  /// Useful for highlighting after a casual illegal placement.
  static Set<Position> getConflicts(
      Puzzle puzzle, List<Position> placements) {
    final conflicts = <Position>{};
    for (int i = 0; i < placements.length; i++) {
      final a = placements[i];
      for (int j = i + 1; j < placements.length; j++) {
        final b = placements[j];
        if (a.row == b.row ||
            a.col == b.col ||
            puzzle.getRegionAt(a) == puzzle.getRegionAt(b) ||
            a.isKingAdjacentTo(b)) {
          conflicts.add(a);
          conflicts.add(b);
        }
      }
    }
    return conflicts;
  }

  /// True when the puzzle is completely and validly solved.
  static bool isSolved(Puzzle puzzle, List<Position> placements) {
    if (placements.length != puzzle.size) return false;
    return getConflicts(puzzle, placements).isEmpty;
  }

  /// Full structural validation of a puzzle's solution.
  /// Returns null on success; error message on failure.
  static String? validateSolution(Puzzle puzzle) {
    if (puzzle.solution.length != puzzle.size) {
      return 'Expected ${puzzle.size} queens in solution, got ${puzzle.solution.length}';
    }
    if (isSolved(puzzle, puzzle.solution)) return null;
    return 'Solution violates constraint rules';
  }

  /// Full structural + solvability validation (requires RegionValidator to
  /// check regions externally if needed; here we do the rule check).
  /// Returns null on success.
  static String? validatePuzzle(Puzzle puzzle) {
    // Solution present and correct size.
    if (puzzle.solution.length != puzzle.size) {
      return 'Solution has wrong number of queens';
    }
    // All cells are in-bounds and region ids valid.
    for (int r = 0; r < puzzle.size; r++) {
      for (int c = 0; c < puzzle.size; c++) {
        final rid = puzzle.regionMap[r][c];
        if (rid < 0 || rid >= puzzle.size) {
          return 'Invalid region id $rid at ($r,$c)';
        }
      }
    }
    // Solution valid.
    final solErr = validateSolution(puzzle);
    if (solErr != null) return solErr;
    return null;
  }
}