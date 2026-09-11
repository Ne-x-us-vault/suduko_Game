import '../model/position.dart';
import '../model/puzzle.dart';

/// Validates structural region layout: exactly N regions, every cell assigned,
/// every region orthogonally connected, full board coverage.

class RegionValidator {
  RegionValidator._();

  /// Returns null if valid, or an error description string.
  static String? validate(Puzzle puzzle) {
    final size = puzzle.size;

    // 1. Every cell has a valid region id, no invalid ids, full coverage.
    final Set<int> regionIds = {};
    final List<int> regionCellCounts = List.filled(size, 0);

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final rid = puzzle.regionMap[r][c];
        if (rid < 0 || rid >= size) return 'Invalid region id $rid at ($r,$c)';
        regionIds.add(rid);
        regionCellCounts[rid]++;
      }
    }

    // 2. Exactly N regions.
    if (regionIds.length != size) {
      return 'Expected $size regions, found ${regionIds.length}';
    }

    // 3. Every region has at least one cell (automatic if ids in 0..N-1 and
    //    all covered, but explicit for safety).
    for (int i = 0; i < size; i++) {
      if (regionCellCounts[i] == 0) return 'Region $i is empty';
    }

    // 4. Every region is orthogonally connected.
    for (int rid = 0; rid < size; rid++) {
      if (!_isConnected(puzzle, rid)) {
        return 'Region $rid is not orthogonally connected';
      }
    }

    return null;
  }

  static bool isValid(Puzzle puzzle) => validate(puzzle) == null;

  static bool _isConnected(Puzzle puzzle, int regionId) {
    final size = puzzle.size;
    Position? start;
    int count = 0;

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (puzzle.regionMap[r][c] == regionId) {
          start ??= Position(r, c);
          count++;
        }
      }
    }
    if (start == null || count == 0) return false;

    // BFS.
    final visited = <Position>{start};
    final queue = [start];
    while (queue.isNotEmpty) {
      final curr = queue.removeAt(0);
      for (final nb in _orthogonalNeighbors(curr, size)) {
        if (puzzle.regionMap[nb.row][nb.col] == regionId && visited.add(nb)) {
          queue.add(nb);
        }
      }
    }
    return visited.length == count;
  }

  static List<Position> _orthogonalNeighbors(Position pos, int size) {
    final result = <Position>[];
    if (pos.row > 0) result.add(Position(pos.row - 1, pos.col));
    if (pos.row < size - 1) result.add(Position(pos.row + 1, pos.col));
    if (pos.col > 0) result.add(Position(pos.row, pos.col - 1));
    if (pos.col < size - 1) result.add(Position(pos.row, pos.col + 1));
    return result;
  }
}