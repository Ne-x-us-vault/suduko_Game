import '../model/position.dart';
import '../model/puzzle.dart';
import '../validation/constraint_engine.dart';

class QueensSolver {
  static List<Position>? findOneSolution(Puzzle puzzle) {
    List<Position> placements = [];
    if (_solveRecursive(puzzle, 0, placements)) {
      return List.from(placements);
    }
    return null;
  }

  static int countSolutions(Puzzle puzzle, {int limit = 2}) {
    int count = 0;
    _countRecursive(puzzle, 0, [], () {
      count++;
      return count >= limit;
    });
    return count;
  }

  static bool _solveRecursive(Puzzle puzzle, int row, List<Position> placements) {
    if (row == puzzle.size) return true;

    for (int col = 0; col < puzzle.size; col++) {
      Position pos = Position(row, col);
      if (ConstraintEngine.isValidPlacement(puzzle, pos, placements)) {
        placements.add(pos);
        if (_solveRecursive(puzzle, row + 1, placements)) return true;
        placements.removeLast();
      }
    }
    return false;
  }

  static void _countRecursive(Puzzle puzzle, int row, List<Position> placements, bool Function() shouldStop) {
    if (row == puzzle.size) {
      if (shouldStop()) return;
      return;
    }

    for (int col = 0; col < puzzle.size; col++) {
      Position pos = Position(row, col);
      if (ConstraintEngine.isValidPlacement(puzzle, pos, placements)) {
        placements.add(pos);
        _countRecursive(puzzle, row + 1, placements, shouldStop);
        placements.removeLast();
        if (shouldStop()) return;
      }
    }
  }
}
