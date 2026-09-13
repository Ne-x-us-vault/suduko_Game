import 'package:flutter_test/flutter_test.dart';
import 'package:queens_game/game/difficulty/deduction_engine.dart';
import 'package:queens_game/game/generator/puzzle_generator.dart';
import 'package:queens_game/game/hints/hint_service.dart';
import 'package:queens_game/game/model/difficulty.dart';
import 'package:queens_game/game/model/position.dart';
import 'package:queens_game/game/solver/queens_solver.dart';
import 'package:queens_game/game/validation/constraint_engine.dart';
import 'package:queens_game/game/validation/region_validator.dart';

void main() {
  const generator = PuzzleGenerator();

  group('DeductionEngine', () {
    test('solves generated puzzles by pure logic without guessing', () {
      for (final size in [5, 6, 7]) {
        final puzzle = generator.generate(size: size, seed: size * 100);
        final result = DeductionEngine.analyzeFromScratch(puzzle);
        expect(result.solvedByDeduction, isTrue,
            reason: 'size $size should be purely deductive');
        expect(ConstraintEngine.isSolved(puzzle, result.placements), isTrue);
      }
    });

    test('produces elimination deductions in addition to placements', () {
      final puzzle = generator.generate(size: 6, seed: 42);
      final result = DeductionEngine.analyzeFromScratch(puzzle);
      expect(result.eliminationCount, greaterThan(0));
      expect(result.totalDeductions, greaterThanOrEqualTo(puzzle.size));
    });

    test('a single analyze pass on an empty board yields a hint', () {
      final puzzle = generator.generate(size: 6, seed: 42);
      final step = DeductionEngine.analyze(puzzle, const [], const {});
      expect(step, isNotEmpty);
      expect(step.any((d) => d.suggestedQueen != null), isTrue);
    });
  });

  group('HintService', () {
    test('returns an actionable hint on a fresh board', () {
      for (final size in [5, 6, 7, 8]) {
        final puzzle = generator.generate(size: size, seed: 99);
        final hint = HintService.getHint(puzzle, const [], const {});
        expect(hint, isNotNull,
            reason: 'size $size must yield a hint at the start');
        expect(hint!.suggestedMove, isNotNull);
        expect(hint.affectedCells, isNotEmpty);
      }
    });

    test('returns null once the puzzle is solved', () {
      final puzzle = generator.generate(size: 6, seed: 42);
      expect(
        HintService.getHint(puzzle, puzzle.solution, const {}),
        isNull,
      );
    });

    test('hints along the solve path always suggest a legal placement', () {
      for (final size in [6, 7, 8]) {
        final puzzle = generator.generate(size: size, seed: 99);
        final placed = <Position>[];
        for (var step = 0; step < puzzle.size; step++) {
          final hint = HintService.getHint(puzzle, placed, const {});
          expect(hint, isNotNull,
              reason: 'no hint available at step $step of size $size');
          final move = hint!.suggestedMove;
          expect(move, isNotNull,
              reason: 'hint must suggest a move at step $step of size $size');
          expect(
            ConstraintEngine.isValidQueenPlacement(puzzle, move!, placed),
            isTrue,
            reason: 'hint at step $step of size $size is an illegal placement',
          );
          placed.add(move);
        }
        expect(ConstraintEngine.isSolved(puzzle, placed), isTrue);
      }
    });
  });

  group('Difficulty spread', () {
    test('all four difficulty labels are reachable', () {
      final seen = <Difficulty>{};
      // Anchor each size to its expected band via a couple of seeds.
      final samples = <(int, int)>[
        (5, 1), (5, 8128), // Easy
        (6, 1), (6, 123456), // Easy/Medium
        (7, 1), (7, 99999), // Medium
        (8, 1), (8, 7000), // Hard
        (9, 1), (9, 25000), // Expert-ish
      ];
      for (final (size, seed) in samples) {
        final puzzle = generator.generate(size: size, seed: seed);
        seen.add(puzzle.difficulty);
        expect(RegionValidator.validate(puzzle), isNull);
        expect(QueensSolver.countSolutions(puzzle), 1);
      }
      expect(seen, containsAll(Difficulty.values));
    });

    test('larger boards classify as harder than small boards', () {
      // Deterministic seeds in each band: difficulty must not regress from
      // small → large boards.
      final small =
          generator.generate(size: 5, seed: 1).difficultyScore.humanScore;
      final medium =
          generator.generate(size: 7, seed: 1).difficultyScore.humanScore;
      final large =
          generator.generate(size: 9, seed: 1).difficultyScore.humanScore;
      expect(medium, greaterThan(small));
      expect(large, greaterThan(medium));
    });
  });
}