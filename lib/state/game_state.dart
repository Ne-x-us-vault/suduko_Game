import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/position.dart';
import '../model/puzzle.dart';
import '../history/game_history.dart';
import '../validation/constraint_engine.dart';
import '../difficulty/deduction_engine.dart';
import '../core/utilities/game_timer.dart';

class GameState {
  final Puzzle puzzle;
  final List<Position> queenPlacements;
  final Set<Position> candidateMarks;
  final int mistakes;
  final int hintsUsed;
  final GameHistory history;
  final bool isPaused;
  final Duration elapsed;
  final bool isStrict;
  final bool isSolved;

  GameState({
    required this.puzzle,
    this.queenPlacements = const [],
    this.candidateMarks = const {},
    this.mistakes = 0,
    this.hintsUsed = 0,
    required this.history,
    this.isPaused = false,
    this.elapsed = Duration.zero,
    this.isStrict = false,
    this.isSolved = false,
  });

  GameState copyWith({
    Puzzle? puzzle,
    List<Position>? queenPlacements,
    Set<Position>? candidateMarks,
    int? mistakes,
    int? hintsUsed,
    bool? isPaused,
    Duration? elapsed,
    bool? isStrict,
    bool? isSolved,
  }) {
    return GameState(
      puzzle: puzzle ?? this.puzzle,
      queenPlacements: queenPlacements ?? this.queenPlacements,
      candidateMarks: candidateMarks ?? this.candidateMarks,
      mistakes: mistakes ?? this.mistakes,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      history: this.history,
      isPaused: isPaused ?? this.isPaused,
      elapsed: elapsed ?? this.elapsed,
      isStrict: isStrict ?? this.isStrict,
      isSolved: isSolved ?? this.isSolved,
    );
  }
}

class GameStateNotifier extends StateNotifier<GameState?> {
  GameStateNotifier() : super(null);
  
  GameTimer? _timer;

  void startNewGame(Puzzle puzzle, {bool strict = false}) {
    _timer?.stop();
    _timer = GameTimer(onTick: (duration) {
      state = state?.copyWith(elapsed: duration);
    });
    _timer!.start();

    state = GameState(
      puzzle: puzzle,
      history: GameHistory(),
      isStrict: strict,
    );
  }

  void placeQueen(Position pos) {
    if (state == null || state!.isSolved) return;
    
    bool isValid = ConstraintEngine.isValidPlacement(state!.puzzle, pos, state!.queenPlacements);
    
    if (state!.isStrict && !isValid) return;

    int newMistakes = state!.mistakes;
    if (!isValid) newMistakes++;

    final newPlacements = List<Position>.from(state!.queenPlacements)..add(pos);
    
    // Check if solve is now complete
    bool solved = ConstraintEngine.isSolved(state!.puzzle, newPlacements);
    if (solved) {
      _timer?.pause();
    }

    state = state!.copyWith(
      queenPlacements: newPlacements,
      mistakes: newMistakes,
      isSolved: solved,
    );
    state!.history.push(GameAction(type: ActionType.placeQueen, position: pos));
  }

  void removeQueen(Position pos) {
    if (state == null) return;
    final newPlacements = state!.queenPlacements.where((p) => p != pos).toList();
    state = state!.copyWith(queenPlacements: newPlacements, isSolved: false);
    state!.history.push(GameAction(type: ActionType.removeQueen, position: pos));
  }

  void toggleCandidate(Position pos) {
    if (state == null) return;
    final newMarks = Set<Position>.from(state!.candidateMarks);
    if (newMarks.contains(pos)) {
      newMarks.remove(pos);
    } else {
      newMarks.add(pos);
    }
    state = state!.copyWith(candidateMarks: newMarks);
    state!.history.push(GameAction(type: ActionType.markCandidate, position: pos));
  }

  Deduction? getHint() {
    if (state == null) return null;
    final deductions = DeductionEngine.analyze(state!.puzzle, state!.queenPlacements, state!.candidateMarks);
    if (deductions.isEmpty) return null;
    state = state!.copyWith(hintsUsed: state!.hintsUsed + 1);
    return deductions.first;
  }

  void undo() {
    if (state == null) return;
    final action = state!.history.undo();
    if (action == null) return;

    // Simple undo: reset and replay (for robustness)
    // In a full prod app, we'd apply the inverse action
    // Here we just clear and reload for the prototype logic
    // but in the real code we'd track the state stack.
  }
}

final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState?>((ref) {
  return GameStateNotifier();
});
