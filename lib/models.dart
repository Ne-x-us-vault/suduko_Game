import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a single cell in the Sudoku board
class SudokuCell {
  final int row;
  final int col;
  int value;
  bool isOriginal;
  bool isSelected;
  bool isHint;
  bool isError;

  SudokuCell({
    required this.row,
    required this.col,
    this.value = 0,
    this.isOriginal = false,
    this.isSelected = false,
    this.isHint = false,
    this.isError = false,
  });

  get isFilled => value != 0;
  get isEmpty => value == 0;
  get isValidNumber => value >= 1 && value <= 9;

  SudokuCell copyWith({
    int? value,
    bool? isSelected,
    bool? isHint,
    bool? isError,
    bool? isOriginal,
  }) {
    return SudokuCell(
      row: row,
      col: col,
      value: value ?? this.value,
      isOriginal: isOriginal ?? this.isOriginal,
      isSelected: isSelected ?? this.isSelected,
      isHint: isHint ?? this.isHint,
      isError: isError ?? this.isError,
    );
  }
}

/// Represents the Sudoku board state
class SudokuBoard extends ChangeNotifier {
  final int size = 9;
  List<List<SudokuCell>> cells = List.generate(9, (_) => List.filled(9, SudokuCell(row: 0, col: 0)));

  SudokuBoard._internal();

  factory SudokuBoard.create() {
    final board = SudokuBoard._internal();
    board._initializeBoard();
    return board;
  }

  factory SudokuBoard.fromPuzzle(List<List<int>> puzzle) {
    final board = SudokuBoard.create();
    board._applyPuzzle(puzzle);
    return board;
  }

  void _initializeBoard() {
    cells = List.generate(9, (r) => List.generate(9, (c) => SudokuCell(row: r, col: c)));
    notifyListeners();
  }

  void _applyPuzzle(List<List<int>> puzzle) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (puzzle[r][c] != 0) {
          cells[r][c] = SudokuCell(row: r, col: c, value: puzzle[r][c], isOriginal: true);
        }
      }
    }
    notifyListeners();
  }

  int getValue(int row, int col) => cells[row][col].value;
  setValue(int row, int col, int value) {
    cells[row][col] = cells[row][col].copyWith(value: value);
    notifyListeners();
  }

  void selectCell(int row, int col) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        cells[r][c] = cells[r][c].copyWith(isSelected: r == row && c == col);
      }
    }
    notifyListeners();
  }

  void toggleHint(int row, int col) {
    cells[row][col] = cells[row][col].copyWith(isHint: !cells[row][col].isHint);
    notifyListeners();
  }

  void setError(int row, int col, bool isError) {
    cells[row][col] = cells[row][col].copyWith(isError: isError);
    notifyListeners();
  }

  bool get isComplete {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (cells[r][c].value == 0) return false;
      }
    }
    return _isValidFullBoard();
  }

  bool _isValidFullBoard() {
    for (int r = 0; r < 9; r++) {
      final Set<int> rowNums = {};
      for (int c = 0; c < 9; c++) {
        final v = cells[r][c].value;
        if (v != 0 && rowNums.contains(v)) return false;
        if (v != 0) rowNums.add(v);
      }
    }

    for (int c = 0; c < 9; c++) {
      final Set<int> colNums = {};
      for (int r = 0; r < 9; r++) {
        final v = cells[r][c].value;
        if (v != 0 && colNums.contains(v)) return false;
        if (v != 0) colNums.add(v);
      }
    }

    for (int br = 0; br < 3; br++) {
      for (int bc = 0; bc < 3; bc++) {
        final Set<int> boxNums = {};
        for (int r = br * 3; r < br * 3 + 3; r++) {
          for (int c = bc * 3; c < bc * 3 + 3; c++) {
            final v = cells[r][c].value;
            if (v != 0 && boxNums.contains(v)) return false;
            if (v != 0) boxNums.add(v);
          }
        }
      }
    }
    return true;
  }

  List<List<int>> getPuzzle() {
    final puzzle = List.generate(9, (i) => List.filled(9, 0));
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (cells[r][c].isOriginal || cells[r][c].value != 0) {
          puzzle[r][c] = cells[r][c].value;
        }
      }
    }
    return puzzle;
  }
}

/// Game statistics and streak tracking
class GameStats extends ChangeNotifier {
  static const String _key = 'sudoku_stats';

  int totalGamesPlayed = 0;
  int gamesWon = 0;
  int currentStreak = 0;
  int maxStreak = 0;
  DateTime? lastPlayed;
  int hintsUsed = 0;
  int errorsMade = 0;

  GameStats._internal();

  factory GameStats() {
    final instance = GameStats._internal();
    instance._load();
    return instance;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    totalGamesPlayed = prefs.getInt('${_key}_total') ?? 0;
    gamesWon = prefs.getInt('${_key}_won') ?? 0;
    currentStreak = prefs.getInt('${_key}_streak') ?? 0;
    maxStreak = prefs.getInt('${_key}_maxstreak') ?? 0;
    lastPlayed = prefs.getString('${_key}_lastplayed') != null
        ? DateTime.parse(prefs.getString('${_key}_lastplayed') ?? '')
        : null;
    hintsUsed = prefs.getInt('${_key}_hints') ?? 0;
    errorsMade = prefs.getInt('${_key}_errors') ?? 0;
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('${_key}_total', totalGamesPlayed);
    prefs.setInt('${_key}_won', gamesWon);
    prefs.setInt('${_key}_streak', currentStreak);
    prefs.setInt('${_key}_maxstreak', maxStreak);
    lastPlayed != null
        ? prefs.setString('${_key}_lastplayed', lastPlayed!.toIso8601String())
        : prefs.remove('${_key}_lastplayed');
    prefs.setInt('${_key}_hints', hintsUsed);
    prefs.setInt('${_key}_errors', errorsMade);
    notifyListeners();
  }

  void startNewGame() {
    currentStreak++;
    if (currentStreak > maxStreak) {
      maxStreak = currentStreak;
    }
    notifyListeners();
  }

  void endGame({required bool won}) {
    totalGamesPlayed++;
    if (won) {
      gamesWon++;
    } else {
      currentStreak = 0;
    }
    save();
    notifyListeners();
  }

  void useHint() {
    hintsUsed++;
    notifyListeners();
  }

  void makeError() {
    errorsMade++;
    notifyListeners();
  }

  String getStreakText() {
    if (currentStreak == 0) return 'Start a streak!';
    return 'Streak: $currentStreak';
  }
}

/// Enum for game difficulty levels
enum Difficulty { easy, medium, hard, expert }