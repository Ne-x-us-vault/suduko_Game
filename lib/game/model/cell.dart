import 'package:flutter/foundation.dart';
import 'position.dart';

/// A single static board cell: its address and its region id.
/// Immutable. Player state is stored separately (see GameState).
@immutable
class Cell {
  final Position position;
  final int regionId;

  const Cell({required this.position, required this.regionId});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Cell &&
            runtimeType == other.runtimeType &&
            position == other.position &&
            regionId == other.regionId;
  }

  @override
  int get hashCode => Object.hash(runtimeType, position, regionId);

  @override
  String toString() => 'Cell($position, r$regionId)';
}