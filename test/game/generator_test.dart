import 'package:flutter_test/flutter_test.dart';
import 'package:queens_game/core/errors/app_exceptions.dart';
import 'package:queens_game/core/utilities/date_utils.dart';
import 'package:queens_game/game/daily/daily_challenge_service.dart';
import 'package:queens_game/game/generator/puzzle_generator.dart';
import 'package:queens_game/game/model/difficulty.dart';
import 'package:queens_game/game/model/puzzle.dart';
import 'package:queens_game/game/solver/queens_solver.dart';
import 'package:queens_game/game/validation/constraint_engine.dart';
import 'package:queens_game/game/validation/region_validator.dart';

void main() {
  const generator = PuzzleGenerator();

  group('PuzzleGenerator determinism', () {
    test('same seed produces the identical puzzle', () {
      final a = generator.generate(size: 6, seed: 12345);
      final b = generator.generate(size: 6, seed: 12345);
      expect(a.id, b.id);
      expect(a.regionMap, b.regionMap);
      expect(a.solution, b.solution);
    });

    test('different seeds produce different puzzles', () {
      final a = generator.generate(size: 6, seed: 1);
      final b = generator.generate(size: 6, seed: 2);
      expect(a.regionMap == b.regionMap, isFalse);
    });
  });

  group('PuzzleGenerator validity', () {
    for (final size in [5, 6, 7, 8]) {
      test('size $size produces a verified puzzle', () {
        final puzzle = generator.generate(size: size, seed: 99);
        expect(puzzle.size, size);
        expect(RegionValidator.validate(puzzle), isNull);
        expect(ConstraintEngine.validatePuzzle(puzzle), isNull);
        // Exact uniqueness: exactly one solution.
        expect(QueensSolver.countSolutions(puzzle), 1);
        // The stored difficulty was produced by classification.
        expect(puzzle.difficultyScore.difficulty, isA<Difficulty>());
      });
    }

    test('all supported sizes generate', () {
      for (final size in [5, 6, 7, 8, 9, 10]) {
        final puzzle = generator.generate(size: size, seed: 7);
        expect(puzzle.size, size);
      }
    });

    test('unsupported size throws', () {
      expect(
        () => generator.generate(size: 4, seed: 1),
        throwsA(isA<PuzzleGenerationException>()),
      );
    });

    test('target difficulty honors best-effort fallback', () {
      for (final d in Difficulty.values) {
        final puzzle =
            generator.generate(size: 7, seed: randSeed(), targetDifficulty: d);
        // The generator may fall back to the closest difficulty, but the
        // puzzle must still be fully verified.
        expect(RegionValidator.validate(puzzle), isNull);
        expect(QueensSolver.countSolutions(puzzle), 1);
      }
    });
  });

  group('Puzzle JSON round-trip', () {
    test('toJson -> fromJson preserves the puzzle', () {
      final original = generator.generate(size: 7, seed: 42);
      final restored = Puzzle.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.regionMap, original.regionMap);
      expect(restored.solution, original.solution);
      expect(restored.seed, original.seed);
      expect(restored.difficultyScore.difficulty,
          original.difficultyScore.difficulty);
    });
  });

  group('Daily challenge determinism', () {
    test('same local date yields the same puzzle', () {
      final now = DateTime(2026, 9, 12, 14, 30);
      final a = DailyChallengeService.getDailyPuzzle(now: now);
      final b = DailyChallengeService.getDailyPuzzle(now: now);
      expect(a.regionMap, b.regionMap);
      expect(a.solution, b.solution);
      expect(a.id, b.id);
    });

    test('daily puzzles are deterministic across app restarts', () {
      final now = DateTime(2026, 1, 1, 0, 5);
      final a = DailyChallengeService.getDailyPuzzle(now: now);
      // "Restart" = recompute from just the date; still identical.
      final b = DailyChallengeService.getDailyPuzzle(now: now);
      expect(a.solution, b.solution);
    });

    test('seed depends on the date', () {
      final a = DailyChallengeService.getDailySeed(DateTime(2026, 9, 12));
      final b = DailyChallengeService.getDailySeed(DateTime(2026, 9, 13));
      expect(a, isNot(b));
    });

    test('date key normalization', () {
      expect(DateUtils.dateKey(DateTime(2026, 9, 12, 23, 59)), '2026-09-12');
      expect(DateUtils.previousDateKey(DateTime(2026, 9, 12)),
          '2026-09-11');
      expect(DateUtils.isNextDay('2026-09-11', '2026-09-12'), isTrue);
      expect(DateUtils.isNextDay('2026-09-12', '2026-09-11'), isFalse);
    });
  });
}

// Any int works; using a constant avoids depending on wall-clock time.
int randSeed() => 8128;