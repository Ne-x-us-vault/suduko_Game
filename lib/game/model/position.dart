import 'package:flutter/foundation.dart';

@immutable
class Position {
  final int row;
  final int col;

  const Position(this.row, this.col);

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Position &&
            runtimeType == other.runtimeType &&
            row == other.row &&
            col == other.col;
  }

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => '(, )';
}
