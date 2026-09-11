import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/utilities/seeded_random.dart';
import '../difficulty/difficulty_engine.dart';
import '../model/difficulty.dart';
import '../model/position.dart';
import '../model/puzzle.dart';
import '../solver/queens_solver.dart';
import '../validation/constraint_engine.dart';
import '../validation/region_validator.dart';
import 'region_generator.dart';

/// Complete procedural puzzle generator.
///
/// Fully deterministic: the same `(size, seed, generatorVersion, config)`
/// always produces the identical puzzle. Every returned puzzle has been
/// validated: region layout valid, exactly one solution (countSolutions == 1),
/// solution satisfies all rules.
class PuzzleGenerator {
  const PuzzleGenerator();

  /// Generates a unique-solution puzzle. If [targetDifficulty] is provided,
  /// generation is retried until the classified difficulty matches it.
  ///
  /// Throws [PuzzleGenerationException] if no valid puzzle can be produced
  /// within [maxAttempts]. Never returns an unverified puzzle.
  Puzzle generate({
    required int size,
    required int seed,
    int? generatorVersion,
    Difficulty? targetDifficulty,
  }) {
    if (!kSupportedBoardSizes.contains(size)) {
      throw PuzzleGenerationException(
        size: size,
        seed: seed,
        attempts: 0,
        reason: 'Unsupported size $size',
      );
    }

    final gv = generatorVersion ?? kGeneratorVersion;
    Puzzle? bestByDifficulty;
    double bestDistance = double.infinity;

    for (int attempt = 0; attempt < kMaxGenerationAttempts; attempt++) {
      // Per-attempt deterministic stream: seed + attempt.
      final rng = SeededRandom(_attemptSeed(seed, gv, attempt));

      final solution = _generateSolution(size, rng);
      if (solution == null) continue;

      final regionGenerator = RegionGenerator(rng);
      final regionMap = regionGenerator.generate(size, solution);
      if (regionMap == null) continue;

      final puzzle = _buildPuzzle(
          id: _makeId(size, seed, gv),
          size: size,
          seed: seed,
          generatorVersion: gv,
          regionMap: regionMap,
          solution: solution);

      // Validate structure + uniqueness before trusting it.
      if (RegionValidator.validate(puzzle) != null) continue;
      final count = QueensSolver.countSolutions(puzzle);
      if (count != 1) continue;

      final classified =
          DifficultyEngine.classify(puzzle);
      final scoredPuzzle = puzzle.withDifficultyScore(classified);
      final structOk = ConstraintEngine.validatePuzzle(scoredPuzzle) == null;
      if (!structOk) continue;

      if (targetDifficulty == null) return scoredPuzzle;

      if (classified.difficulty == targetDifficulty) {
        return scoredPuzzle;
      }
      final distance = _difficultyDistance(classified, targetDifficulty);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestByDifficulty = scoredPuzzle;
      }
    }

    // Fall back to the closest-difficulty verified puzzle.
    if (targetDifficulty != null && bestByDifficulty != null) {
      return bestByDifficulty;
    }

    throw PuzzleGenerationException(
      size: size,
      seed: seed,
      attempts: kMaxGenerationAttempts,
    );
  }

  int _attemptSeed(int seed, int gv, int attempt) {
    var x = seed;
    x ^= (gv * 2654435761);
    x += (attempt + 1) * 40503;
    x &= 0xFFFFFFFF;
    return x;
  }

  double _difficultyDistance(DifficultyScore a, Difficulty b) {
    final order = {Difficulty.easy: 0, Difficulty.medium: 1, Difficulty.hard: 2, Difficulty.expert: 3};
    return (order[a.difficulty]! - order[b]!).abs().toDouble();
  }

  String _makeId(int size, int seed, int gv) => 'q$gv-s$seed-n$size';

  /// Generates N queens, one per row and column, no two king-adjacent.
  /// Backtracking with shuffled column order.
  List<Position>? _generateSolution(int size, SeededRandom rng) {
    final placements = <Position>[];
    if (_place(0, size, rng, placements)) return placements;
    return null;
  }

  bool _place(int row, int size, SeededRandom rng, List<Position> acc) {
    if (row == size) return true;
    final cols = List.generate(size, (i) => i);
    rng.shuffle(cols);
    for (final col in cols) {
      final pos = Position(row, col);
      var ok = true;
      for (final p in acc) {
        if (p.col == col || pos.isKingAdjacentTo(p)) {
          ok = false;
          break;
        }
      }
      if (!ok) continue;
      acc.add(pos);
      if (_place(row + 1, size, rng, acc)) return true;
      acc.removeLast();
    }
    return false;
  }

  Puzzle _buildPuzzle({
    required String id,
    required int size,
    required int seed,
    required int generatorVersion,
    required List<List<int>> regionMap,
    required List<Position> solution,
  }) {
    return Puzzle(
      id: id,
      size: size,
      regionMap: regionMap,
      solution: solution,
      seed: seed,
      generatorVersion: generatorVersion,
      difficultyScore: const DifficultyScore(
        humanScore: 0,
        computationalScore: 0,
        finalScore: 0,
        difficulty: Difficulty.easy,
        humanMetrics: DifficultyMetrics.empty(),
        computationalMetrics: SolverMetrics.empty(),
        solvedByDeduction: false,
      ),
    );
  }
}

extension _PuzzleWithScore on Puzzle {
  Puzzle withDifficultyScore(DifficultyScore score) => Puzzle(
        id: id,
        size: size,
        regionMap: regionMap,
        solution: solution,
        seed: seed,
        generatorVersion: generatorVersion,
        difficultyScore: score,
      );
}

/// Removed placeholder typedef.