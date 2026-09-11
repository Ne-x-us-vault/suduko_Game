import 'package:flutter/foundation.dart';
import 'position.dart';

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
  int get hashCode => position.hashCode ^ regionId.hashCode;
}
