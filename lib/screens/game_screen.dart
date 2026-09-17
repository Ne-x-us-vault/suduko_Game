import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sudoku_game/models.dart';
import 'package:sudoku_game/theme.dart';
import 'package:sudoku_game/components/sudoku_board_widget.dart';
import 'package:sudoku_game/components/number_pad.dart';
import 'package:sudoku_game/features/sudoku/sudoku_generator.dart';

class GameScreen extends StatefulWidget {
  final Difficulty difficulty;

  const GameScreen({super.key, required this.difficulty});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late SudokuBoard _board;
  late Timer _timer;
  int _elapsedSeconds = 0;
  bool _notesMode = false;
  bool _gameComplete = false;
  int _hintsRemaining = 3;
  int _errorCount = 0;
  final List<UndoEntry> _undoStack = [];
  final FocusNode _focusNode = FocusNode();

  // Shake animation for errors
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );
    _startNewGame();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _startNewGame() {
    final result = SudokuGenerator.generatePuzzle(widget.difficulty);
    _board = SudokuBoard.fromPuzzle(result.puzzle, result.solution);
    _elapsedSeconds = 0;
    _notesMode = false;
    _gameComplete = false;
    _hintsRemaining = 3;
    _errorCount = 0;
    _undoStack.clear();
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer timer) {
    if (!_gameComplete) {
      setState(() {
        _elapsedSeconds++;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _errorFlashTimer?.cancel();
    _shakeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get _difficultyLabel {
    switch (widget.difficulty) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
      case Difficulty.expert:
        return 'Expert';
    }
  }

  // --- Cell interaction ---

  void _onCellTap(int row, int col) {
    if (_gameComplete) return;
    final cell = _board.cells[row][col];
    if (cell.isOriginal) {
      // Select original cells too - allows seeing peers
      _board.selectCell(row, col);
    } else {
      _board.selectCell(row, col);
    }
    _focusNode.requestFocus();
    setState(() {});
  }

  Timer? _errorFlashTimer;

  void _placeNumber(int number) {
    if (_gameComplete) return;
    final selected = _findSelectedCell();
    if (selected == null || selected.isOriginal) return;

    final row = selected.row;
    final col = selected.col;

    if (_notesMode) {
      _undoStack.add(UndoEntry(
        row: row,
        col: col,
        previousValue: selected.value,
        previousNotes: Set<int>.from(selected.notes),
      ));
      _board.toggleNote(row, col, number);
    } else {
      _undoStack.add(UndoEntry(
        row: row,
        col: col,
        previousValue: selected.value,
        previousNotes: Set<int>.from(selected.notes),
      ));
      _board.setValue(row, col, number);

      if (_board.checkError(row, col)) {
        _errorCount++;
        _showErrorFlash(row, col);
      }

      if (_board.isComplete && !_gameComplete) {
        _gameComplete = true;
        _timer.cancel();
        Future.delayed(const Duration(milliseconds: 600), _showWinDialog);
      }
    }
    setState(() {});
  }

  void _showErrorFlash(int row, int col) {
    _shakeController.forward(from: 0);
    HapticFeedback.mediumImpact();

    // Brief red flash, then clear
    _board.setError(row, col, true);
    _errorFlashTimer?.cancel();
    _errorFlashTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        _board.setError(row, col, false);
        setState(() {});
      }
    });
  }

  void _eraseCell() {
    if (_gameComplete) return;
    final selected = _findSelectedCell();
    if (selected == null || selected.isOriginal) return;

    _undoStack.add(UndoEntry(
      row: selected.row,
      col: selected.col,
      previousValue: selected.value,
      previousNotes: Set<int>.from(selected.notes),
    ));
    _board.clearCell(selected.row, selected.col);
    setState(() {});
  }

  void _undoMove() {
    if (_gameComplete || _undoStack.isEmpty) return;

    final entry = _undoStack.removeLast();

    if (entry.previousValue != 0) {
      _board.setValue(entry.row, entry.col, entry.previousValue);
      _board.setError(entry.row, entry.col, false);
    } else {
      _board.clearCell(entry.row, entry.col);
    }
    if (entry.previousNotes.isNotEmpty) {
      _board.cells[entry.row][entry.col] =
          _board.cells[entry.row][entry.col].copyWith(
            notes: entry.previousNotes,
          );
    }
    _board.selectCell(entry.row, entry.col);
    setState(() {});
  }

  void _toggleNotes() {
    setState(() {
      _notesMode = !_notesMode;
    });
    HapticFeedback.lightImpact();
  }

  void _useHint() {
    if (_gameComplete || _hintsRemaining <= 0) return;

    final emptyCells = <(int, int)>[];
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final cell = _board.cells[r][c];
        if (!cell.isOriginal && cell.isEmpty) {
          emptyCells.add((r, c));
        }
      }
    }

    if (emptyCells.isEmpty) return;

    final randomCell =
        emptyCells[DateTime.now().millisecond % emptyCells.length];
    final row = randomCell.$1;
    final col = randomCell.$2;

    _board.selectCell(row, col);
    _board.setValue(row, col, _board.getSolutionValue(row, col));
    _board.cells[row][col] = _board.cells[row][col].copyWith(isHint: true);
    _hintsRemaining--;

    if (_board.isComplete && !_gameComplete) {
      _gameComplete = true;
      _timer.cancel();
      Future.delayed(const Duration(milliseconds: 600), _showWinDialog);
    }
    setState(() {});
  }

  SudokuCell? _findSelectedCell() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_board.cells[r][c].isSelected) return _board.cells[r][c];
      }
    }
    return null;
  }

  Map<int, int> _getNumberCounts() {
    final counts = <int, int>{};
    for (int i = 1; i <= 9; i++) {
      counts[i] = 9;
    }
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final v = _board.cells[r][c].value;
        if (v != 0) {
          counts[v] = (counts[v] ?? 0) - 1;
        }
      }
    }
    return counts;
  }

  // --- Keyboard handling ---

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (_gameComplete) return KeyEventResult.ignored;

    final key = event.logicalKey;

    // Number keys
    if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      _placeNumber(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
      _placeNumber(2);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
      _placeNumber(3);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
      _placeNumber(4);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) {
      _placeNumber(5);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) {
      _placeNumber(6);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) {
      _placeNumber(7);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) {
      _placeNumber(8);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) {
      _placeNumber(9);
      return KeyEventResult.handled;
    }

    // Erase
    if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace) {
      _eraseCell();
      return KeyEventResult.handled;
    }

    // Notes toggle
    if (key == LogicalKeyboardKey.keyN) {
      _toggleNotes();
      return KeyEventResult.handled;
    }

    // Undo
    if (key == LogicalKeyboardKey.keyZ) {
      _undoMove();
      return KeyEventResult.handled;
    }

    // Hint
    if (key == LogicalKeyboardKey.keyH) {
      _useHint();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  // --- Dialogs ---

  void _showWinDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        backgroundColor: isDark ? AppColors.black : AppColors.white,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.black,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.emoji_events_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Puzzle Complete',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _formattedTime,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_difficultyLabel  \u00B7  $_errorCount errors',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.grey400 : AppColors.grey600,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark
                              ? AppColors.grey700
                              : AppColors.gridThin,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Home',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.white
                              : AppColors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(_startNewGame);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Play Again',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = _board.filledCount / 81;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _difficultyLabel,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.white : AppColors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.grey900 : AppColors.white,
                  borderRadius: BorderRadius.circular(0),
                  border: Border.all(
                    color: isDark
                        ? AppColors.grey800
                        : AppColors.gridThin,
                    width: 1,
                  ),
                ),
                child: Text(
                  _formattedTime,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: isDark ? AppColors.white : AppColors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Focus(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  // Progress
                  ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: isDark
                          ? AppColors.grey800
                          : AppColors.gridThin,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.black),
                      minHeight: 3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Board
                  Flexible(
                    child: AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                            _shakeController.isAnimating
                                ? (1 - _shakeAnimation.value) *
                                    4 *
                                    ((_shakeController.value * 6).toInt().isEven
                                        ? 1
                                        : -1)
                                : 0,
                            0,
                          ),
                          child: child,
                        );
                      },
                      child: SudokuBoardWidget(
                        board: _board,
                        onCellTap: _onCellTap,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Hint
                  GestureDetector(
                    onTap: _useHint,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: _hintsRemaining > 0
                            ? AppColors.white
                            : (isDark
                                ? AppColors.grey800
                                : AppColors.grey200),
                        borderRadius: BorderRadius.circular(0),
                        border: Border.all(
                          color: _hintsRemaining > 0
                              ? AppColors.black
                              : (isDark
                                  ? AppColors.grey700
                                  : AppColors.gridThin),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lightbulb_rounded,
                            size: 15,
                            color: _hintsRemaining > 0
                                ? AppColors.black
                                : (isDark ? AppColors.grey500 : AppColors.grey400),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Hints: $_hintsRemaining',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _hintsRemaining > 0
                                  ? AppColors.black
                                  : (isDark
                                      ? AppColors.grey500
                                      : AppColors.grey400),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Number pad
                  NumberPad(
                    onNumberTap: _placeNumber,
                    onErase: _eraseCell,
                    onUndo: _undoMove,
                    onNotesToggle: _toggleNotes,
                    notesMode: _notesMode,
                    numberCounts: _getNumberCounts(),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
