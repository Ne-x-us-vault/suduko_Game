import 'package:flutter/foundation.dart';

import '../game/hints/hint_service.dart';
import '../game/model/game_mode.dart';
import '../game/model/position.dart';
import '../game/model/puzzle.dart';
import '../game/validation/constraint_engine.dart';

/// Mutable player board state captured for undo/redo.
/// Auto marks are *derived* from queens, so they are not snapshotted.
@immutable
class BoardSnapshot {
  final List<Position> queens;
  final Set<Position> manualMarks;
  final int mistakes;
  final int hintsUsed;

  const BoardSnapshot({
    required this.queens,
    required this.manualMarks,
    required this.mistakes,
    required this.hintsUsed,
  });

  @override
  String toString() =>
      'BoardSnapshot(q=${queens.length}, m=$mistakes, h=$hintsUsed)';
}

/// Derives automatic candidate marks from queen placements: every queen marks
/// its entire row, entire column, and all 8 neighbors. Occupied queen cells
/// are never marked.
Set<Position> computeAutoMarks(Puzzle puzzle, List<Position> queens) {
  final marks = <Position>{};
  for (final q in queens) {
    for (int c = 0; c < puzzle.size; c++) {
      if (c != q.col) marks.add(Position(q.row, c));
    }
    for (int r = 0; r < puzzle.size; r++) {
      if (r != q.row) marks.add(Position(r, q.col));
    }
    marks.addAll(q.kingNeighbors(puzzle.size));
  }
  marks.removeWhere(queens.contains);
  return marks;
}

/// Immutable snapshot of all mutable game state.
@immutable
class GameState {
  final Puzzle puzzle;
  final List<Position> queens;
  final Set<Position> manualMarks;

  /// Derived, never manually editable — recomputed from [queens].
  final Set<Position> autoMarks;
  final int mistakes;
  final int hintsUsed;
  final bool isPaused;
  final Duration elapsed;
  final bool isStrict;
  final bool isSolved;
  final GameMode mode;
  final bool showMistakes;
  final Set<Position> conflictHighlight;
  final HintResult? activeHint;
  final String? dailyDate;

  const GameState({
    required this.puzzle,
    required this.queens,
    required this.manualMarks,
    required this.autoMarks,
    required this.mistakes,
    required this.hintsUsed,
    required this.isPaused,
    required this.elapsed,
    required this.isStrict,
    required this.isSolved,
    required this.mode,
    required this.showMistakes,
    required this.conflictHighlight,
    this.activeHint,
    this.dailyDate,
  });

  bool get hasUndoableActions => queens.isNotEmpty || manualMarks.isNotEmpty;

  Set<Position> get allMarks => {...manualMarks, ...autoMarks};

  bool hasQueen(Position p) => queens.contains(p);
  bool isManualMarked(Position p) => manualMarks.contains(p);

  /// Creates an initial state for a fresh game.
  factory GameState.initial({
    required Puzzle puzzle,
    required GameMode mode,
    required bool isStrict,
    required bool showMistakes,
    String? dailyDate,
  }) {
    return GameState(
      puzzle: puzzle,
      queens: const [],
      manualMarks: const {},
      autoMarks: const {},
      mistakes: 0,
      hintsUsed: 0,
      isPaused: false,
      elapsed: Duration.zero,
      isStrict: isStrict,
      isSolved: false,
      mode: mode,
      showMistakes: showMistakes,
      conflictHighlight: const {},
      dailyDate: dailyDate,
    );
  }

  GameState copyWith({
    List<Position>? queens,
    Set<Position>? manualMarks,
    Set<Position>? autoMarks,
    int? mistakes,
    int? hintsUsed,
    bool? isPaused,
    Duration? elapsed,
    bool? isSolved,
    Set<Position>? conflictHighlight,
    HintResult? activeHint,
    bool clearHint = false,
  }) {
    return GameState(
      puzzle: puzzle,
      queens: queens ?? this.queens,
      manualMarks: manualMarks ?? this.manualMarks,
      autoMarks: autoMarks ?? this.autoMarks,
      mistakes: mistakes ?? this.mistakes,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      isPaused: isPaused ?? this.isPaused,
      elapsed: elapsed ?? this.elapsed,
      isStrict: isStrict,
      isSolved: isSolved ?? this.isSolved,
      mode: mode,
      showMistakes: showMistakes,
      conflictHighlight: conflictHighlight ?? this.conflictHighlight,
      activeHint: clearHint ? null : (activeHint ?? this.activeHint),
      dailyDate: dailyDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'queens': queens.map((p) => [p.row, p.col]).toList(),
        'manualMarks': manualMarks.map((p) => [p.row, p.col]).toList(),
        'mistakes': mistakes,
        'hintsUsed': hintsUsed,
        'isPaused': isPaused,
        'elapsedSeconds': elapsed.inSeconds,
        'isStrict': isStrict,
        'isSolved': isSolved,
        'mode': mode.name,
        'showMistakes': showMistakes,
        'dailyDate': dailyDate,
      };

  /// Restores a session. Auto marks and conflict highlight are fields that
  /// were persisted too, but we recompute them for safety.
  factory GameState.restoreFromJson(Puzzle puzzle, Map<String, dynamic> json) {
    final queens = _deserializePositions(json['queens']);
    final isSolved = json['isSolved'] as bool? ?? false;
    return GameState(
      puzzle: puzzle,
      queens: queens,
      manualMarks: _deserializePositions(json['manualMarks']).toSet(),
      autoMarks: computeAutoMarks(puzzle, queens),
      mistakes: json['mistakes'] as int? ?? 0,
      hintsUsed: json['hintsUsed'] as int? ?? 0,
      isPaused: json['isPaused'] as bool? ?? false,
      elapsed: Duration(seconds: json['elapsedSeconds'] as int? ?? 0),
      isStrict: json['isStrict'] as bool? ?? false,
      isSolved: isSolved,
      mode: GameModeX.fromName(json['mode'] as String?),
      showMistakes: json['showMistakes'] as bool? ?? true,
      conflictHighlight: isSolved ||
              !(json['showMistakes'] as bool? ?? true)
          ? const {}
          : ConstraintEngine.getConflicts(puzzle, queens),
      dailyDate: json['dailyDate'] as String?,
    );
  }

  static List<Position> _deserializePositions(dynamic value) {
    if (value is! List) return [];
    return value
        .map((p) {
          final parts = p as List;
          return Position(
            (parts[0] as num).toInt(),
            (parts[1] as num).toInt(),
          );
        })
        .toList();
  }
}