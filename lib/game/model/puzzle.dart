import 'package:flutter/foundation.dart';
import 'position.dart';

enum Difficulty { easy, medium, hard, expert }

@immutable
class Puzzle {
  final String id;
  final int size;
  final List<List<int>> regionMap; // regionId at [row][col]
  final List<Position> solution;
  final int seed;
  final int generatorVersion;
  final Difficulty difficulty;
  final Map<String, dynamic> difficultyMetrics;

  const Puzzle({
    required this.id,
    required this.size,
    required this.regionMap,
    required this.solution,
    required this.seed,
    required this.generatorVersion,
    required this.difficulty,
    required this.difficultyMetrics,
  });

  // Helper to get region ID for a position
  int getRegionAt(Position pos) => regionMap[pos.row][pos.col];
}
