import 'dart:async';

import 'package:flutter/material.dart';
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

class _GameScreenState extends State<GameScreen> {
  late SudokuBoard _board;
  late Timer _timer;
  int _elapsedSeconds = 0;
  bool _notesMode = false;
  bool _gameComplete = false;
  int _hintsRemaining = 3;
  final List<UndoEntry> _undoStack = [];

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    final result = SudokuGenerator.generatePuzzle(widget.difficulty);
    _board = SudokuBoard.fromPuzzle(result.puzzle, result.solution);
    _elapsedSeconds = 0;
    _notesMode = false;
    _gameComplete = false;
    _hintsRemaining = 3;
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

  void _onCellTap(int row, int col) {
    if (_gameComplete) return;
    final cell = _board.cells[row][col];
    if (cell.isOriginal) return;
    _board.selectCell(row, col);
  }

  void _onNumberTap(int number) {
    if (_gameComplete) return;
    final selected = _findSelectedCell();
    if (selected == null) return;

    final row = selected.row;
    final col = selected.col;
    final cell = _board.cells[row][col];

    if (cell.isOriginal) return;

    if (_notesMode) {
      _undoStack.add(UndoEntry(
        row: row,
        col: col,
        previousValue: cell.value,
        previousNotes: Set<int>.from(cell.notes),
      ));
      _board.toggleNote(row, col, number);
    } else {
      _undoStack.add(UndoEntry(
        row: row,
        col: col,
        previousValue: cell.value,
        previousNotes: Set<int>.from(cell.notes),
      ));
      _board.setValue(row, col, number);

    if (_board.checkError(row, col)) {
        _board.setError(row, col, true);
      } else {
        _board.setError(row, col, false);
      }

      if (_board.isComplete && !_gameComplete) {
        _gameComplete = true;
        _timer.cancel();
        Future.delayed(const Duration(milliseconds: 500), () {
          _showWinDialog();
        });
      }
    }
    setState(() {});
  }

  void _onErase() {
    if (_gameComplete) return;
    final selected = _findSelectedCell();
    if (selected == null) return;
    if (selected.isOriginal) return;

    _undoStack.add(UndoEntry(
      row: selected.row,
      col: selected.col,
      previousValue: selected.value,
      previousNotes: Set<int>.from(selected.notes),
    ));
    _board.clearCell(selected.row, selected.col);
    setState(() {});
  }

  void _onUndo() {
    if (_gameComplete) return;
    if (_undoStack.isEmpty) return;

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

  void _onNotesToggle() {
    setState(() {
      _notesMode = !_notesMode;
    });
  }

  void _onHint() {
    if (_gameComplete) return;
    if (_hintsRemaining <= 0) return;

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

    final randomCell = emptyCells[DateTime.now().millisecond % emptyCells.length];
    final row = randomCell.$1;
    final col = randomCell.$2;
    final solutionValue = _board.getSolutionValue(row, col);

    _board.selectCell(row, col);
    _board.setValue(row, col, solutionValue);

    _board.cells[row][col] = _board.cells[row][col].copyWith(isHint: true);
    _hintsRemaining--;

    if (_board.isComplete && !_gameComplete) {
      _gameComplete = true;
      _timer.cancel();
      Future.delayed(const Duration(milliseconds: 500), () {
        _showWinDialog();
      });
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

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events,
                size: 48,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Puzzle Complete!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.graphite,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Time: $_formattedTime',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.graphite,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Difficulty: $_difficultyLabel',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.graphite.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.gridLine),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Home',
                      style: TextStyle(color: AppColors.graphite),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _startNewGame();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('New Game'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = _board.filledCount / 81;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _difficultyLabel,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.ivory : AppColors.graphite,
          ),
        ),
        centerTitle: true,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                _formattedTime,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isDark ? AppColors.ivory : AppColors.graphite,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.gridLine.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
                  minHeight: 3,
                ),
              ),
              const SizedBox(height: 12),
              // Board
              SudokuBoardWidget(
                board: _board,
                onCellTap: _onCellTap,
              ),
              const SizedBox(height: 16),
              // Hint button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _onHint,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _hintsRemaining > 0
                            ? AppColors.gold.withValues(alpha: 0.12)
                            : AppColors.gridLine.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _hintsRemaining > 0
                              ? AppColors.gold.withValues(alpha: 0.4)
                              : AppColors.gridLine.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 16,
                            color: _hintsRemaining > 0
                                ? AppColors.gold
                                : AppColors.gridLine,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Hint ($_hintsRemaining)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _hintsRemaining > 0
                                  ? AppColors.gold
                                  : AppColors.gridLine,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Number pad
              NumberPad(
                onNumberTap: _onNumberTap,
                onErase: _onErase,
                onUndo: _onUndo,
                onNotesToggle: _onNotesToggle,
                notesMode: _notesMode,
                numberCounts: _getNumberCounts(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
