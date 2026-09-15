class SudokuSolver {
  static bool solveBoard(List<List<CellValue>> cells) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (cells[row][col].value == null) {
          for (int num = 1; num <= 9; num++) {
            cells[row][col] = CellValue(value: num);
            if (_isValidPlacement(cells, row, col) && solveBoard(cells)) {
              return true;
            }
            cells[row][col] = CellValue();
          }
          return false;
        }
      }
    }
    return true;
  }

  static bool _isValidPlacement(List<List<CellValue>> cells, int row, int col) {
    // Check row
    for (int c = 0; c < 9; c++) {
      if (c != col && cells[row][c].value == cells[row][col].value) return false;
    }

    // Check column
    for (int r = 0; r < 9; r++) {
      if (r != row && cells[r][col].value == cells[row][col].value) return false;
    }

    // Check 3x3 box
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        final cr = boxRow + r;
        final cc = boxCol + c;
        if ((cr != row || cc != col) && cells[cr][cc].value == cells[row][col].value) {
          return false;
        }
      }
    }
    return true;
  }

  static bool isSolved(List<List<CellValue>> cells) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (cells[r][c].value == null) return false;
      }
    }
    return true;
  }

  static bool isValidFullBoard(List<List<CellValue>> cells) {
    for (int r = 0; r < 9; r++) {
      if (!SudokuBoard._isRowValidFromCells(cells, r)) return false;
    }
    for (int c = 0; c < 9; c++) {
      if (!SudokuBoard._isColValidFromCells(cells, c)) return false;
    }
    for (int b = 0; b < 9; b++) {
      if (!SudokuBoard._isBoxValidFromCells(cells, b)) return false;
    }
    return true;
  }

  static List<int> getRow(List<List<CellValue>> cells, int row) {
    return List<int>.from(cells[row].map((c) => c.value ?? 0).where((v) => v != 0));
  }

  static List<int> getCol(List<List<CellValue>> cells, int col) {
    final result = <int>[];
    for (int r = 0; r < 9; r++) {
      final v = cells[r][col].value;
      if (v != null) result.add(v);
    }
    return result;
  }

  static List<int> getBox(List<List<CellValue>> cells, int boxIndex) {
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
}

class SudokuValidator {
  static bool validateBoard(List<List<CellValue>> cells) {
    for (int r = 0; r < 9; r++) {
      if (!_validateRow(cells, r)) return false;
    }
    for (int c = 0; c < 9; c++) {
      if (!_validateCol(cells, c)) return false;
    }
    for (int b = 0; b < 9; b++) {
      if (!_validateBox(cells, b)) return false;
    }
    return true;
  }

  static bool _validateRow(List<List<CellValue>> cells, int row) {
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

  static bool _validateCol(List<List<CellValue>> cells, int col) {
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

  static bool _validateBox(List<List<CellValue>> cells, int boxIndex) {
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
}