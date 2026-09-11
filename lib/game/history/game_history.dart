import '../model/position.dart';

enum ActionType { placeQueen, removeQueen, markCandidate, removeCandidate }

class GameAction {
  final ActionType type;
  final Position position;
  final bool isAuto;

  GameAction({required this.type, required this.position, this.isAuto = false});
}

class GameHistory {
  final List<GameAction> _undoStack = [];
  final List<GameAction> _redoStack = [];

  void push(GameAction action) {
    _undoStack.add(action);
    _redoStack.clear();
  }

  GameAction? undo() {
    if (_undoStack.isEmpty) return null;
    final action = _undoStack.removeLast();
    _redoStack.add(action);
    return action;
  }

  GameAction? redo() {
    if (_redoStack.isEmpty) return null;
    final action = _redoStack.removeLast();
    _undoStack.add(action);
    return action;
  }
}
