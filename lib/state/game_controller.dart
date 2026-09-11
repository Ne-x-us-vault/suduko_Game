import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utilities/game_timer.dart';
import '../game/hints/hint_service.dart';
import '../game/history/game_history.dart';
import '../game/model/game_mode.dart';
import '../game/model/position.dart';
import '../game/model/puzzle.dart';
import '../game/validation/constraint_engine.dart';
import 'game_state.dart';

/// Result of attempting to place a queen (for UI feedback).
enum PlacementResult { placed, rejectedStrict, noGame, solved }

/// Owns mutable game state, the in-game timer, and undo/redo.
class GameController extends StateNotifier<GameState?> {
  GameController() : super(null) {
    _timer = GameTimer(onTick: _onTick);
  }

  late final GameTimer _timer;
  final SnapshotHistory<BoardSnapshot> _history = SnapshotHistory();
  GameMode _mode = GameMode.quickPlay;
  String? _dailyDate;
  bool _isStrict = false;
  bool _showMistakes = true;

  /// Fired exactly once per completion (unsolved → solved).
  void Function(GameMode mode, String? dailyDate)? onCompleted;
  bool _completionHandled = false;

  GameMode get mode => _mode;
  String? get dailyDate => _dailyDate;

  /// Public alias for the current [GameState] (accesses [StateNotifier.state]).
  GameState? get current => state;

  /// Optional hook the app uses to persist the active session (debounced).
  void Function()? onPersistRequested;

  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;
  GameTimer get timer => _timer;

  void _notifyPersist() => onPersistRequested?.call();

  void _onTick(Duration elapsed) {
    final s = state;
    if (s == null || s.isPaused || s.isSolved) return;
    state = s.copyWith(elapsed: elapsed);
  }

  void _configure({
    required GameMode mode,
    required bool strict,
    required bool showMistakes,
    String? dailyDate,
  }) {
    _mode = mode;
    _isStrict = strict;
    _showMistakes = showMistakes;
    _dailyDate = dailyDate;
  }

  void startNewGame(
    Puzzle puzzle, {
    GameMode mode = GameMode.quickPlay,
    bool strict = false,
    bool showMistakes = true,
    String? dailyDate,
  }) {
    _configure(mode: mode, strict: strict, showMistakes: showMistakes, dailyDate: dailyDate);
    _history.clear();
    _completionHandled = false;
    _timer.stop();
    state = GameState.initial(
      puzzle: puzzle,
      mode: mode,
      isStrict: strict,
      showMistakes: showMistakes,
      dailyDate: dailyDate,
    );
    _pushSnapshot();
    _timer.start();
    _notifyPersist();
  }

  /// Restores an in-progress game session (e.g. app relaunch).
  void restoreGame(GameState gameState) {
    _configure(
      mode: gameState.mode,
      strict: gameState.isStrict,
      showMistakes: gameState.showMistakes,
      dailyDate: gameState.dailyDate,
    );
    _history.clear();
    _history.push(BoardSnapshot(
      queens: List.of(gameState.queens),
      manualMarks: Set.of(gameState.manualMarks),
      mistakes: gameState.mistakes,
      hintsUsed: gameState.hintsUsed,
    ));
    _completionHandled = gameState.isSolved;
    state = gameState;
    _timer.stop();
    if (!gameState.isSolved) {
      _timer.setElapsed(gameState.elapsed);
      if (gameState.isPaused) {
        _timer.pause();
      } else {
        _timer.start();
      }
    }
    _notifyPersist();
  }

  void _pushSnapshot() {
    final s = state;
    if (s == null) return;
    _history.push(BoardSnapshot(
      queens: List.of(s.queens),
      manualMarks: Set.of(s.manualMarks),
      mistakes: s.mistakes,
      hintsUsed: s.hintsUsed,
    ));
  }

  /// Refreshes derived fields (auto marks + conflicts) from the given
  /// snapshot, preserving puzzle/mode/strictness.
  void _applySnapshots(BoardSnapshot snapshot) {
    final s = state;
    if (s == null) return;
    final autoMarks = computeAutoMarks(s.puzzle, snapshot.queens);
    final conflicts = _showMistakes
        ? ConstraintEngine.getConflicts(s.puzzle, snapshot.queens)
        : const <Position>{};
    state = s.copyWith(
      queens: List.of(snapshot.queens),
      manualMarks: Set.of(snapshot.manualMarks),
      autoMarks: autoMarks,
      mistakes: snapshot.mistakes,
      hintsUsed: snapshot.hintsUsed,
      conflictHighlight: conflicts,
      clearHint: true,
    );
  }

  void _applyBoardState({
    required List<Position> queens,
    required Set<Position> manualMarks,
    required int mistakes,
  }) {
    final s = state!;
    final autoMarks = computeAutoMarks(s.puzzle, queens);
    final conflicts = _showMistakes
        ? ConstraintEngine.getConflicts(s.puzzle, queens)
        : const <Position>{};
    state = s.copyWith(
      queens: queens,
      manualMarks: manualMarks,
      autoMarks: autoMarks,
      mistakes: mistakes,
      conflictHighlight: conflicts,
      clearHint: true,
    );
  }

  PlacementResult placeQueen(Position position) {
    final s = state;
    if (s == null) return PlacementResult.noGame;
    if (s.isSolved) return PlacementResult.solved;
    if (s.isPaused) return PlacementResult.noGame;

    // Tapping a placed queen removes it.
    if (s.hasQueen(position)) {
      final queens = List<Position>.from(s.queens)..remove(position);
      final marks = Set<Position>.from(s.manualMarks);
      _applyBoardState(queens: queens, manualMarks: marks, mistakes: s.mistakes);
      _pushSnapshot();
      _notifyPersist();
      return PlacementResult.placed;
    }

    final isValid = ConstraintEngine.isValidQueenPlacement(
      s.puzzle,
      position,
      s.queens,
    );

    // Strict mode: block illegal placements entirely.
    if (_isStrict && !isValid) {
      return PlacementResult.rejectedStrict;
    }

    // Place (replacing any manual mark on the cell).
    final marks = Set<Position>.from(s.manualMarks)..remove(position);
    final queens = List<Position>.from(s.queens)..add(position);
    final mistakes = isValid ? s.mistakes : s.mistakes + 1;
    _applyBoardState(queens: queens, manualMarks: marks, mistakes: mistakes);
    _pushSnapshot();
    _checkSolved();
    return PlacementResult.placed;
  }

  void toggleCandidate(Position position) {
    final s = state;
    if (s == null || s.isSolved || s.isPaused) return;
    if (s.hasQueen(position)) return;

    final marks = Set<Position>.from(s.manualMarks);
    marks.contains(position) ? marks.remove(position) : marks.add(position);
    state = s.copyWith(manualMarks: marks, clearHint: true);
    _pushSnapshot();
    _notifyPersist();
  }

  void _checkSolved() {
    final s = state;
    if (s == null || s.isSolved) return;
    if (ConstraintEngine.isSolved(s.puzzle, s.queens)) {
      _timer.pause();
      state = s.copyWith(isSolved: true);
      if (!_completionHandled) {
        _completionHandled = true;
        onCompleted?.call(_mode, _dailyDate);
      }
      _notifyPersist();
    }
  }

  HintResult? useHint() {
    final s = state;
    if (s == null || s.isSolved || s.isPaused) return null;
    final hint = HintService.getHint(s.puzzle, s.queens, s.manualMarks);
    if (hint == null) return null;
    state = s.copyWith(hintsUsed: s.hintsUsed + 1, activeHint: hint);
    _notifyPersist();
    return hint;
  }

  void undo() {
    final snapshot = _history.undo();
    if (snapshot == null) return;
    _applySnapshots(snapshot);
    _notifyPersist();
    final s = state;
    if (s != null && s.isSolved) {
      final elapsed = s.elapsed;
      state = s.copyWith(isSolved: false);
      _timer.setElapsed(elapsed);
      _timer.resume();
    }
  }

  void redo() {
    final snapshot = _history.redo();
    if (snapshot == null) return;
    _applySnapshots(snapshot);
    _notifyPersist();
    _checkSolved();
  }

  void pause() {
    final s = state;
    if (s == null || s.isSolved) return;
    _timer.pause();
    state = s.copyWith(isPaused: true, elapsed: _timer.elapsed);
    _notifyPersist();
  }

  void resume() {
    final s = state;
    if (s == null || s.isSolved) return;
    _timer.start();
    _timer.setElapsed(s.elapsed);
    state = s.copyWith(isPaused: false);
    _notifyPersist();
  }

  void restart() {
    final s = state;
    if (s == null) return;
    startNewGame(
      s.puzzle,
      mode: _mode,
      strict: _isStrict,
      showMistakes: _showMistakes,
      dailyDate: _dailyDate,
    );
  }

  /// Abandons the current game entirely (no snapshot to restore).
  void clear() {
    _history.clear();
    _completionHandled = false;
    _timer.stop();
    state = null;
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }
}

final gameStateProvider =
    StateNotifierProvider<GameController, GameState?>((ref) {
  final controller = GameController();
  ref.onDispose(controller.dispose);
  return controller;
});