import 'package:flutter/foundation.dart';

import '../model/position.dart';

/// A single user action for history/display purposes. Undo/redo is performed
/// by restoring full snapshots, so these are descriptive rather than
/// instructional.
enum ActionType { placeQueen, removeQueen, markCandidate, removeCandidate }

@immutable
class GameAction {
  final ActionType type;
  final Position position;
  final bool isAuto;

  const GameAction({
    required this.type,
    required this.position,
    this.isAuto = false,
  });

  @override
  String toString() => '${type.name}@$position${isAuto ? '(auto)' : ''}';
}

/// Old-style push/undo stack kept only for backward compatibility with paths
/// that log a linear history. Real undo/redo uses [SnapshotHistory].
class GameHistory {
  final List<GameAction> _stack = [];

  List<GameAction> get actions => List.unmodifiable(_stack);

  void push(GameAction action) => _stack.add(action);

  GameAction? get last => _stack.isEmpty ? null : _stack.last;

  void clear() => _stack.clear();
}

/// Full-snapshot undo/redo history. Restoring a snapshot restores the board,
/// marks, and mistake state exactly.
class SnapshotHistory<T> {
  final List<T> _undo = [];
  final List<T> _redo = [];

  T? get current => _undo.isEmpty ? null : _undo.last;

  bool get canUndo => _undo.length > 1;
  bool get canRedo => _redo.isNotEmpty;

  /// Records a new snapshot (after applying an action). Clears the redo
  /// branch. `undoStack` may be null to represent a void (initial) state.
  void push(T snapshot) {
    _undo.add(snapshot);
    _redo.clear();
  }

  /// Reverts to the previous snapshot. Returns null when nothing to undo.
  T? undo() {
    if (!canUndo) return null;
    final snapshot = _undo.removeLast();
    _redo.add(snapshot);
    return _undo.last;
  }

  /// Advances to the next snapshot. Returns null when nothing to redo.
  T? redo() {
    if (_redo.isEmpty) return null;
    final snapshot = _redo.removeLast();
    _undo.add(snapshot);
    return snapshot;
  }

  void clear() {
    _undo.clear();
    _redo.clear();
  }
}