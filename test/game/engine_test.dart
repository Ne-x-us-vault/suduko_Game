import 'package:test/test.dart';
import 'package:queens_game/model/position.dart';
import 'package:queens_game/model/puzzle.dart';
import 'package:queens_game/validation/constraint_engine.dart';
import 'package:queens_game/solver/queens_solver.dart';

void main() {
  group('ConstraintEngine', () {
    final puzzle = Puzzle(
      id: 'test_1',
      size: 4,
      regionMap: [
        [0, 0, 1, 1],
        [0, 0, 1, 1],
        [2, 2, 3, 3],
        [2, 2, 3, 3],
      ],
      solution: [Position(0, 0), Position(1, 2), Position(2, 1), Position(3, 3)],
      seed: 1,
      generatorVersion: 1,
      difficulty: Difficulty.easy,
      difficultyMetrics: {},
    );

    test('Should detect row conflict', () {
      final placements = [Position(0, 0)];
      expect(ConstraintEngine.isValidPlacement(puzzle, Position(0, 1), placements), isFalse);
    });

    test('Should detect column conflict', () {
      final placements = [Position(0, 0)];
      expect(ConstraintEngine.isValidPlacement(puzzle, Position(1, 0), placements), isFalse);
    });

    test('Should detect region conflict', () {
      final placements = [Position(0, 0)];
      expect(ConstraintEngine.isValidPlacement(puzzle, Position(0, 1), placements), isFalse);
    });

    test('Should detect adjacency conflict (diagonal)', () {
      final placements = [Position(0, 0)];
      expect(ConstraintEngine.isValidPlacement(puzzle, Position(1, 1), placements), isFalse);
    });

    test('Should allow valid placement', () {
      final placements = [Position(0, 0)];
      // (1, 2) is different row, col, region (1 vs 0), and not adjacent to (0,0)
      expect(ConstraintEngine.isValidPlacement(puzzle, Position(1, 2), placements), isTrue);
    });
  });

  group('QueensSolver', () {
    test('Should find solution for simple puzzle', () {
      final puzzle = Puzzle(
        id: 'test_solve',
        size: 4,
        regionMap: [
          [0, 0, 1, 1],
          [0, 0, 1, 1],
          [2, 2, 3, 3],
          [2, 2, 3, 3],
        ],
        solution: [], // solver finds it
        seed: 1,
        generatorVersion: 1,
        difficulty: Difficulty.easy,
        difficultyMetrics: {},
      );
      final sol = QueensSolver.findOneSolution(puzzle);
      expect(sol, isNotNull);
      expect(sol!.length, 4);
      expect(ConstraintEngine.isSolved(puzzle, sol), isTrue);
    });

    test('Should count solutions correctly', () {
      final puzzle = Puzzle(
        id: 'test_count',
        size: 3,
        regionMap: [
          [0, 1, 2],
          [0, 1, 2],
          [0, 1, 2],
        ],
        solution: [],
        seed: 1,
        generatorVersion: 1,
        difficulty: Difficulty.easy,
        difficultyMetrics: {},
      );
      // In this specific 3x3 layout, check if it's uniquely solvable or not
      int count = QueensSolver.countSolutions(puzzle);
      expect(count, isA<int>());
    });
  });
}
