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
///
/// Two deduction families are produced:
///
///  * Placements — a row, column or region has exactly one remaining legal
///    cell, so a queen is forced there.
///  * Eliminations — a cell cannot legally hold a queen, because placing one
///    there would leave some other row, column or region with no legal cell
///    left. This is the classic "region interaction" reasoning of QUEENS.
enum DeductionType {
  rowSingle, // Only one legal cell left in an unsolved row.
  columnSingle, // Only one legal cell left in an unsolved column.
  regionSingle, // Only one legal cell left in an unsolved region.
  forcedFromRegion, // A cell is impossible because it would empty a line.
  adjacencyElim, // Adjacent cells eliminated (informational).
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

  /// True when this deduction tells the player to cross a cell out rather
  /// than place a queen. Encoded as [suggestedQueen] == null.
  final bool isElimination;
  final DeductionType type;

  const Deduction({
    required this.explanation,
    required this.affectedCells,
    this.suggestedQueen,
    this.isElimination = false,
    required this.type,
  });
}

/// Plain-array candidate mask so a full deduction chain stays cheap.
class _BoardCandidates {
  final List<bool> _canPlace;
  final int _size;

  _BoardCandidates(this._size)
      : _canPlace = List<bool>.filled(_size * _size, true);

  bool get(int r, int c) => _canPlace[r * _size + c];

  void setFalse(int r, int c) => _canPlace[r * _size + c] = false;
}

class DeductionEngine {
  DeductionEngine._();

  /// True when [pos] would be eliminated by a queen at [q] (same row, column,
  /// region, or an 8-neighbour of [q]).
  static bool _eliminatedBy(Puzzle puzzle, Position pos, Position q) {
    if (pos.row == q.row || pos.col == q.col) return true;
    if (puzzle.getRegionAt(pos) == puzzle.getRegionAt(q)) return true;
    return pos.isKingAdjacentTo(q);
  }

  /// All deductions visible from the *current* state in a single pass.
  ///
  ///  * forced placements: a row/column/region with exactly one legal cell.
  ///  * forced eliminations: a cell that can never be a queen because placing
  ///    one there would empty an unplaced row, column or region.
  static List<Deduction> analyze(
    Puzzle puzzle,
    List<Position> currentPlacements,
    Set<Position> candidateMarks,
  ) {
    final deductions = <Deduction>[];
    final size = puzzle.size;
    final placedRows = <int>{};
    final placedCols = <int>{};
    final placedRegions = <int>{};

    final cand = _BoardCandidates(size);
    for (final p in currentPlacements) {
      placedRows.add(p.row);
      placedCols.add(p.col);
      placedRegions.add(puzzle.getRegionAt(p));
      cand.setFalse(p.row, p.col);
      for (int r = 0; r < size; r++) {
        cand.setFalse(r, p.col);
      }
      for (int c = 0; c < size; c++) {
        cand.setFalse(p.row, c);
      }
      for (final nb in p.kingNeighbors(size)) {
        cand.setFalse(nb.row, nb.col);
      }
    }
    for (final m in candidateMarks) {
      cand.setFalse(m.row, m.col);
    }

    // ---- 1. Forced placements: line with one remaining legal cell ----
    for (int r = 0; r < size; r++) {
      if (placedRows.contains(r)) continue;
      final cells = _lineCells(puzzle, cand, row: r);
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
    for (int c = 0; c < size; c++) {
      if (placedCols.contains(c)) continue;
      final cells = _lineCells(puzzle, cand, col: c);
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
    for (int reg = 0; reg < size; reg++) {
      if (placedRegions.contains(reg)) continue;
      final cells = _lineCells(puzzle, cand, region: reg);
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

    // ---- 2. Forced eliminations: "poison" cells ----
    // A cell X cannot be a queen if doing so would leave an unplaced line
    // (other than X's own) with no legal cell left.
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (!cand.get(r, c)) continue;
        final pos = Position(r, c);
        if (_wouldEmptyALine(
            puzzle, cand, pos, placedRows, placedCols, placedRegions)) {
          deductions.add(Deduction(
            explanation: _poisonExplanation(puzzle, pos),
            affectedCells: [pos],
            isElimination: true,
            type: DeductionType.forcedFromRegion,
          ));
        }
      }
    }

    return deductions;
  }

  /// Cells of a row/column/region that can still hold a queen.
  static List<Position> _lineCells(
    Puzzle puzzle,
    _BoardCandidates cand, {
    int? row,
    int? col,
    int? region,
  }) {
    final size = puzzle.size;
    final result = <Position>[];
    for (int r = 0; r < size; r++) {
      if (row != null && r != row) continue;
      for (int c = 0; c < size; c++) {
        if (col != null && c != col) continue;
        if (region != null && puzzle.getRegionAtCoords(r, c) != region) {
          continue;
        }
        if (cand.get(r, c)) result.add(Position(r, c));
      }
    }
    return result;
  }

  /// True when queen placement at [pos] would strip every legal cell from at
  /// least one *other* unplaced row, column or region.
  static bool _wouldEmptyALine(
    Puzzle puzzle,
    _BoardCandidates cand,
    Position pos,
    Set<int> placedRows,
    Set<int> placedCols,
    Set<int> placedRegions,
  ) {
    final size = puzzle.size;

    bool lineHasSurvivor(List<Position> cells) {
      for (final cell in cells) {
        if (cand.get(cell.row, cell.col) &&
            !_eliminatedBy(puzzle, cell, pos)) {
          return true;
        }
      }
      return false;
    }

    for (int r = 0; r < size; r++) {
      if (r == pos.row || placedRows.contains(r)) continue;
      if (!lineHasSurvivor(_lineCells(puzzle, cand, row: r))) return true;
    }
    for (int c = 0; c < size; c++) {
      if (c == pos.col || placedCols.contains(c)) continue;
      if (!lineHasSurvivor(_lineCells(puzzle, cand, col: c))) return true;
    }
    for (int reg = 0; reg < size; reg++) {
      if (reg == puzzle.getRegionAt(pos) || placedRegions.contains(reg)) {
        continue;
      }
      if (!lineHasSurvivor(_lineCells(puzzle, cand, region: reg))) return true;
    }
    return false;
  }

  static String _poisonExplanation(Puzzle puzzle, Position pos) {
    final region = puzzle.getRegionAt(pos) + 1;
    return 'A queen at (${pos.row + 1}, ${pos.col + 1}) would leave another '
        'row, column or region with no possible position. This cell can never '
        'hold a queen — cross it out (region $region).';
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
    int eliminationCount = 0;
    int rounds = 0;
    int longestChain = 0;
    int currentRun = 0;
    int maxCandidateSetSize = 0;
    final size = puzzle.size;

    while (placements.length < size) {
      final deductions = analyze(puzzle, placements, marks);

      // Track the widest candidate pool seen while reasoning.
      final pool = _maxLineCandidates(puzzle, placements, marks);
      if (pool > maxCandidateSetSize) maxCandidateSetSize = pool;

      if (deductions.isEmpty) {
        guessesRequired++;
        break;
      }

      rounds++;
      int placedThisRound = 0;
      for (final d in deductions) {
        if (d.isElimination) {
          marks.addAll(d.affectedCells);
          eliminationCount++;
        } else if (d.suggestedQueen != null &&
            !placements.contains(d.suggestedQueen)) {
          placements.add(d.suggestedQueen!);
          placedThisRound++;
        }
      }

      if (placedThisRound > 0) {
        currentRun += placedThisRound;
        if (currentRun > longestChain) longestChain = currentRun;
      } else {
        currentRun = 0;
      }
      if (deductions.every((d) => d.isElimination)) currentRun = 0;
    }

    final isSolved = ConstraintEngine.isSolved(puzzle, placements);
    return AnalysisResult(
      placements: placements,
      guessesRequired: guessesRequired,
      solvedByDeduction: isSolved && guessesRequired == 0,
      totalDeductions: placements.length + eliminationCount,
      eliminationCount: eliminationCount,
      rounds: rounds,
      longestChain: longestChain,
      maxCandidateSetSize: maxCandidateSetSize,
    );
  }

  /// Largest legal-cell count on any unplaced row/column/region for the
  /// current board state (used as a difficulty signal).
  static int _maxLineCandidates(
    Puzzle puzzle,
    List<Position> placements,
    Set<Position> marks,
  ) {
    final size = puzzle.size;
    final placedRows = <int>{};
    final placedCols = <int>{};
    final placedRegions = <int>{};
    for (final p in placements) {
      placedRows.add(p.row);
      placedCols.add(p.col);
      placedRegions.add(puzzle.getRegionAt(p));
    }

    int maxCount = 0;
    int countLine({int? row, int? col, int? region}) {
      int count = 0;
      for (int r = 0; r < size; r++) {
        if (row != null && r != row) continue;
        for (int c = 0; c < size; c++) {
          if (col != null && c != col) continue;
          if (region != null && puzzle.getRegionAtCoords(r, c) != region) {
            continue;
          }
          final pos = Position(r, c);
          if (placements.contains(pos)) continue;
          if (marks.contains(pos)) continue;
          if (ConstraintEngine.isValidQueenPlacement(
              puzzle, pos, placements)) {
            count++;
          }
        }
      }
      return count;
    }

    for (int r = 0; r < size; r++) {
      if (placedRows.contains(r)) continue;
      final c = countLine(row: r);
      if (c > maxCount) maxCount = c;
    }
    for (int c = 0; c < size; c++) {
      if (placedCols.contains(c)) continue;
      final n = countLine(col: c);
      if (n > maxCount) maxCount = n;
    }
    for (int reg = 0; reg < size; reg++) {
      if (placedRegions.contains(reg)) continue;
      final n = countLine(region: reg);
      if (n > maxCount) maxCount = n;
    }
    return maxCount;
  }
}

class AnalysisResult {
  final List<Position> placements;
  final int guessesRequired;
  final bool solvedByDeduction;

  /// Total number of placement + elimination steps found before stalling.
  final int totalDeductions;

  /// Number of forced-elimination cells crossed out during deduction.
  final int eliminationCount;

  /// Number of fixpoint iterations performed (reasoning depth).
  final int rounds;

  /// Longest run of consecutive forced placements.
  final int longestChain;

  /// Largest candidate pool observed on any single row/column/region.
  final int maxCandidateSetSize;

  const AnalysisResult({
    required this.placements,
    required this.guessesRequired,
    required this.solvedByDeduction,
    required this.totalDeductions,
    required this.eliminationCount,
    required this.rounds,
    required this.longestChain,
    required this.maxCandidateSetSize,
  });
}