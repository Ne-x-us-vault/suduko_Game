import '../../core/utilities/seeded_random.dart';
import '../model/position.dart';

/// Procedural region generation.
///
/// Regions are grown simultaneously from the N solution-queen cells, which
/// guarantees:
///   • exactly N regions
///   • every region contains exactly one solution queen
///   • every region is orthogonally connected by construction
///   • full board coverage
///
/// To favour visually natural shapes we (a) grow smaller regions first
/// (balanced sizes) and (b) prefer frontier cells that are adjacent to the
/// growing region (compact growth). Correctness is still verified upstream by
/// `RegionValidator` + the solution counter.
class RegionGenerator {
  final SeededRandom _rng;

  RegionGenerator(this._rng);

  /// Returns null if the layout could not be produced (should be rare).
  List<List<int>>? generate(int size, List<Position> queens) {
    if (queens.length != size) return null;

    final map =
        List.generate(size, (_) => List<int>.filled(size, -1));
    final counts = List<int>.filled(size, 0);

    // Seed each region with its solution queen.
    for (int id = 0; id < size; id++) {
      final q = queens[id];
      map[q.row][q.col] = id;
      counts[id] = 1;
    }

    // Frontier: unassigned cells adjacent to at least one assigned cell.
    final frontier = <Position>{};
    for (final q in queens) {
      for (final nb in _orthogonal(q, size)) {
        if (map[nb.row][nb.col] == -1) frontier.add(nb);
      }
    }

    // regionMap: regions that still can grow (adjacent to a frontier cell).
    var guard = size * size * 4;
    while (frontier.isNotEmpty && guard-- > 0) {
      // Cells adjacent to each region.
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

      // Choose the smallest region that still has frontier cells (balanced).
      int? chosen;
      for (int rid = 0; rid < size; rid++) {
        if (regionFrontier[rid].isEmpty) continue;
        if (chosen == null || counts[rid] < counts[chosen]) {
          chosen = rid;
        }
      }
      if (chosen == null) {
        // Frontier cells exist but no region borders them — impossible for a
        // connected board; treat as failure.
        return null;
      }
      final rid = chosen;

      // Compactness: prefer the frontier cell of this region with the most
      // neighbors already belonging to it, then random among ties.
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

      // Assign.
      final row = best.row;
      final col = best.col;
      map[row][col] = rid;
      counts[rid]++;
      frontier.remove(best);
      for (final nb in _orthogonal(best, size)) {
        if (map[nb.row][nb.col] == -1) frontier.add(nb);
      }
    }

    if (frontier.isNotEmpty) return null; // couldn't fill the board

    return map;
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