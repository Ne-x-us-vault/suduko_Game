import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Difficulty { easy, medium, hard, expert }

class SudokuCell {
  final int row;
  final int col;
  int value;
  bool isOriginal;
  bool isSelected;
  bool isHint;
  bool isError;
  Set<int> notes;

  SudokuCell({
    required this.row,
    required this.col,
    this.value = 0,
    this.isOriginal = false,
    this.isSelected = false,
    this.isHint = false,
    this.isError = false,
    Set<int>? notes,
  }) : notes = notes ?? {};

  bool get isFilled => value != 0;
  bool get isEmpty => value == 0;
  bool get isValidNumber => value >= 1 && value <= 9;
  bool get hasNotes => notes.isNotEmpty;

  SudokuCell copyWith({
    int? value,
    bool? isSelected,
    bool? isHint,
    bool? isError,
    bool? isOriginal,
    Set<int>? notes,
  }) {
    return SudokuCell(
      row: row,
      col: col,
      value: value ?? this.value,
      isOriginal: isOriginal ?? this.isOriginal,
      isSelected: isSelected ?? this.isSelected,
      isHint: isHint ?? this.isHint,
      isError: isError ?? this.isError,
      notes: notes ?? Set<int>.from(this.notes),
    );
  }
}

class SudokuBoard extends ChangeNotifier {
  static const int size = 9;
  List<List<SudokuCell>> cells = List.generate(
    9,
    (r) => List.generate(9, (c) => SudokuCell(row: r, col: c)),
  );
  List<List<int>> _solution = List.generate(9, (_) => List.filled(9, 0));

  SudokuBoard._internal();

  factory SudokuBoard.create() {
    final board = SudokuBoard._internal();
    board._initializeBoard();
    return board;
  }

  factory SudokuBoard.fromPuzzle(List<List<int>> puzzle, List<List<int>> solution) {
    final board = SudokuBoard.create();
    board._solution = solution;
    board._applyPuzzle(puzzle);
    return board;
  }

  void _initializeBoard() {
    cells = List.generate(
      9,
      (r) => List.generate(9, (c) => SudokuCell(row: r, col: c)),
    );
    notifyListeners();
  }

  void _applyPuzzle(List<List<int>> puzzle) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (puzzle[r][c] != 0) {
          cells[r][c] = SudokuCell(
            row: r,
            col: c,
            value: puzzle[r][c],
            isOriginal: true,
          );
        }
      }
    }
    notifyListeners();
  }

  int getValue(int row, int col) => cells[row][col].value;

  int getSolutionValue(int row, int col) => _solution[row][col];

  void setValue(int row, int col, int value) {
    cells[row][col] = cells[row][col].copyWith(
      value: value,
      isError: false,
      notes: {},
    );
    notifyListeners();
  }

  void toggleNote(int row, int col, int number) {
    final cell = cells[row][col];
    if (cell.isFilled) return;
    final newNotes = Set<int>.from(cell.notes);
    if (newNotes.contains(number)) {
      newNotes.remove(number);
    } else {
      newNotes.add(number);
    }
    cells[row][col] = cell.copyWith(notes: newNotes);
    notifyListeners();
  }

  void clearCell(int row, int col) {
    cells[row][col] = cells[row][col].copyWith(
      value: 0,
      isError: false,
      notes: {},
    );
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

  void clearSelection() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        cells[r][c] = cells[r][c].copyWith(isSelected: false);
      }
    }
    notifyListeners();
  }

  bool checkError(int row, int col) {
    final value = cells[row][col].value;
    if (value == 0) return false;
    return value != _solution[row][col];
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

  int get filledCount {
    int count = 0;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (cells[r][c].isFilled) count++;
      }
    }
    return count;
  }

  List<List<int>> getPuzzle() {
    final puzzle = List.generate(9, (i) => List.filled(9, 0));
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (cells[r][c].isOriginal) {
          puzzle[r][c] = cells[r][c].value;
        }
      }
    }
    return puzzle;
  }
}

class GameStats extends ChangeNotifier {
  static const String _key = 'sudoku_stats';

  int totalGamesPlayed = 0;
  int gamesWon = 0;
  int currentStreak = 0;
  int maxStreak = 0;
  DateTime? lastPlayed;
  int hintsUsed = 0;
  int errorsMade = 0;
  Map<Difficulty, int> bestTimes = {};

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
    for (final difficulty in Difficulty.values) {
      final seconds = prefs.getInt('${_key}_best_${difficulty.name}');
      if (seconds != null && seconds > 0) {
        bestTimes[difficulty] = seconds;
      }
    }
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('${_key}_total', totalGamesPlayed);
    prefs.setInt('${_key}_won', gamesWon);
    prefs.setInt('${_key}_streak', currentStreak);
    prefs.setInt('${_key}_maxstreak', maxStreak);
    if (lastPlayed != null) {
      prefs.setString('${_key}_lastplayed', lastPlayed!.toIso8601String());
    } else {
      prefs.remove('${_key}_lastplayed');
    }
    prefs.setInt('${_key}_hints', hintsUsed);
    prefs.setInt('${_key}_errors', errorsMade);
    for (final entry in bestTimes.entries) {
      prefs.setInt('${_key}_best_${entry.key.name}', entry.value);
    }
    notifyListeners();
  }

  int? bestTimeFor(Difficulty difficulty) => bestTimes[difficulty];

  void recordBestTime(Difficulty difficulty, int seconds) {
    final current = bestTimes[difficulty];
    if (current == null || seconds < current) {
      bestTimes[difficulty] = seconds;
      save();
      notifyListeners();
    }
  }

  String get winRate {
    if (totalGamesPlayed == 0) return '—';
    return '${(gamesWon * 100 / totalGamesPlayed).round()}%';
  }

  void startNewGame() {
    totalGamesPlayed++;
    currentStreak++;
    if (currentStreak > maxStreak) maxStreak = currentStreak;
    lastPlayed = DateTime.now();
    save();
  }

  void endGame({required bool won}) {
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
    save();
    notifyListeners();
  }

  void makeError() {
    errorsMade++;
    save();
    notifyListeners();
  }

  String getStreakText() {
    if (currentStreak == 0) return 'Start a streak!';
    return 'Streak: $currentStreak';
  }
}

class UndoEntry {
  final int row;
  final int col;
  final int previousValue;
  final Set<int> previousNotes;

  UndoEntry({
    required this.row,
    required this.col,
    required this.previousValue,
    required this.previousNotes,
  });
}
