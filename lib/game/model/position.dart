import 'package:flutter/foundation.dart';

/// A board cell address. Immutable.
@immutable
class Position {
  final int row;
  final int col;

  const Position(this.row, this.col);

  /// Whether this position is inside a [size] x [size] board.
  bool inBounds(int size) => row >= 0 && row < size && col >= 0 && col < size;

  /// King's-move neighbors (all 8 directions), filtered by [size].
  List<Position> kingNeighbors(int size) {
    final result = <Position>[];
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final p = Position(row + dr, col + dc);
        if (p.inBounds(size)) result.add(p);
      }
    }
    return result;
  }

  /// Whether this position is within one king-move of [other].
  bool isKingAdjacentTo(Position other) =>
      (row - other.row).abs() <= 1 && (col - other.col).abs() <= 1;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Position &&
            runtimeType == other.runtimeType &&
            row == other.row &&
            col == other.col;
  }

  @override
  int get hashCode => Object.hash(runtimeType, row, col);

  @override
  String toString() => '($row, $col)';
}