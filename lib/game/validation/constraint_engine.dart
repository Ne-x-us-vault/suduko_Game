import '../model/position.dart';
import '../model/puzzle.dart';

class ConstraintEngine {
  /// Checks if placing a queen at [pos] is legal given current [placements]
  static bool isValidPlacement(Puzzle puzzle, Position pos, List<Position> placements) {
    // 1. Row constraint
    if (placements.any((p) => p.row == pos.row)) return false;

    // 2. Column constraint
    if (placements.any((p) => p.col == pos.col)) return false;

    // 3. Region constraint
    int regionId = puzzle.getRegionAt(pos);
    if (placements.any((p) => puzzle.getRegionAt(p) == regionId)) return false;

    // 4. Adjacency constraint (8 neighbors / King's move)
    for (var p in placements) {
      if ((p.row - pos.row).abs() <= 1 && (p.col - pos.col).abs() <= 1) {
        return false;
      }
    }

    return true;
  }

  /// Returns all conflicts for a given placement set
  static List<Position> getConflicts(Puzzle puzzle, List<Position> placements) {
    List<Position> conflicts = [];
    for (int i = 0; i < placements.length; i++) {
      Position p1 = placements[i];
      for (int j = i + 1; j < placements.length; j++) {
        Position p2 = placements[j];
        
        bool conflict = false;
        if (p1.row == p2.row) conflict = true;
        else if (p1.col == p2.col) conflict = true;
        else if (puzzle.getRegionAt(p1) == puzzle.getRegionAt(p2)) conflict = true;
        else if ((p1.row - p2.row).abs() <= 1 && (p1.col - p2.col).abs() <= 1) conflict = true;
        
        if (conflict) {
          conflicts.add(p1);
          conflicts.add(p2);
        }
      }
    }
    return conflicts.toSet().toList();
  }

  static bool isSolved(Puzzle puzzle, List<Position> placements) {
    if (placements.length != puzzle.size) return false;
    
    // If we have N queens and no conflicts, it's solved by definition of our constraints
    return getConflicts(puzzle, placements).isEmpty;
  }
}
