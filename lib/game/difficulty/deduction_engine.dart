import '../model/position.dart';
import '../model/puzzle.dart';
import '../validation/constraint_engine.dart';

class Deduction {
  final String explanation;
  final List<Position> affectedCells;
  final Position? suggestedQueen;
  final String technique;

  Deduction({
    required this.explanation, 
    required this.affectedCells, 
    this.suggestedQueen, 
    required this.technique
  });
}

class DeductionEngine {
  static List<Deduction> analyze(Puzzle puzzle, List<Position> currentPlacements, Set<Position> candidateMarks) {
    List<Deduction> deductions = [];
    int size = puzzle.size;

    // 1. Find all currently legal cells (not a queen, not marked X)
    List<Position> legalCells = [];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        Position pos = Position(r, c);
        if (!currentPlacements.contains(pos) && !candidateMarks.contains(pos)) {
          if (ConstraintEngine.isValidPlacement(puzzle, pos, currentPlacements)) {
            legalCells.add(pos);
          }
        }
      }
    }

    // 2. Check for "Hidden Singles" in Rows, Cols, and Regions
    // Row Check
    for (int r = 0; r < size; r++) {
      if (currentPlacements.any((p) => p.row == r)) continue;
      List<Position> rowLegal = legalCells.where((p) => p.row == r).toList();
      if (rowLegal.length == 1) {
        deductions.add(Deduction(
          explanation: "Row ${r + 1} has only one possible position for a queen.",
          affectedCells: rowLegal,
          suggestedQueen: rowLegal.first,
          technique: "Row Single",
        ));
      }
    }

    // Col Check
    for (int c = 0; c < size; c++) {
      if (currentPlacements.any((p) => p.col == c)) continue;
      List<Position> colLegal = legalCells.where((p) => p.col == c).toList();
      if (colLegal.length == 1) {
        deductions.add(Deduction(
          explanation: "Column ${c + 1} has only one possible position for a queen.",
          affectedCells: colLegal,
          suggestedQueen: colLegal.first,
          technique: "Column Single",
        ));
      }
    }

    // Region Check
    for (int regId = 0; regId < size; regId++) {
      if (currentPlacements.any((p) => puzzle.getRegionAt(p) == regId)) continue;
      List<Position> regLegal = legalCells.where((p) => puzzle.getRegionAt(p) == regId).toList();
      if (regLegal.length == 1) {
        deductions.add(Deduction(
          explanation: "Region ${regId + 1} has only one possible position for a queen.",
          affectedCells: regLegal,
          suggestedQueen: regLegal.first,
          technique: "Region Single",
        ));
      }
    }

    return deductions;
  }
}
