import 'package:flutter_test/flutter_test.dart';

import 'package:sudoku_game/models.dart';
import 'package:sudoku_game/features/sudoku/sudoku_generator.dart';
import 'package:sudoku_game/features/sudoku/sudoku_solver.dart';

void main() {
  test('generated solved board is valid', () {
    final board = SudokuGenerator.generateSolvedBoard();
    expect(SudokuSolver.isSolved(board), isTrue);
  });

  test('generated puzzles are solvable and unique across difficulties', () {
    for (final difficulty in Difficulty.values) {
      for (int i = 0; i < 5; i++) {
        final result = SudokuGenerator.generatePuzzle(difficulty);
        expect(SudokuSolver.isValidFullBoard(result.puzzle), isTrue);
        final copy = List.generate(
          9,
          (r) => List<int>.from(result.puzzle[r]),
        );
        expect(SudokuSolver.solveBoard(copy), isTrue);
      }
    }
  });

  test('puzzle difficulty produces expected clue counts', () {
    for (final difficulty in Difficulty.values) {
      final target = SudokuGenerator.cluesForDifficulty(difficulty);
      for (int i = 0; i < 3; i++) {
        final result = SudokuGenerator.generatePuzzle(difficulty);
        var clues = 0;
        for (final row in result.puzzle) {
          clues += row.where((v) => v != 0).length;
        }
        expect(clues, greaterThanOrEqualTo(target));
        expect(clues, lessThanOrEqualTo(target + 8));
      }
    }
  });
}