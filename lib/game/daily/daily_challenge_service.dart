import '../../core/constants/app_constants.dart';
import '../../core/utilities/date_utils.dart';
import '../../core/utilities/seeded_random.dart';
import '../generator/puzzle_generator.dart';
import '../model/difficulty.dart';
import '../model/puzzle.dart';

/// Deterministic Daily Challenge service.
///
/// The daily puzzle for a given local date is a pure function of
/// `(dateKey, generatorVersion)` — so every player gets the same puzzle and
/// refreshing the app never changes it.
class DailyChallengeService {
  DailyChallengeService._();

  static const PuzzleGenerator _generator = PuzzleGenerator();

  /// Deterministic seed from the date and generator version.
  static int getDailySeed([DateTime? now]) {
    final dateKey = DateUtils.dateKey(now ?? DateTime.now());
    return fnv1a('$dateKey-v$kGeneratorVersion');
  }

  /// Daily board size / difficulty (rotates deterministically by weekday so
  /// the challenge has variety).
  static int getDailySize([DateTime? now]) {
    final n = (now ?? DateTime.now()).toLocal();
    const sizes = [6, 7, 8, 7, 6, 8, 9]; // Mon..Sun
    return sizes[(n.weekday - 1) % 7];
  }

  static Difficulty getDailyDifficulty([DateTime? now]) {
    final n = (now ?? DateTime.now()).toLocal();
    const diffs = [
      Difficulty.medium,
      Difficulty.medium,
      Difficulty.hard,
      Difficulty.hard,
      Difficulty.hard,
      Difficulty.expert,
      Difficulty.expert,
    ];
    return diffs[(n.weekday - 1) % 7];
  }

  /// Generates the deterministic daily puzzle. Throws on failure (caller
  /// should surface a retry).
  static Puzzle getDailyPuzzle({DateTime? now}) {
    final size = getDailySize(now);
    final difficulty = getDailyDifficulty(now);
    return _generator.generate(
      size: size,
      seed: getDailySeed(now),
      targetDifficulty: difficulty,
    );
  }
}