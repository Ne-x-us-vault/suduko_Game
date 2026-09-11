import 'package:flutter/material.dart';

/// Achievement definitions and unlock logic.
///
/// Achievements unlock from *actual* gameplay events (completion callbacks).
/// Unlock state and timestamps are persisted.

enum AchievementId {
  firstSolve,
  speedRunner,
  noMistakes,
  noHints,
  sevenBySeven,
  tenByTen,
  dailyPlayer,
  sevenDayStreak,
  thirtyDayStreak,
  perfectGame,
  expertSolver,
  quickPlayFive,
}

@immutable
class AchievementDefinition {
  final AchievementId id;
  final String title;
  final String description;
  final IconData icon;

  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class AchievementState {
  final AchievementId id;
  final bool unlocked;
  final DateTime? unlockedAt;

  const AchievementState({required this.id, required this.unlocked, this.unlockedAt});

  Map<String, dynamic> toJson() => {
        'id': id.name,
        'unlocked': unlocked,
        'unlockedAt': unlockedAt?.toIso8601String(),
      };

  factory AchievementState.fromJson(Map<String, dynamic> json) =>
      AchievementState(
        id: AchievementId.values.byName(json['id'] as String),
        unlocked: json['unlocked'] as bool? ?? false,
        unlockedAt: json['unlockedAt'] == null
            ? null
            : DateTime.tryParse(json['unlockedAt'] as String),
      );
}

/// Aggregated progress snapshot used to evaluate unlock conditions.
class AchievementProgress {
  final int gamesCompleted;
  final int fastestTimeSeconds;
  final bool noMistakes;
  final bool noHints;
  final bool perfectGame;
  final int size;
  final int currentStreak;
  final int longestStreak;
  final int dailyCompleted;
  final String difficultyName;
  final int quickPlayGames;

  const AchievementProgress({
    required this.gamesCompleted,
    required this.fastestTimeSeconds,
    required this.noMistakes,
    required this.noHints,
    required this.perfectGame,
    required this.size,
    required this.currentStreak,
    required this.longestStreak,
    required this.dailyCompleted,
    required this.difficultyName,
    required this.quickPlayGames,
  });
}

class AchievementService {
  AchievementService._();

  static const List<AchievementDefinition> definitions = [
    AchievementDefinition(
      id: AchievementId.firstSolve,
      title: 'First Solve',
      description: 'Complete your first puzzle.',
      icon: Icons.emoji_events,
    ),
    AchievementDefinition(
      id: AchievementId.speedRunner,
      title: 'Speed Runner',
      description: 'Finish a puzzle in under 60 seconds.',
      icon: Icons.bolt,
    ),
    AchievementDefinition(
      id: AchievementId.noMistakes,
      title: 'Flawless',
      description: 'Complete a puzzle with zero mistakes.',
      icon: Icons.check_circle,
    ),
    AchievementDefinition(
      id: AchievementId.noHints,
      title: 'Self Reliant',
      description: 'Complete a puzzle without using hints.',
      icon: Icons.psychology,
    ),
    AchievementDefinition(
      id: AchievementId.sevenBySeven,
      title: '7×7 Master',
      description: 'Complete a 7×7 puzzle.',
      icon: Icons.grid_on,
    ),
    AchievementDefinition(
      id: AchievementId.tenByTen,
      title: '10×10 Master',
      description: 'Complete a 10×10 puzzle.',
      icon: Icons.grid_4x4,
    ),
    AchievementDefinition(
      id: AchievementId.dailyPlayer,
      title: 'Daily Player',
      description: 'Complete your first Daily Challenge.',
      icon: Icons.calendar_month,
    ),
    AchievementDefinition(
      id: AchievementId.sevenDayStreak,
      title: 'On a Roll',
      description: 'Reach a 7-day Daily Challenge streak.',
      icon: Icons.local_fire_department,
    ),
    AchievementDefinition(
      id: AchievementId.thirtyDayStreak,
      title: 'Unstoppable',
      description: 'Reach a 30-day Daily Challenge streak.',
      icon: Icons.whatshot,
    ),
    AchievementDefinition(
      id: AchievementId.perfectGame,
      title: 'Perfect Game',
      description: 'Solve with no mistakes AND no hints.',
      icon: Icons.workspace_premium,
    ),
    AchievementDefinition(
      id: AchievementId.expertSolver,
      title: 'Expert Solver',
      description: 'Complete an Expert-difficulty puzzle.',
      icon: Icons.stars,
    ),
    AchievementDefinition(
      id: AchievementId.quickPlayFive,
      title: 'Quick Starter',
      description: 'Complete 5 quick-play puzzles.',
      icon: Icons.play_circle,
    ),
  ];

  /// Evaluates which achievements should be unlocked by the given progress,
  /// returning the newly unlocked ids.
  static List<AchievementId> evaluate(
    AchievementProgress p,
    Map<AchievementId, bool> alreadyUnlocked,
  ) {
    final newly = <AchievementId>[];
    void maybe(AchievementId id, bool condition) {
      if (condition && !(alreadyUnlocked[id] ?? false)) newly.add(id);
    }

    maybe(AchievementId.firstSolve, p.gamesCompleted >= 1);
    maybe(AchievementId.speedRunner, p.fastestTimeSeconds > 0 && p.fastestTimeSeconds < 60);
    maybe(AchievementId.noMistakes, p.noMistakes);
    maybe(AchievementId.noHints, p.noHints);
    maybe(AchievementId.sevenBySeven, p.size == 7);
    maybe(AchievementId.tenByTen, p.size == 10);
    maybe(AchievementId.dailyPlayer, p.dailyCompleted >= 1);
    maybe(AchievementId.sevenDayStreak, p.longestStreak >= 7);
    maybe(AchievementId.thirtyDayStreak, p.longestStreak >= 30);
    maybe(AchievementId.perfectGame, p.perfectGame);
    maybe(AchievementId.expertSolver, p.difficultyName == 'expert');
    maybe(AchievementId.quickPlayFive, p.quickPlayGames >= 5);

    return newly;
  }

  static AchievementDefinition definitionFor(AchievementId id) =>
      definitions.firstWhere((d) => d.id == id);
}