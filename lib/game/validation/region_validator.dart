import '../model/position.dart';
import '../model/puzzle.dart';

class RegionValidator {
  static bool isValidRegionLayout(Puzzle puzzle) {
    int size = puzzle.size;
    
    // Check: Exactly N regions
    Set<int> regionsFound = {};
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        regionsFound.add(puzzle.regionMap[r][c]);
      }
    }
    if (regionsFound.length != size) return false;

    // Check: Every region is orthogonally connected
    for (int regionId in regionsFound) {
      if (!_isConnected(puzzle, regionId)) return false;
    }

    return true;
  }

  static bool _isConnected(Puzzle puzzle, int regionId) {
    int size = puzzle.size;
    Position? startPos;
    int totalCellsInRegion = 0;

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (puzzle.regionMap[r][c] == regionId) {
          if (startPos == null) startPos = Position(r, c);
          totalCellsInRegion++;
        }
      }
    }

    if (startPos == null) return false;

    // BFS to find all reachable cells in the region
    Set<Position> visited = {startPos};
    List<Position> queue = [startPos];

    while (queue.isNotEmpty) {
      Position curr = queue.removeAt(0);
      for (var neighbor in _getNeighbors(curr, size)) {
        if (puzzle.regionMap[neighbor.row][neighbor.col] == regionId && !visited.contains(neighbor)) {
          visited.add(neighbor);
          queue.add(neighbor);
        }
      }
    }

    return visited.length == totalCellsInRegion;
  }

  static List<Position> _getNeighbors(Position pos, int size) {
    List<Position> neighbors = [];
    if (pos.row > 0) neighbors.add(Position(pos.row - 1, pos.col));
    if (pos.row < size - 1) neighbors.add(Position(pos.row + 1, pos.col));
    if (pos.col > 0) neighbors.add(Position(pos.row, pos.col - 1));
    if (pos.col < size - 1) neighbors.add(Position(pos.row, pos.col + 1));
    return neighbors;
  }
}
