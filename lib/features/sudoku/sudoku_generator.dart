import 'dart:math';

import 'package:sudoku_game/models.dart';

class SudokuGenerator {
  static List<List<int>> generateSolvedBoard([Random? random]) {
    final rand = random ?? Random();
    final cells = List.generate(9, (_) => List.filled(9, 0));
    if (!_fillBoard(cells, rand)) {
      return _knownSolvedBoard();
    }
    return cells;
  }

  static bool _fillBoard(List<List<int>> cells, Random rand) {
    final emptyPositions = List.generate(81, (i) => i)..shuffle(rand);
    for (final pos in emptyPositions) {
      final row = pos ~/ 9;
      final col = pos % 9;
      if (cells[row][col] != 0) continue;

      final nums = _getShuffledNumbers(rand);
      for (final num in nums) {
        cells[row][col] = num;
        if (_isValidPlacement(cells, row, col) && _solveRemaining(cells)) {
          return true;
        }
        cells[row][col] = 0;
      }
      return false;
    }
    return true;
  }

  static List<int> _getShuffledNumbers(Random rand) {
    final nums = List.generate(9, (i) => i + 1);
    nums.shuffle(rand);
    return nums;
  }

  static bool _solveRemaining(List<List<int>> cells) {
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

  static List<List<int>> _deepCopy(List<List<int>> cells) {
    return List.generate(9, (r) => List<int>.from(cells[r]));
  }

  static int cluesForDifficulty(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return 38;
      case Difficulty.medium:
        return 30;
      case Difficulty.hard:
        return 25;
      case Difficulty.expert:
        return 22;
    }
  }

  static ({List<List<int>> puzzle, List<List<int>> solution}) generatePuzzle(
    Difficulty difficulty, [
    Random? random,
  ]) {
    final solution = generateSolvedBoard(random);
    final clueCount = cluesForDifficulty(difficulty);
    final toRemove = 81 - clueCount;
    final puzzle = removeValues(solution, toRemove, random);
    return (puzzle: puzzle, solution: solution);
  }

  static List<List<int>> removeValues(
    List<List<int>> solvedBoard,
    int toRemove, [
    Random? rand,
  ]) {
    final cells = _deepCopy(solvedBoard);
    final availablePositions = List.generate(81, (i) => i)..shuffle(rand);
    int removed = 0;

    for (final pos in availablePositions) {
      if (removed >= toRemove) break;
      final row = pos ~/ 9;
      final col = pos % 9;

      if (cells[row][col] == 0) continue;

      final savedValue = cells[row][col];
      cells[row][col] = 0;

      if (_hasUniqueSolution(cells)) {
        removed++;
      } else {
        cells[row][col] = savedValue;
      }
    }

    return cells;
  }

  static bool _hasUniqueSolution(List<List<int>> cells) {
    final tempCells = _deepCopy(cells);
    int solutionCount = 0;
    bool countSolutions(List<List<int>> board, int idx) {
      if (solutionCount > 1) return false;
      for (int i = idx; i < 81; i++) {
        final row = i ~/ 9;
        final col = i % 9;
        if (board[row][col] == 0) {
          for (int num = 1; num <= 9; num++) {
            board[row][col] = num;
            if (_isValidPlacement(board, row, col) && countSolutions(board, i + 1)) {
              return true;
            }
            board[row][col] = 0;
          }
          return false;
        }
      }
      solutionCount++;
      return solutionCount > 1;
    }

    countSolutions(tempCells, 0);
    return solutionCount == 1;
  }

  static List<List<int>> _knownSolvedBoard() {
    return [
      [5, 3, 4, 6, 7, 8, 9, 1, 2],
      [6, 7, 2, 1, 9, 5, 3, 4, 8],
      [1, 9, 8, 3, 4, 2, 5, 6, 7],
      [8, 5, 9, 7, 6, 1, 4, 2, 3],
      [4, 2, 6, 8, 5, 3, 7, 9, 1],
      [7, 1, 3, 9, 2, 4, 8, 5, 6],
      [9, 6, 1, 5, 3, 7, 2, 8, 4],
      [2, 8, 7, 4, 1, 9, 6, 3, 5],
      [3, 4, 5, 2, 8, 6, 1, 7, 9],
    ];
  }
}
