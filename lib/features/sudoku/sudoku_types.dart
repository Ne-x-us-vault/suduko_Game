class CellValue {
  final int? value;
  final Set<int> notes;

  CellValue({this.value, this.notes = const {}});

  CellValue copyWith({int? value, Set<int>? notes}) {
    return CellValue(
      value: value ?? this.value,
      notes: notes ?? this.notes,
    );
  }
}

extension CellValueX on CellValue {
  bool get isOriginal => value != null && notes.isEmpty;
  bool get isFilled => value != null;
  bool get isEmpty => value == null;
  bool get hasNotes => notes.isNotEmpty;
  int? getOrDefault(int defaultValue) => value ?? defaultValue;
}

class SudokuBoard {
  final List<List<CellValue>> cells;
  final int cluesCount;
  final bool isSolved;
  final bool isValid;

  SudokuBoard({
    required this.cells,
    required this.cluesCount,
    required this.isSolved,
    required this.isValid,
  });

  CellValue operator at(int row, int col) {
    return cells[row][col];
  }

  set at(int row, int col, CellValue value) {
    cells[row][col] = value;
  }

  List<int> getRow(int row) => List<int>.from(cells[row].map((c) => c.value ?? 0).where((v) => v != 0));
  List<int> getCol(int col) {
    final result = <int>[];
    for (int r = 0; r < 9; r++) {
      final v = cells[r][col].value;
      if (v != null) result.add(v);
    }
    return result;
  }

  List<int> getBox(int boxIndex) {
    final int rowStart = (boxIndex ~/ 3) * 3;
    final int colStart = (boxIndex % 3) * 3;
    final result = <int>[];
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        final v = cells[rowStart + r][colStart + c].value;
        if (v != null) result.add(v);
      }
    }
    return result;
  }

  bool isRowValid(int row) {
    final seen = <int>{};
    for (int c = 0; c < 9; c++) {
      final v = cells[row][c].value;
      if (v != null) {
        if (v < 1 || v > 9 || seen.contains(v)) return false;
        seen.add(v);
      }
    }
    return true;
  }

  bool isColValid(int col) {
    final seen = <int>{};
    for (int r = 0; r < 9; r++) {
      final v = cells[r][col].value;
      if (v != null) {
        if (v < 1 || v > 9 || seen.contains(v)) return false;
        seen.add(v);
      }
    }
    return true;
  }

  bool isBoxValid(int boxIndex) {
    final seen = <int>{};
    final int rowStart = (boxIndex ~/ 3) * 3;
    final int colStart = (boxIndex % 3) * 3;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        final v = cells[rowStart + r][colStart + c].value;
        if (v != null) {
          if (v < 1 || v > 9 || seen.contains(v)) return false;
          seen.add(v);
        }
      }
    }
    return true;
  }

  bool get isBoardValid {
    for (int r = 0; r < 9; r++) {
      if (!isRowValid(r)) return false;
    }
    for (int c = 0; c < 9; c++) {
      if (!isColValid(c)) return false;
    }
    for (int b = 0; b < 9; b++) {
      if (!isBoxValid(b)) return false;
    }
    return true;
  }

  int getCluesCount {
    int count = 0;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (cells[r][c].value != null) count++;
      }
    }
    return count;
  }

  SudokuBoard copyWith({
    List<List<CellValue>>? cells,
    int? cluesCount,
    bool? isSolved,
    bool? isValid,
  }) {
    return SudokuBoard(
      cells: cells ?? this.cells,
      cluesCount: cluesCount ?? this.cluesCount,
      isSolved: isSolved ?? this.isSolved,
      isValid: isValid ?? this.isValid,
    );
  }
}

class DifficultyInfo {
  final String label;
  final int estimatedTime; // seconds
  final int clues;
  final String bestTime;

  DifficultyInfo({
    required this.label,
    required this.estimatedTime,
    required this.clues,
    required this.bestTime,
  });
}