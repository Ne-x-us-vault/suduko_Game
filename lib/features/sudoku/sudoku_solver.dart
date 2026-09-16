class SudokuSolver {
  static bool solveBoard(List<List<int>> cells) {
    return _solveFrom(cells, 0);
  }

  static bool _solveFrom(List<List<int>> cells, int startIdx) {
    for (int idx = startIdx; idx < 81; idx++) {
      final row = idx ~/ 9;
      final col = idx % 9;
      if (cells[row][col] == 0) {
        for (int num = 1; num <= 9; num++) {
          cells[row][col] = num;
          if (_isValidPlacement(cells, row, col) && _solveFrom(cells, idx + 1)) {
            return true;
          }
          cells[row][col] = 0;
        }
        return false;
      }
    }
    return true;
  }

  static bool _isValidPlacement(List<List<int>> cells, int row, int col) {
    final num = cells[row][col];
    if (num == 0) return true;

    for (int c = 0; c < 9; c++) {
      if (c != col && cells[row][c] == num) return false;
    }
    for (int r = 0; r < 9; r++) {
      if (r != row && cells[r][col] == num) return false;
    }

    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        final cr = boxRow + r;
        final cc = boxCol + c;
        if ((cr != row || cc != col) && cells[cr][cc] == num) {
          return false;
        }
      }
    }
    return true;
  }

  static bool isSolved(List<List<int>> cells) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (cells[r][c] == 0) return false;
      }
    }
    return isValidFullBoard(cells);
  }

  static bool isValidFullBoard(List<List<int>> cells) {
    for (int r = 0; r < 9; r++) {
      final seen = <int>{};
      for (int c = 0; c < 9; c++) {
        final v = cells[r][c];
        if (v != 0) {
          if (v < 1 || v > 9 || seen.contains(v)) return false;
          seen.add(v);
        }
      }
    }
    for (int c = 0; c < 9; c++) {
      final seen = <int>{};
      for (int r = 0; r < 9; r++) {
        final v = cells[r][c];
        if (v != 0) {
          if (v < 1 || v > 9 || seen.contains(v)) return false;
          seen.add(v);
        }
      }
    }
    for (int b = 0; b < 9; b++) {
      final seen = <int>{};
      final rowStart = (b ~/ 3) * 3;
      final colStart = (b % 3) * 3;
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
          final v = cells[rowStart + r][colStart + c];
          if (v != 0) {
            if (v < 1 || v > 9 || seen.contains(v)) return false;
            seen.add(v);
          }
        }
      }
    }
    return true;
  }
}
