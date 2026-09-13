import 'package:flutter_test/flutter_test.dart';
import 'package:queens_game/game/model/difficulty.dart';
import 'package:queens_game/game/model/position.dart';
import 'package:queens_game/game/model/puzzle.dart';
import 'package:queens_game/game/solver/queens_solver.dart';
import 'package:queens_game/game/validation/constraint_engine.dart';
import 'package:queens_game/game/validation/region_validator.dart';

/// A hand-crafted 4×4 puzzle with one queen per row/column/region and no two
/// queens adjacent: queens at (0,1),(1,3),(2,0),(3,2).
/// Regions are designed to ensure a unique solution.
Puzzle buildTestPuzzle4() {
  return Puzzle(
    id: 't4',
    size: 4,
    regionMap: const [
      [0, 0, 0, 1],
      [0, 2, 1, 1],
      [2, 2, 3, 3],
      [2, 3, 3, 3],
    ],
    solution: const [
      Position(0, 1),
      Position(1, 3),
      Position(2, 0),
      Position(3, 2),
    ],
    seed: 0,
    generatorVersion: 1,
    difficultyScore: _emptyScore(),
  );
}

DifficultyScore _emptyScore() => const DifficultyScore(
      humanScore: 0,
      computationalScore: 0,
      finalScore: 0,
      difficulty: Difficulty.easy,
      humanMetrics: DifficultyMetrics.empty(),
      computationalMetrics: SolverMetrics.empty(),
      solvedByDeduction: false,
    );

/// A 4×4 layout with disconnected regions.
Puzzle buildBadLayout4() {
  return Puzzle(
    id: 'bad4',
    size: 4,
    regionMap: const [
      [0, 0, 1, 1],
      [2, 2, 3, 3],
      [0, 3, 1, 2],
      [3, 3, 0, 0],
    ],
    solution: const [
      Position(0, 1),
      Position(1, 3),
      Position(2, 0),
      Position(3, 2),
    ],
    seed: 0,
    generatorVersion: 1,
    difficultyScore: _emptyScore(),
  );
}

void main() {
  group('RegionValidator', () {
    test('accepts a valid layout', () {
      expect(RegionValidator.validate(buildTestPuzzle4()), isNull);
    });

    test('isValid returns true only for valid layouts', () {
      expect(RegionValidator.isValid(buildTestPuzzle4()), isTrue);
      expect(RegionValidator.isValid(buildBadLayout4()), isFalse);
    });

    test('rejects a disconnected region layout', () {
      expect(RegionValidator.validate(buildBadLayout4()), isNotNull);
    });
  });

  group('ConstraintEngine', () {
    final puzzle = buildTestPuzzle4();
    const solution = [
      Position(0, 1),
      Position(1, 3),
      Position(2, 0),
      Position(3, 2),
    ];

    test('solution satisfies every rule', () {
      expect(ConstraintEngine.isSolved(puzzle, [...solution]), isTrue);
      expect(ConstraintEngine.validateSolution(puzzle), isNull);
      expect(ConstraintEngine.validatePuzzle(puzzle), isNull);
      expect(ConstraintEngine.getConflicts(puzzle, [...solution]), isEmpty);
    });

    test('rows/columns/regions each hold exactly one queen', () {
      expect(ConstraintEngine.isRowSatisfied(puzzle, [...solution]), isTrue);
      expect(
          ConstraintEngine.isColumnSatisfied(puzzle, [...solution]), isTrue);
      expect(
          ConstraintEngine.isRegionSatisfied(puzzle, [...solution]), isTrue);
    });

    test('detects a row conflict', () {
      final invalid = [...solution, const Position(0, 0)];
      expect(ConstraintEngine.isSolved(puzzle, invalid), isFalse);
      expect(ConstraintEngine.getConflicts(puzzle, invalid),
          contains(const Position(0, 0)));
    });

    test('detects an adjacency conflict', () {
      final invalid = [...solution, const Position(1, 2)];
      expect(ConstraintEngine.isSolved(puzzle, invalid), isFalse);
    });

    test('isValidQueenPlacement checks all four rule types', () {
      // Row conflict: (1,1) vs (1,3) - same row 1
      expect(
        ConstraintEngine.isValidQueenPlacement(
            puzzle, const Position(1, 1), const [Position(1, 3)]),
        isFalse,
      );
      // Column conflict: (2,1) vs (0,1) - same column 1
      expect(
        ConstraintEngine.isValidQueenPlacement(
            puzzle, const Position(2, 1), const [Position(0, 1)]),
        isFalse,
      );
      // Region conflict: (0,0) vs (0,1) - both in region 0 (row 0)
      expect(
        ConstraintEngine.isValidQueenPlacement(
            puzzle, const Position(0, 0), const [Position(0, 1)]),
        isFalse,
      );
      // Adjacency conflict: (0,0) diagonally adjacent to (1,1)
      expect(
        ConstraintEngine.isValidQueenPlacement(
            puzzle, const Position(0, 0), const [Position(1, 1)]),
        isFalse,
      );
      // Valid: (0,0) not conflicting with (1,3)
      expect(
        ConstraintEngine.isValidQueenPlacement(
            puzzle, const Position(0, 0), const [Position(1, 3)]),
        isTrue,
      );
    });

    test('hasAdjacentQueen detects the eight neighbors', () {
      // (3,3) is adjacent to (3,2) in solution
      expect(
        ConstraintEngine.hasAdjacentQueen(const Position(3, 3), solution),
        isTrue,
      );
      // (2,3) is adjacent to (1,3) [vertical] and (3,2) [diagonal] in solution
      expect(
        ConstraintEngine.hasAdjacentQueen(const Position(2, 3), solution),
        isTrue,
      );
      // Queen positions are not adjacent to other queens (by puzzle rules)
      expect(
        ConstraintEngine.hasAdjacentQueen(const Position(0, 1), solution),
        isFalse,
      );
    });

    test('validatePuzzle rejects a bad region id', () {
      final bad = Puzzle(
        id: 'badrid',
        size: 4,
        regionMap: const [
          [0, 0, 0, 9],
          [1, 1, 1, 1],
          [2, 2, 2, 2],
          [3, 3, 3, 3],
        ],
        solution: solution,
        seed: 0,
        generatorVersion: 1,
        difficultyScore: _emptyScore(),
      );
      expect(ConstraintEngine.validatePuzzle(bad), isNotNull);
    });
  });

  group('QueensSolver', () {
    test('solves the crafted puzzle uniquely', () {
      final count = QueensSolver.countSolutions(buildTestPuzzle4());
      expect(count, 1);
      final result = QueensSolver.findOneSolution(buildTestPuzzle4());
      expect(result.solution, isNotNull);
      expect(result.solution, hasLength(4));
    });

    test('returns the same solution deterministically', () {
      final a = QueensSolver.findOneSolution(buildTestPuzzle4());
      final b = QueensSolver.findOneSolution(buildTestPuzzle4());
      expect(a.solution, b.solution);
    });

    test('uniqueness check works', () {
      expect(QueensSolver.isUniqueSolution(buildTestPuzzle4()), isTrue);
    });
  });
}