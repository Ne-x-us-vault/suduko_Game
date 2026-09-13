import '../../core/utilities/seeded_random.dart';
import '../model/position.dart';

/// Procedural region generation with multiple strategies.
///
/// Each strategy produces different region layouts for the same solution,
/// increasing the chance of finding a uniquely solvable puzzle.
class RegionGenerator {
  final SeededRandom _rng;
  final int _strategy;

  RegionGenerator(this._rng, {int strategy = 0}) : _strategy = strategy;

  /// Returns null if the layout could not be produced.
  List<List<int>>? generate(int size, List<Position> queens) {
    if (queens.length != size) return null;

    switch (_strategy % 5) {
      case 0:
        return _growFromQueens(size, queens);
      case 1:
        return _snakeRegions(size, queens);
      case 2:
        return _spiralRegions(size, queens);
      case 3:
        return _checkerboardRegions(size, queens);
      case 4:
        return _voronoiRegions(size, queens);
      default:
        return _growFromQueens(size, queens);
    }
  }

  /// Original: grow regions outward from each solution queen.
  List<List<int>>? _growFromQueens(int size, List<Position> queens) {
    final map = List.generate(size, (_) => List<int>.filled(size, -1));
    final counts = List<int>.filled(size, 0);

    for (int id = 0; id < size; id++) {
      final q = queens[id];
      map[q.row][q.col] = id;
      counts[id] = 1;
    }

    final frontier = <Position>{};
    for (final q in queens) {
      for (final nb in _orthogonal(q, size)) {
        if (map[nb.row][nb.col] == -1) frontier.add(nb);
      }
    }

    var guard = size * size * 4;
    while (frontier.isNotEmpty && guard-- > 0) {
      final regionFrontier = List<List<Position>>.generate(size, (_) => []);
      for (final cell in frontier) {
        final adjacentRegions = <int>{};
        for (final nb in _orthogonal(cell, size)) {
          final rid = map[nb.row][nb.col];
          if (rid != -1) adjacentRegions.add(rid);
        }
        for (final rid in adjacentRegions) {
          regionFrontier[rid].add(cell);
        }
      }

      int? chosen;
      for (int rid = 0; rid < size; rid++) {
        if (regionFrontier[rid].isEmpty) continue;
        if (chosen == null || counts[rid] < counts[chosen]) {
          chosen = rid;
        }
      }
      if (chosen == null) return null;
      final rid = chosen;

      final cells = regionFrontier[rid];
      Position best = cells.first;
      int bestScore = -1;
      final ties = <Position>[];
      for (final cell in cells) {
        int score = 0;
        for (final nb in _orthogonal(cell, size)) {
          if (map[nb.row][nb.col] == rid) score++;
        }
        if (score > bestScore) {
          bestScore = score;
          ties.clear();
          ties.add(cell);
        } else if (score == bestScore) {
          ties.add(cell);
        }
      }
      best = _rng.pick(ties);

      final row = best.row;
      final col = best.col;
      map[row][col] = rid;
      counts[rid]++;
      frontier.remove(best);
      for (final nb in _orthogonal(best, size)) {
        if (map[nb.row][nb.col] == -1) frontier.add(nb);
      }
    }

    if (frontier.isNotEmpty) return null;
    return map;
  }

  /// Snake-like regions that weave through the board, creating more constraints.
  List<List<int>>? _snakeRegions(int size, List<Position> queens) {
    final map = List.generate(size, (_) => List<int>.filled(size, -1));
    final queenPos = {for (var i = 0; i < size; i++) queens[i]: i};

    // Create a Hamiltonian path through the board
    final path = _hamiltonianPath(size);
    if (path.length != size * size) return null;

    // Assign regions along the path, ensuring each queen gets its region
    var currentRegion = 0;

    for (int i = 0; i < path.length; i++) {
      final pos = path[i];
      final isQueen = queenPos.containsKey(pos);

      if (isQueen) {
        // This cell must belong to its queen's region
        map[pos.row][pos.col] = queenPos[pos]!;
        currentRegion = queenPos[pos]!;
      } else {
        map[pos.row][pos.col] = currentRegion;
      }
    }

    // Verify all regions have their queen
    for (int r = 0; r < size; r++) {
      final q = queens[r];
      if (map[q.row][q.col] != r) return null;
    }

    return _ensureConnectivity(map, size, queens);
  }

  /// Spiral regions from center outward.
  List<List<int>>? _spiralRegions(int size, List<Position> queens) {
    final map = List.generate(size, (_) => List<int>.filled(size, -1));
    final queenPos = {for (var i = 0; i < size; i++) queens[i]: i};

    // Generate spiral order from center
    final spiral = _spiralOrder(size);
    var currentRegion = 0;

    for (final pos in spiral) {
      final isQueen = queenPos.containsKey(pos);
      if (isQueen) {
        map[pos.row][pos.col] = queenPos[pos]!;
        currentRegion = queenPos[pos]!;
      } else {
        map[pos.row][pos.col] = currentRegion;
      }
    }

    // Verify
    for (int r = 0; r < size; r++) {
      final q = queens[r];
      if (map[q.row][q.col] != r) return null;
    }

    return _ensureConnectivity(map, size, queens);
  }

  /// Checkerboard-inspired regions.
  List<List<int>>? _checkerboardRegions(int size, List<Position> queens) {
    final map = List.generate(size, (_) => List<int>.filled(size, -1));
    final queenPos = {for (var i = 0; i < size; i++) queens[i]: i};

    // Use a space-filling curve (Hilbert-like) for region assignment
    final order = _spaceFillingOrder(size);

    var currentRegion = 0;
    for (final pos in order) {
      if (queenPos.containsKey(pos)) {
        map[pos.row][pos.col] = queenPos[pos]!;
        currentRegion = queenPos[pos]!;
      } else {
        map[pos.row][pos.col] = currentRegion;
      }
    }

    // Verify
    for (int r = 0; r < size; r++) {
      final q = queens[r];
      if (map[q.row][q.col] != r) return null;
    }

    return _ensureConnectivity(map, size, queens);
  }

  /// Voronoi-style regions based on distance to queens.
  List<List<int>>? _voronoiRegions(int size, List<Position> queens) {
    final map = List.generate(size, (_) => List<int>.filled(size, -1));

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final pos = Position(r, c);
        // Find closest queen (Manhattan distance)
        int bestDist = size * size;
        int bestId = 0;
        for (int id = 0; id < size; id++) {
          final q = queens[id];
          final dist = (pos.row - q.row).abs() + (pos.col - q.col).abs();
          if (dist < bestDist) {
            bestDist = dist;
            bestId = id;
          }
        }
        map[r][c] = bestId;
      }
    }

    // Ensure each queen's cell belongs to its region
    for (int id = 0; id < size; id++) {
      final q = queens[id];
      if (map[q.row][q.col] != id) {
        // Force it and adjust neighbors
        map[q.row][q.col] = id;
      }
    }

    return _ensureConnectivity(map, size, queens);
  }

  /// Ensure all regions are orthogonally connected (healing any that are not).
  List<List<int>>? _ensureConnectivity(
    List<List<int>> map, int size, List<Position> queens) {

    for (int pass = 0; pass < size; pass++) {
      int? bad;
      for (int rid = 0; rid < size; rid++) {
        if (!_isConnected(map, size, rid)) {
          bad = rid;
          break;
        }
      }
      if (bad == null) return map;
      final healed = _fixConnectivity(map, size, queens, bad);
      if (healed == null) return null;
    }
    return map;
  }

  List<List<int>>? _fixConnectivity(
    List<List<int>> map, int size, List<Position> queens, int badRegion) {
    // Rebuild the disconnected region: keep its largest orthogonal chunk and
    // re-attach every stranded cell to a neighbouring region. Re-attaching a
    // cell next to an existing, connected region keeps that target connected,
    // and the surviving chunk guarantees the bad region still exists.
    final cells = <Position>[];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (map[r][c] == badRegion) cells.add(Position(r, c));
      }
    }
    if (cells.isEmpty) return null;

    // Find the largest connected chunk via flood fill.
    final seen = <Position>{};
    Position? largestSeed;
    int largestSize = -1;
    final chunks = <List<Position>>[];
    for (final start in cells) {
      if (seen.contains(start)) continue;
      final chunk = <Position>[];
      final queue = [start];
      seen.add(start);
      while (queue.isNotEmpty) {
        final curr = queue.removeAt(0);
        chunk.add(curr);
        for (final nb in _orthogonal(curr, size)) {
          if (map[nb.row][nb.col] == badRegion && seen.add(nb)) {
            queue.add(nb);
          }
        }
      }
      chunks.add(chunk);
      if (chunk.length > largestSize) {
        largestSize = chunk.length;
        largestSeed = start;
      }
    }

    // Keep the largest chunk (marked by largestSeed's flood), reassign the
    // rest to an orthogonal neighbour of a different region.
    final keep = <Position>{};
    if (largestSeed != null) {
      final queue = [largestSeed];
      keep.add(largestSeed);
      while (queue.isNotEmpty) {
        final curr = queue.removeAt(0);
        for (final nb in _orthogonal(curr, size)) {
          if (map[nb.row][nb.col] == badRegion && keep.add(nb)) {
            queue.add(nb);
          }
        }
      }
    }

    for (final p in cells) {
      if (keep.contains(p)) continue;
      int? target;
      for (final nb in _orthogonal(p, size)) {
        final rid = map[nb.row][nb.col];
        if (rid != badRegion && rid >= 0 && rid < size) {
          target = rid;
          break;
        }
      }
      if (target == null) return null; // isolated, can't heal
      map[p.row][p.col] = target;
    }

    return map;
  }

  bool _isConnected(List<List<int>> map, int size, int regionId) {
    Position? start;
    int count = 0;
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (map[r][c] == regionId) {
          start ??= Position(r, c);
          count++;
        }
      }
    }
    if (start == null || count == 0) return false;

    final visited = <Position>{start};
    final queue = [start];
    while (queue.isNotEmpty) {
      final curr = queue.removeAt(0);
      for (final nb in _orthogonal(curr, size)) {
        if (map[nb.row][nb.col] == regionId && visited.add(nb)) {
          queue.add(nb);
        }
      }
    }
    return visited.length == count;
  }

  /// Generate a Hamiltonian path covering all cells.
  List<Position> _hamiltonianPath(int size) {
    final path = <Position>[];
    // Simple serpentine path
    for (int r = 0; r < size; r++) {
      if (r % 2 == 0) {
        for (int c = 0; c < size; c++) {
          path.add(Position(r, c));
        }
      } else {
        for (int c = size - 1; c >= 0; c--) {
          path.add(Position(r, c));
        }
      }
    }
    return path;
  }

  /// Generate spiral order from center.
  List<Position> _spiralOrder(int size) {
    final result = <Position>[];
    int top = 0, bottom = size - 1, left = 0, right = size - 1;
    while (top <= bottom && left <= right) {
      for (int c = left; c <= right; c++) {
        result.add(Position(top, c));
      }
      top++;
      for (int r = top; r <= bottom; r++) {
        result.add(Position(r, right));
      }
      right--;
      if (top <= bottom) {
        for (int c = right; c >= left; c--) {
          result.add(Position(bottom, c));
        }
        bottom--;
      }
      if (left <= right) {
        for (int r = bottom; r >= top; r--) {
          result.add(Position(r, left));
        }
        left++;
      }
    }
    return result;
  }

  /// Generate space-filling curve order.
  List<Position> _spaceFillingOrder(int size) {
    // Simplified: use Morton (Z-order) curve
    final cells = <Position>[];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        cells.add(Position(r, c));
      }
    }
    // Sort by Morton code
    cells.sort((a, b) => _mortonCode(a).compareTo(_mortonCode(b)));
    return cells;
  }

  int _mortonCode(Position p) {
    // Interleave bits
    int code = 0;
    for (int i = 0; i < 16; i++) {
      code |= ((p.row >> i) & 1) << (2 * i);
      code |= ((p.col >> i) & 1) << (2 * i + 1);
    }
    return code;
  }

  static List<Position> _orthogonal(Position p, int size) {
    final result = <Position>[];
    if (p.row > 0) result.add(Position(p.row - 1, p.col));
    if (p.row < size - 1) result.add(Position(p.row + 1, p.col));
    if (p.col > 0) result.add(Position(p.row, p.col - 1));
    if (p.col < size - 1) result.add(Position(p.row, p.col + 1));
    return result;
  }
}