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

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final GameStats _stats = GameStats();
  late SudokuBoard _board;
  Timer? _timer;
  Timer? _errorFlashTimer;
  int _elapsedSeconds = 0;
  bool _notesMode = false;
  bool _gameComplete = false;
  bool _isNewBest = false;
  int _hintsRemaining = 3;
  int _errorCount = 0;
  final List<UndoEntry> _undoStack = [];
  final FocusNode _focusNode = FocusNode();

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final paused = state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive || state == AppLifecycleState.hidden;
    if (paused && !_gameComplete && _timer?.isActive == true) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed &&
        !_gameComplete &&
        _timer?.isActive != true) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _errorFlashTimer?.cancel();
    _shakeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startNewGame() {
    _errorFlashTimer?.cancel();
    final result = SudokuGenerator.generatePuzzle(widget.difficulty);
    _board = SudokuBoard.fromPuzzle(result.puzzle, result.solution);
    _elapsedSeconds = 0;
    _notesMode = false;
    _gameComplete = false;
    _isNewBest = false;
    _hintsRemaining = 3;
    _errorCount = 0;
    _undoStack.clear();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer timer) {
    if (!_gameComplete) {
      setState(() {
        _elapsedSeconds++;
      });
    }
  }

  String get _formattedTime {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatSeconds(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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

  void _onCellTap((int, int) position) {
    if (_gameComplete) return;
    _board.selectCell(position.$1, position.$2);
    _focusNode.requestFocus();
    setState(() {});
  }

  void _placeNumber(int number) {
    if (_gameComplete) return;
    final selected = _findSelectedCell();
    if (selected == null || selected.isOriginal) return;

    final row = selected.row;
    final col = selected.col;

    _undoStack.add(
      UndoEntry(
        row: row,
        col: col,
        previousValue: selected.value,
        previousNotes: Set<int>.from(selected.notes),
      ),
    );

    if (_notesMode) {
      _board.toggleNote(row, col, number);
    } else {
      _board.setValue(row, col, number);

      if (_board.checkError(row, col)) {
        _errorCount++;
        _stats.makeError();
        _showErrorFlash(row, col);
      } else {
        _removePeerNotes(row, col, number);
      }

      _checkWin();
    }
    setState(() {});
  }

  void _removePeerNotes(int row, int col, int number) {
    for (int r = 0; r < 9; r++) {
      if (r == row) continue;
      final cell = _board.cells[r][col];
      if (cell.notes.contains(number)) {
        _board.cells[r][col] = cell.copyWith(
          notes: Set<int>.from(cell.notes)..remove(number),
        );
      }
    }
    for (int c = 0; c < 9; c++) {
      if (c == col) continue;
      final cell = _board.cells[row][c];
      if (cell.notes.contains(number)) {
        _board.cells[row][c] = cell.copyWith(
          notes: Set<int>.from(cell.notes)..remove(number),
        );
      }
    }
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) {
        if (r == row && c == col) continue;
        final cell = _board.cells[r][c];
        if (cell.notes.contains(number)) {
          _board.cells[r][c] = cell.copyWith(
            notes: Set<int>.from(cell.notes)..remove(number),
          );
        }
      }
    }
  }

  void _showErrorFlash(int row, int col) {
    _shakeController.forward(from: 0);
    HapticFeedback.mediumImpact();

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

    _undoStack.add(
      UndoEntry(
        row: selected.row,
        col: selected.col,
        previousValue: selected.value,
        previousNotes: Set<int>.from(selected.notes),
      ),
    );
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
    _stats.useHint();
    _removePeerNotes(row, col, _board.getSolutionValue(row, col));

    _checkWin();
    setState(() {});
  }

  void _checkWin() {
    if (_board.isComplete && !_gameComplete) {
      _gameComplete = true;
      _timer?.cancel();
      final best = _stats.bestTimeFor(widget.difficulty);
      _isNewBest = best == null || _elapsedSeconds < best;
      _stats.endGame(won: true);
      _stats.recordBestTime(widget.difficulty, _elapsedSeconds);
      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted) _showWinDialog();
      });
    }
  }

  SudokuCell? _findSelectedCell() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_board.cells[r][c].isSelected) return _board.cells[r][c];
      }
    }
    return null;
  }

  (int, int)? _selectedPosition() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_board.cells[r][c].isSelected) return (r, c);
      }
    }
    return null;
  }

  void _moveSelection(int dr, int dc) {
    if (_gameComplete) return;
    final pos = _selectedPosition();
    final row = (pos == null ? 4 : pos.$1 + dr).clamp(0, 8);
    final col = (pos == null ? 4 : pos.$2 + dc).clamp(0, 8);
    _focusNode.requestFocus();
    _board.selectCell(row, col);
    setState(() {});
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

    const digitKeys = [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
    ];
    const numpadKeys = [
      LogicalKeyboardKey.numpad1,
      LogicalKeyboardKey.numpad2,
      LogicalKeyboardKey.numpad3,
      LogicalKeyboardKey.numpad4,
      LogicalKeyboardKey.numpad5,
      LogicalKeyboardKey.numpad6,
      LogicalKeyboardKey.numpad7,
      LogicalKeyboardKey.numpad8,
      LogicalKeyboardKey.numpad9,
    ];

    for (int i = 0; i < 9; i++) {
      if (key == digitKeys[i] || key == numpadKeys[i]) {
        _placeNumber(i + 1);
        return KeyEventResult.handled;
      }
    }

    if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace) {
      _eraseCell();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyN) {
      _toggleNotes();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyZ) {
      _undoMove();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyH) {
      _useHint();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveSelection(-1, 0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveSelection(1, 0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      _moveSelection(0, -1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _moveSelection(0, 1);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  // --- Exit handling ---

  void _attemptExit() {
    if (_gameComplete) {
      Navigator.of(context).pop();
      return;
    }
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: context.surface,
        title: Text(
          'Leave this puzzle?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Your progress will be lost and the timer won\'t count.',
          style: TextStyle(fontSize: 14, height: 1.4, color: context.inkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Keep playing',
              style: TextStyle(color: context.ink, fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Leave',
              style: TextStyle(
                color: context.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ).then((leave) {
      if (leave == true && mounted) Navigator.of(context).pop();
    });
  }

  // --- Dialogs ---

  void _showWinDialog() {
    final best = _stats.bestTimeFor(widget.difficulty);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: context.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTrophy(),
              const SizedBox(height: 18),
              Text(
                'Puzzle solved!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: context.ink,
                ),
              ),
              Text(
                _difficultyLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: context.accent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _formattedTime,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: context.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (_isNewBest) ...[
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.accentSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'New best time',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.accent,
                    ),
                  ),
                ),
              ] else if (best != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Best: ${_formatSeconds(best)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.inkMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildResultChip('Errors', '$_errorCount'),
                  const SizedBox(width: 12),
                  _buildResultChip('Hints', '${3 - _hintsRemaining}'),
                ],
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
                      child: const Text('Home'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(_startNewGame);
                      },
                      child: const Text('Play again'),
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

  Widget _buildTrophy() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: context.accent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: context.accent.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.emoji_events_rounded,
            size: 40,
            color: AppColors.onAccent,
          ),
        ),
      ),
    );
  }

  Widget _buildResultChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.paper,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: context.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.inkMuted,
            ),
          ),
        ],
      ),
    );
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    final progress = _board.filledCount / 81;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _attemptExit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _attemptExit,
            tooltip: 'Exit puzzle',
          ),
          title: Text(
            _difficultyLabel,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: context.ink,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.line, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 15, color: context.inkMuted),
                      const SizedBox(width: 5),
                      Text(
                        _formattedTime,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [
                            FontFeature.tabularFigures()
                          ],
                          color: context.ink,
                        ),
                      ),
                    ],
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
            behavior: HitTestBehavior.translucent,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    _buildProgressBar(progress),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
                    _buildHintPill(),
                    const SizedBox(height: 12),
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
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Column(
      children: [
        Row(
          children: [
            const Spacer(),
            Text(
              '${_board.filledCount}/81',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.inkMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: context.line,
            valueColor: AlwaysStoppedAnimation<Color>(context.accent),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildHintPill() {
    final available = _hintsRemaining > 0;

    return GestureDetector(
      onTap: available ? _useHint : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: available ? context.hintSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: available ? context.hintInk.withValues(alpha: 0.4) : context.line,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_rounded,
              size: 16,
              color: available ? context.hintInk : context.inkMuted,
            ),
            const SizedBox(width: 6),
            Text(
              available ? 'Hint — $_hintsRemaining left' : 'No hints left',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: available ? context.hintInk : context.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}