import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/utilities/game_timer.dart';
import '../core/utilities/seeded_random.dart';
import '../game/achievements/achievement_service.dart';
import '../game/daily/daily_challenge_service.dart';
import '../game/generator/puzzle_generator.dart';
import '../game/model/difficulty.dart';
import '../game/model/game_mode.dart';
import '../game/model/puzzle.dart';
import '../game/scoring/scoring_service.dart';
import '../game/statistics/statistics_service.dart';
import '../game/streaks/streak_service.dart';
import '../persistence/persistence_service.dart';
import '../platform/share_service.dart';
import 'game_controller.dart';
import 'game_state.dart';

/// Everything that happens once when a game is completed.
class CompletionRecord {
  final Puzzle puzzle;
  final ScoreBreakdown score;
  final PlayerStatistics stats;
  final List<AchievementId> newlyUnlocked;
  final Map<AchievementId, AchievementState> achievements;
  final int streak;
  final String resultText;
  final GameMode mode;

  const CompletionRecord({
    required this.puzzle,
    required this.score,
    required this.stats,
    required this.newlyUnlocked,
    required this.achievements,
    required this.streak,
    required this.resultText,
    required this.mode,
  });
}

/// Central service tying the puzzle engine, persistence, statistics,
/// achievements, streaks, and scoring together. Created once at startup.
class AppServices {
  final PersistenceService persistence;
  late PlayerStatistics stats;
  late Map<AchievementId, AchievementState> achievements;
  List<String> recentPuzzleIds = [];

  /// Most recent completion (for the completion dialog). Notifies observers.
  final ValueNotifier<CompletionRecord?> lastCompletion = ValueNotifier(null);

  /// Whether a recoverable in-progress session exists at startup.
  bool hasActiveSession = false;

  /// Restored in-progress session, if any.
  GameState? restoredState;

  final PuzzleGenerator _generator = const PuzzleGenerator();
  Timer? _sessionSaveDebounce;

  AppServices({required this.persistence});

  Future<void> load() async {
    try {
      await persistence.migrateIfNeeded();
    } catch (e) {
      // Incompatible/newer data — start fresh rather than crash.
    }
    stats = await persistence.loadStatistics();
    achievements = await persistence.loadAchievements();
    recentPuzzleIds = await persistence.loadRecentPuzzleIds();
    hasActiveSession = await persistence.loadActiveSession() != null;
  }

  // ---------------------------------------------------------------------------
  // Puzzle factories
  // ---------------------------------------------------------------------------

  Future<Puzzle> generatePuzzle({
    required int size,
    required Difficulty difficulty,
    GameMode mode = GameMode.quickPlay,
  }) async {
    const maxTries = 3;
    Puzzle? puzzle;
    var seed = SeededRandom(DateTime.now().millisecondsSinceEpoch)
        .nextInt(1 << 30);
    for (var i = 0; i < maxTries; i++) {
      final candidate = _generator.generate(
        size: size,
        seed: seed,
        targetDifficulty: difficulty,
      );
      if (!recentPuzzleIds.contains(candidate.id)) {
        puzzle = candidate;
        break;
      }
      seed = SeededRandom(seed + 7919).nextInt(1 << 30);
    }
    final result = puzzle ??
        _generator.generate(
          size: size,
          seed: seed,
          targetDifficulty: difficulty,
        );
    recentPuzzleIds.add(result.id);
    if (recentPuzzleIds.length > kRecentPuzzleIdPoolSize) {
      recentPuzzleIds.removeAt(0);
    }
    await persistence.saveRecentPuzzleIds(recentPuzzleIds);
    return result;
  }

  Future<Puzzle> generateDailyPuzzle() async {
    final puzzle = DailyChallengeService.getDailyPuzzle();
    return puzzle;
  }

  // ---------------------------------------------------------------------------
  // Session persistence
  // ---------------------------------------------------------------------------

  /// Queues a (debounced) save of the active session so every move is
  /// recoverable after a crash without writing to disk continuously.
  void scheduleSessionSave(GameController controller) {
    _sessionSaveDebounce?.cancel();
    _sessionSaveDebounce = Timer(const Duration(milliseconds: 250), () {
final s = controller.current;
      if (s == null) return;
      saveSession(s);
    });
  }

  Future<void> saveSession(GameState s) async {
    final payload = {
      'puzzle': s.puzzle.toJson(),
      'state': s.toJson(),
      'savedAt': DateTime.now().toIso8601String(),
    };
    await persistence.saveActiveSession(payload);
  }

  Future<void> tryRestoreSession() async {
    final raw = await persistence.loadActiveSession();
    if (raw == null) return;
    try {
      final puzzle =
          Puzzle.fromJson((raw['puzzle'] as Map).cast<String, dynamic>());
      final stateJson = (raw['state'] as Map?)?.cast<String, dynamic>();
      if (stateJson == null) return;
      restoredState = GameState.restoreFromJson(puzzle, stateJson);
    } catch (e) {
      restoredState = null;
    }
  }

  Future<void> clearSession() => persistence.clearActiveSession();

  // ---------------------------------------------------------------------------
  // Game lifecycle
  // ---------------------------------------------------------------------------

  void recordGameStart() {
    stats.recordGameStart();
  }

  Future<CompletionRecord?> recordCompletion(GameController controller) async {
    final s = controller.current;
    if (s == null || !s.isSolved) return null;
    final mode = controller.mode;
    final isDaily = mode == GameMode.dailyChallenge;
    final isQuickPlay = mode == GameMode.quickPlay;
    final now = DateTime.now();

    // Daily streak.
    if (isDaily) {
      StreakService.recordDailyCompletion(stats, now);
    }

    final score = ScoringService.compute(
      puzzle: s.puzzle,
      elapsed: s.elapsed,
      mistakes: s.mistakes,
      hintsUsed: s.hintsUsed,
      queensPlaced: s.queens,
      streak: StreakService.computeStreak(stats, now),
      mode: mode,
    );

    stats.recordCompletion(
      timeSeconds: s.elapsed.inSeconds,
      score: score.finalScore,
      mistakes: s.mistakes,
      hints: s.hintsUsed,
      queensPlaced: s.queens.length,
      difficultyName: s.puzzle.difficulty.nameValue,
      sizeName: '${s.puzzle.size}',
      isDaily: isDaily,
      isQuickPlay: isQuickPlay,
    );

    final progress = AchievementProgress(
      gamesCompleted: stats.gamesCompleted,
      fastestTimeSeconds: stats.fastestTimeSeconds,
      noMistakes: s.mistakes == 0,
      noHints: s.hintsUsed == 0,
      perfectGame: s.mistakes == 0 && s.hintsUsed == 0,
      size: s.puzzle.size,
      currentStreak: stats.currentStreak,
      longestStreak: stats.longestStreak,
      dailyCompleted: stats.dailyChallengesCompleted,
      difficultyName: s.puzzle.difficulty.nameValue,
      quickPlayGames: stats.quickPlayCompletions,
    );

    final alreadyUnlocked = <AchievementId, bool>{
      for (final entry in achievements.entries) entry.key: entry.value.unlocked,
    };
    final newly = AchievementService.evaluate(progress, alreadyUnlocked);
    for (final id in newly) {
      achievements[id] = AchievementState(
        id: id,
        unlocked: true,
        unlockedAt: now,
      );
    }

    await persistence.saveStatistics(stats);
    await persistence.saveAchievements(achievements);
    await persistence.clearActiveSession();

    final resultText = ShareService.buildResultText(
      modeLabel: mode.label,
      size: s.puzzle.size,
      difficultyLabel: s.puzzle.difficulty.label,
      time: formatElapsed(s.elapsed),
      mistakes: s.mistakes,
      hints: s.hintsUsed,
    );

    return CompletionRecord(
      puzzle: s.puzzle,
      score: score,
      stats: stats,
      newlyUnlocked: newly,
      achievements: achievements,
      streak: StreakService.computeStreak(stats, now),
      resultText: resultText,
      mode: mode,
    );
  }

  Future<void> resetStatistics() async {
    stats = PlayerStatistics();
    await persistence.resetStatistics();
  }

  Future<void> resetAllLocalData() async {
    stats = PlayerStatistics();
    achievements = {};
    recentPuzzleIds = [];
    await persistence.resetAll();
  }

  void dispose() {
    _sessionSaveDebounce?.cancel();
  }
}

final appServicesProvider = Provider<AppServices?>((ref) => null);

/// Wires the completion handler and session persistence into the controller.
void wireController(AppServices services, GameController controller) {
  controller.onPersistRequested = () => services.scheduleSessionSave(controller);
  controller.onCompleted = (mode, dailyDate) async {
    try {
      final record = await services.recordCompletion(controller);
      services.lastCompletion.value = record;
    } catch (e) {
      // Persistence failure should never crash the running game.
    }
  };
}

/// Provides the latest completion event to the UI. This is a
/// ChangeNotifierProvider whose state is the [ValueNotifier] itself, so the
/// widget watching it rebuilds as soon as a new completion is recorded.
final lastCompletionProvider =
    ChangeNotifierProvider<ValueNotifier<CompletionRecord?>>(
  (ref) {
    final services = ref.watch(appServicesProvider);
    return services?.lastCompletion ?? ValueNotifier(null);
  },
  name: 'lastCompletionProvider',
);