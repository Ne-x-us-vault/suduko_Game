import 'package:flutter_test/flutter_test.dart';
import 'package:queens_game/game/achievements/achievement_service.dart';
import 'package:queens_game/game/model/difficulty.dart';
import 'package:queens_game/game/model/game_mode.dart';
import 'package:queens_game/game/model/position.dart';
import 'package:queens_game/game/model/puzzle.dart';
import 'package:queens_game/game/scoring/scoring_service.dart';
import 'package:queens_game/game/statistics/statistics_service.dart';
import 'package:queens_game/game/streaks/streak_service.dart';

Puzzle _puzzle({Difficulty difficulty = Difficulty.easy, int size = 6}) {
  return Puzzle(
    id: 'svc-$size',
    size: size,
    regionMap: List.generate(size, (r) => List.generate(size, (c) => r)),
    solution: List.generate(size, (r) => Position(r, (r + 1) % size)),
    seed: 0,
    generatorVersion: 1,
    difficultyScore: DifficultyScore(
      humanScore: 10,
      computationalScore: 5,
      finalScore: 15,
      difficulty: difficulty,
      humanMetrics: const DifficultyMetrics.empty(),
      computationalMetrics: const SolverMetrics.empty(),
      solvedByDeduction: false,
    ),
  );
}

void main() {
  group('ScoringService', () {
    test('deterministic: same inputs yield the same score', () {
      final puzzle = _puzzle();
      final a = ScoringService.compute(
        puzzle: puzzle,
        elapsed: const Duration(seconds: 120),
        mistakes: 1,
        hintsUsed: 0,
        queensPlaced: const [Position(0, 0)],
        streak: 2,
        mode: GameMode.quickPlay,
      );
      final b = ScoringService.compute(
        puzzle: puzzle,
        elapsed: const Duration(seconds: 120),
        mistakes: 1,
        hintsUsed: 0,
        queensPlaced: const [Position(0, 0)],
        streak: 2,
        mode: GameMode.quickPlay,
      );
      expect(a.finalScore, b.finalScore);
    });

    test('mistakes and hints only reduce the score', () {
      final puzzle = _puzzle();
      final clean = ScoringService.compute(
        puzzle: puzzle,
        elapsed: const Duration(seconds: 120),
        mistakes: 0,
        hintsUsed: 0,
        queensPlaced: const [],
        streak: 0,
        mode: GameMode.quickPlay,
      );
      final sloppy = ScoringService.compute(
        puzzle: puzzle,
        elapsed: const Duration(seconds: 120),
        mistakes: 3,
        hintsUsed: 2,
        queensPlaced: const [],
        streak: 0,
        mode: GameMode.quickPlay,
      );
      expect(sloppy.finalScore, lessThanOrEqualTo(clean.finalScore));
      expect(sloppy.mistakePenalty, greaterThan(0));
      expect(sloppy.hintPenalty, greaterThan(0));
    });

    test('base score scales with board size', () {
      final large = ScoringService.compute(
        puzzle: _puzzle(size: 10),
        elapsed: const Duration(seconds: 60),
        mistakes: 0,
        hintsUsed: 0,
        queensPlaced: const [],
        streak: 0,
        mode: GameMode.quickPlay,
      );
      final small = ScoringService.compute(
        puzzle: _puzzle(size: 6),
        elapsed: const Duration(seconds: 60),
        mistakes: 0,
        hintsUsed: 0,
        queensPlaced: const [],
        streak: 0,
        mode: GameMode.quickPlay,
      );
      expect(large.baseScore, greaterThan(small.baseScore));
    });

    test('difficulty bonus increases with difficulty', () {
      final easy = ScoringService.compute(
        puzzle: _puzzle(difficulty: Difficulty.easy),
        elapsed: const Duration(seconds: 90),
        mistakes: 0,
        hintsUsed: 0,
        queensPlaced: const [],
        streak: 0,
        mode: GameMode.dailyChallenge,
      );
      final expert = ScoringService.compute(
        puzzle: _puzzle(difficulty: Difficulty.expert),
        elapsed: const Duration(seconds: 90),
        mistakes: 0,
        hintsUsed: 0,
        queensPlaced: const [],
        streak: 0,
        mode: GameMode.dailyChallenge,
      );
      expect(expert.difficultyBonus, greaterThan(easy.difficultyBonus));
    });

    test('streak bonus is capped at 250', () {
      final puzzle = _puzzle();
      final multi = ScoringService.compute(
        puzzle: puzzle,
        elapsed: const Duration(seconds: 90),
        mistakes: 0,
        hintsUsed: 0,
        queensPlaced: const [],
        streak: 100,
        mode: GameMode.dailyChallenge,
      );
      expect(multi.streakBonus, 250);
    });

    test('perfect only when zero mistakes and hints', () {
      final puzzle = _puzzle();
      final perfect = ScoringService.compute(
        puzzle: puzzle,
        elapsed: const Duration(seconds: 90),
        mistakes: 0,
        hintsUsed: 0,
        queensPlaced: const [],
        streak: 0,
        mode: GameMode.dailyChallenge,
      );
      expect(perfect.perfect, isTrue);
      final hinted = ScoringService.compute(
        puzzle: puzzle,
        elapsed: const Duration(seconds: 90),
        mistakes: 0,
        hintsUsed: 1,
        queensPlaced: const [],
        streak: 0,
        mode: GameMode.dailyChallenge,
      );
      expect(hinted.perfect, isFalse);
    });

    test('ScoreBreakdown round-trips through JSON', () {
      final s = ScoringService.compute(
        puzzle: _puzzle(),
        elapsed: const Duration(seconds: 45),
        mistakes: 1,
        hintsUsed: 0,
        queensPlaced: const [],
        streak: 3,
        mode: GameMode.dailyChallenge,
      );
      final r = ScoreBreakdown.fromJson(s.toJson());
      expect(r.finalScore, s.finalScore);
      expect(r.mistakePenalty, s.mistakePenalty);
      expect(r.perfect, s.perfect);
    });
  });

  group('StreakService', () {
    test('first completion starts a streak of 1', () {
      final stats = PlayerStatistics();
      final streak = StreakService.recordDailyCompletion(
          stats, DateTime(2026, 9, 12, 9));
      expect(streak, 1);
      expect(stats.currentStreak, 1);
      expect(stats.longestStreak, 1);
    });

    test('consecutive days increment the streak', () {
      final stats = PlayerStatistics();
      StreakService.recordDailyCompletion(stats, DateTime(2026, 9, 12));
      expect(
          StreakService.recordDailyCompletion(stats, DateTime(2026, 9, 13)), 2);
      expect(
          StreakService.recordDailyCompletion(stats, DateTime(2026, 9, 14)), 3);
      expect(stats.longestStreak, 3);
    });

    test('a missed day resets the streak to 1', () {
      final stats = PlayerStatistics();
      StreakService.recordDailyCompletion(stats, DateTime(2026, 9, 12));
      StreakService.recordDailyCompletion(stats, DateTime(2026, 9, 13));
      // Skips 9/14, resumes 9/16.
      final streak = StreakService.recordDailyCompletion(
          stats, DateTime(2026, 9, 16));
      expect(streak, 1);
      expect(stats.longestStreak, 2);
    });

    test('completing twice the same day does not inflate the streak', () {
      final stats = PlayerStatistics();
      StreakService.recordDailyCompletion(stats, DateTime(2026, 9, 12, 8));
      final second =
          StreakService.recordDailyCompletion(stats, DateTime(2026, 9, 12, 20));
      expect(second, 1);
    });

    test('computeStreak reports 0 after a missed day', () {
      final stats = PlayerStatistics();
      StreakService.recordDailyCompletion(stats, DateTime(2026, 9, 12));
      expect(
          StreakService.computeStreak(stats, DateTime(2026, 9, 14)), 0);
      expect(
          StreakService.computeStreak(stats, DateTime(2026, 9, 13)), 1);
    });
  });

  group('PlayerStatistics', () {
    test('starts empty and records completions', () {
      final stats = PlayerStatistics();
      stats.recordGameStart();
      stats.recordCompletion(
        timeSeconds: 90,
        score: 900,
        mistakes: 1,
        hints: 0,
        queensPlaced: 6,
        difficultyName: 'medium',
        sizeName: '6',
        isDaily: true,
        isQuickPlay: false,
      );
      expect(stats.gamesStarted, 1);
      expect(stats.gamesCompleted, 1);
      expect(stats.fastestTimeSeconds, 90);
      expect(stats.completionsByDifficulty['medium'], 1);
      expect(stats.completionsBySize['6'], 1);
      expect(stats.dailyChallengesCompleted, 1);
      expect(stats.completionRate, 100);
    });

    test('fastest time tracks the minimum', () {
      final stats = PlayerStatistics();
      stats.recordCompletion(
          timeSeconds: 200, score: 1, mistakes: 0, hints: 0, queensPlaced: 6,
          difficultyName: 'easy', sizeName: '6', isDaily: false, isQuickPlay: true);
      stats.recordCompletion(
          timeSeconds: 80, score: 1, mistakes: 0, hints: 0, queensPlaced: 6,
          difficultyName: 'easy', sizeName: '6', isDaily: false, isQuickPlay: true);
      expect(stats.fastestTimeSeconds, 80);
    });

    test('round-trips through JSON', () {
      final stats = PlayerStatistics();
      stats.recordGameStart();
      stats.recordCompletion(
          timeSeconds: 60, score: 1200, mistakes: 0, hints: 0, queensPlaced: 7,
          difficultyName: 'hard', sizeName: '7', isDaily: true, isQuickPlay: false);
      final restored = PlayerStatistics.fromJson(stats.toJson());
      expect(restored.gamesStarted, 1);
      expect(restored.gamesCompleted, 1);
      expect(restored.bestScore, 1200);
      expect(restored.completionsByDifficulty['hard'], 1);
      expect(restored.noMistakeSolves, 1);
    });
  });

  group('AchievementService', () {
    AchievementProgress progress({
      int gamesCompleted = 0,
      int fastest = 0,
      bool noMistakes = false,
      bool noHints = false,
      bool perfect = false,
      int size = 0,
      int longest = 0,
      int daily = 0,
      String difficulty = 'easy',
      int quick = 0,
    }) =>
        AchievementProgress(
          gamesCompleted: gamesCompleted,
          fastestTimeSeconds: fastest,
          noMistakes: noMistakes,
          noHints: noHints,
          perfectGame: perfect,
          size: size,
          currentStreak: longest,
          longestStreak: longest,
          dailyCompleted: daily,
          difficultyName: difficulty,
          quickPlayGames: quick,
        );

    test('first solve unlocks on first completion', () {
      final unlocked = AchievementService.evaluate(progress(gamesCompleted: 1), {});
      expect(unlocked, contains(AchievementId.firstSolve));
    });

    test('already-unlocked achievements are not re-returned', () {
      final unlocked = AchievementService.evaluate(
        progress(gamesCompleted: 1),
        {AchievementId.firstSolve: true},
      );
      expect(unlocked, isEmpty);
    });

    test('expert solver requires an expert completion', () {
      final unlocked = AchievementService.evaluate(
        progress(gamesCompleted: 1, difficulty: 'expert'),
        {},
      );
      expect(unlocked, contains(AchievementId.expertSolver));
    });

    test('streak achievements need the appropriate streak length', () {
      final seven = AchievementService.evaluate(progress(longest: 7), {});
      expect(seven, contains(AchievementId.sevenDayStreak));
      expect(seven, isNot(contains(AchievementId.thirtyDayStreak)));
    });

    test('every definition has a matching banner', () {
      for (final d in AchievementService.definitions) {
        expect(d.title, isNotEmpty);
        expect(AchievementService.definitionFor(d.id).id, d.id);
      }
    });

    test('AchievementState round-trips through JSON', () {
      final state = AchievementState(
          id: AchievementId.perfectGame, unlocked: true, unlockedAt: DateTime(2026, 9, 12));
      final restored = AchievementState.fromJson(state.toJson());
      expect(restored.id, AchievementId.perfectGame);
      expect(restored.unlocked, isTrue);
    });
  });
}