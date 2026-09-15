class SudokuGenerator {
  static List<List<CellValue>> generateSolvedBoard([Random? random]) {
    final cells = List.generate(9, (_) => List.generate(9, (_) => CellValue()));
    final rand = random ?? Random();
    if (!_fillBoard(cells, rand)) {
      return _createKnownSolvedBoard();
    }
    return cells;
  }

  static bool _fillBoard(List<List<CellValue>> cells, Random rand) {
    final emptyPositions = List.generate(81, (i) => i)..shuffle(rand);
    for (final pos in emptyPositions) {
      final row = pos ~/ 9;
      final col = pos % 9;
      if (cells[row][col].value != null) continue;

      final nums = _getShuffledNumbers(rand);
      for (final num in nums) {
        cells[row][col] = CellValue(value: num);
        if (_isValidPlacement(cells, row, col) && _solveRemaining(cells)) {
          goto done;
        }
        cells[row][col] = CellValue();
      }
    }
    return false;

    done: return true;
  }

  static List<int> _getShuffledNumbers(Random rand) {
    final nums = List.generate(9, (i) => i + 1);
    nums.shuffle(rand);
    return nums;
  }

  static bool _solveRemaining(List<List<CellValue>> cells) {
    return _solveFrom(cells, 0);
  }

  static bool _solveFrom(List<List<CellValue>> cells, int startIdx) {
    for (int idx = startIdx; idx < 81; idx++) {
      final row = idx ~/ 9;
      final col = idx % 9;
      if (cells[row][col].value == null) {
        for (int num = 1; num <= 9; num++) {
          cells[row][col] = CellValue(value: num);
          if (_isValidPlacement(cells, row, col) && _solveFrom(cells, idx + 1)) {
            return true;
          }
          cells[row][col] = CellValue();
        }
        return false;
      }
    }
    return true;
  }

  static bool _isValidPlacement(List<List<CellValue>> cells, int row, int col) {
    final num = cells[row][col].value!;

    for (int c = 0; c < 9; c++) {
      if (c != col && cells[row][c].value == num) return false;
    }

    for (int r = 0; r < 9; r++) {
      if (r != row && cells[r][col].value == num) return false;
    }

    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        final cr = boxRow + r;
        final cc = boxCol + c;
        if ((cr != row || cc != col) && cells[cr][cc].value == num) {
          return false;
        }
      }
    }
    return true;
  }

  static List<List<CellValue>> _deepCopy(List<List<CellValue>> cells) {
    return List.generate(9, (r) => List.generate(9, (c) => cells[r][c]));
  }

  static List<List<CellValue>> removeValues(
      List<List<CellValue>> solvedBoard, int toRemove, [Random? rand]) {
    final cells = _deepCopy(solvedBoard);
    final availablePositions = List.generate(81, (i) => i)..shuffle(rand);
    int removed = 0;

    for (final pos in availablePositions) {
      if (removed >= toRemove) break;
      final row = pos ~/ 9;
      final col = pos % 9;

      if (cells[row][col].value == null) continue;

      final savedValue = cells[row][col].value;
      cells[row][col] = CellValue();

      if (_hasSolution(cells)) {
        removed++;
      } else {
        cells[row][col] = CellValue(value: savedValue!);
      }
    }

    return cells;
  }

  static bool _hasSolution(List<List<CellValue>> cells) {
    final tempCells = _deepCopy(cells);
    return _solveFrom(tempCells, 0);
  }
}

List<List<CellValue>> _createKnownSolvedBoard() {
  final cells = List.generate(9, (_) => List.generate(9, (_) => CellValue()));
  // Create a valid Sudoku board using a pattern-based approach
  for (int r = 0; r < 9; r++) {
    for (int c = 0; c < 9; c++) {
      cells[r][c] = CellValue(value: (r * 3 + r ~/ 3 + c) % 9 + 1);
    }
  }
  // Verify and fix if needed
  return cells;
}