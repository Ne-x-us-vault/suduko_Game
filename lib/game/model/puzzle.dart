import 'package:flutter/foundation.dart';
import 'difficulty.dart';
import 'position.dart';

/// A static, immutable puzzle definition.
///
/// Player progress is never stored here — see `GameState`. Storing the
/// definition separately from mutable player state means a move/undo/redo
/// never corrupts the puzzle itself.
@immutable
class Puzzle {
  /// Stable, reproducible identity (seed + size + generator version).
  final String id;
  final int size;
  final List<List<int>> regionMap; // regionId at [row][col], in 0..size-1
  final List<Position> solution;
  final int seed;
  final int generatorVersion;
  final DifficultyScore difficultyScore;

  const Puzzle({
    required this.id,
    required this.size,
    required this.regionMap,
    required this.solution,
    required this.seed,
    required this.generatorVersion,
    required this.difficultyScore,
  });

  int getRegionAt(Position pos) => regionMap[pos.row][pos.col];

  int getRegionAtCoords(int row, int col) => regionMap[row][col];

  /// Difficulty facet for display & sorting.
  Difficulty get difficulty => difficultyScore.difficulty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'size': size,
        'regionMap': regionMap.map((r) => r.toList()).toList(),
        'solution': solution.map((p) => [p.row, p.col]).toList(),
        'seed': seed,
        'generatorVersion': generatorVersion,
        'difficultyScore': difficultyScore.toJson(),
      };

  factory Puzzle.fromJson(Map<String, dynamic> json) {
    final rawRows = json['regionMap'] as List;
    final rows = rawRows
        .map((r) => (r as List).cast<int>().toList())
        .toList();
    final sol = (json['solution'] as List)
        .map((p) {
          final parts = p as List;
          return Position(
            (parts[0] as num).toInt(),
            (parts[1] as num).toInt(),
          );
        })
        .toList();
    return Puzzle(
      id: json['id'] as String,
      size: json['size'] as int,
      regionMap: rows,
      solution: sol,
      seed: json['seed'] as int,
      generatorVersion: json['generatorVersion'] as int,
      difficultyScore: DifficultyScore.fromJson(
          json['difficultyScore'] as Map<String, dynamic>? ?? {}),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Puzzle && runtimeType == other.runtimeType && id == other.id;
  }

  @override
  int get hashCode => Object.hash(runtimeType, id);
}