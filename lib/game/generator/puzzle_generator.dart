import 'dart:math';
import '../model/position.dart';
import '../model/puzzle.dart';
import '../solver/queens_solver.dart';
import '../validation/constraint_engine.dart';
import '../validation/region_validator.dart';

class PuzzleGenerator {
  final Random _random;

  PuzzleGenerator([int? seed]) : _random = seed != null ? Random(seed) : Random();

  Puzzle generate(int size, Difficulty difficulty) {
    int attempts = 0;
    while (attempts < 2000) {
      attempts++;
      
      List<Position> solution = _generateValidQueenPlacement(size);
      if (solution == null) continue;

      List<List<int>> regionMap = _generateRegions(size, solution);
      if (regionMap == null) continue;

      Puzzle puzzle = Puzzle(
        id: 'gen_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
        size: size,
        regionMap: regionMap,
        solution: solution,
        seed: _random.nextInt(100000),
        generatorVersion: 1,
        difficulty: difficulty,
        difficultyMetrics: {'attempts': attempts},
      );

      if (QueensSolver.countSolutions(puzzle, limit: 2) == 1) {
        if (RegionValidator.isValidRegionLayout(puzzle)) {
          return puzzle;
        }
      }
    }
    throw Exception("Failed to generate a unique puzzle after 2000 attempts.");
  }

  List<Position>? _generateValidQueenPlacement(int size) {
    List<Position> placements = [];
    if (_placeQueensRecursive(size, 0, placements)) return placements;
    return null;
  }

  bool _placeQueensRecursive(int size, int row, List<Position> placements) {
    if (row == size) return true;

    List<int> cols = List.generate(size, (i) => i)..shuffle(_random);
    for (int col in cols) {
      Position pos = Position(row, col);
      if (_isValidQueenOnly(pos, placements)) {
        placements.add(pos);
        if (_placeQueensRecursive(size, row + 1, placements)) return true;
        placements.removeLast();
      }
    }
    return false;
  }

  bool _isValidQueenOnly(Position pos, List<Position> placements) {
    for (var p in placements) {
      if (p.row == pos.row || p.col == pos.col) return false;
      if ((p.row - pos.row).abs() <= 1 && (p.col - pos.col).abs() <= 1) return false;
    }
    return true;
  }

  List<List<int>>? _generateRegions(int size, List<Position> queens) {
    List<List<int>> map = List.generate(size, (_) => List.filled(size, -1));
    
    for (int i = 0; i < size; i++) {
      map[queens[i].row][queens[i].col] = i;
    }

    List<Position> unassigned = [];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (map[r][c] == -1) unassigned.add(Position(r, c));
      }
    }

    unassigned.shuffle(_random);

    while (unassigned.isNotEmpty) {
      Position curr = unassigned.removeAt(0);
      List<int> neighborRegions = _getNeighborRegions(curr, size, map);
      
      if (neighborRegions.isEmpty) return null;
      map[curr.row][curr.col] = neighborRegions[_random.nextInt(neighborRegions.length)];
    }

    return map;
  }

  List<int> _getNeighborRegions(Position pos, int size, List<List<int>> map) {
    List<int> regions = [];
    if (pos.row > 0 && map[pos.row - 1][pos.col] != -1) regions.add(map[pos.row - 1][pos.col]);
    if (pos.row < size - 1 && map[pos.row + 1][pos.col] != -1) regions.add(map[pos.row + 1][pos.col]);
    if (pos.col > 0 && map[pos.row][pos.col - 1] != -1) regions.add(map[pos.row][pos.col - 1]);
    if (pos.col < size - 1 && map[pos.row][pos.col + 1] != -1) regions.add(map[pos.row][pos.col + 1]);
    return regions.toSet().toList();
  }
}
