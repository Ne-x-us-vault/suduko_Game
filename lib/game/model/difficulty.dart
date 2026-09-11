import 'package:flutter/foundation.dart';

/// Supported difficulty levels.
enum Difficulty { easy, medium, hard, expert }

extension DifficultyX on Difficulty {
  String get label {
    switch (this) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
      case Difficulty.expert:
        return 'Expert';
    }
  }

  String get nameValue {
    switch (this) {
      case Difficulty.easy:
        return 'easy';
      case Difficulty.medium:
        return 'medium';
      case Difficulty.hard:
        return 'hard';
      case Difficulty.expert:
        return 'expert';
    }
  }

  static Difficulty fromName(String? name) {
    switch (name) {
      case 'easy':
        return Difficulty.easy;
      case 'medium':
        return Difficulty.medium;
      case 'hard':
        return Difficulty.hard;
      case 'expert':
        return Difficulty.expert;
      default:
        return Difficulty.easy;
    }
  }
}

/// Human-oriented difficulty metrics produced by the deduction engine.
@immutable
class DifficultyMetrics {
  final int totalDeductions;
  final int forcedPlacements;
  final int forcedEliminations;
  final int longestChain;
  final int maxCandidateSetSize;
  final int unresolvedChoices;
  final int guessesRequired;
  final int highestTechniqueLevel;
  final bool solvedByDeduction;

  const DifficultyMetrics({
    required this.totalDeductions,
    required this.forcedPlacements,
    required this.forcedEliminations,
    required this.longestChain,
    required this.maxCandidateSetSize,
    required this.unresolvedChoices,
    required this.guessesRequired,
    required this.highestTechniqueLevel,
    required this.solvedByDeduction,
  });

  const DifficultyMetrics.empty()
      : totalDeductions = 0,
        forcedPlacements = 0,
        forcedEliminations = 0,
        longestChain = 0,
        maxCandidateSetSize = 0,
        unresolvedChoices = 0,
        guessesRequired = 0,
        highestTechniqueLevel = 0,
        solvedByDeduction = false;

  Map<String, dynamic> toJson() => {
        'totalDeductions': totalDeductions,
        'forcedPlacements': forcedPlacements,
        'forcedEliminations': forcedEliminations,
        'longestChain': longestChain,
        'maxCandidateSetSize': maxCandidateSetSize,
        'unresolvedChoices': unresolvedChoices,
        'guessesRequired': guessesRequired,
        'highestTechniqueLevel': highestTechniqueLevel,
        'solvedByDeduction': solvedByDeduction,
      };

  factory DifficultyMetrics.fromJson(Map<String, dynamic> json) =>
      DifficultyMetrics(
        totalDeductions: json['totalDeductions'] as int? ?? 0,
        forcedPlacements: json['forcedPlacements'] as int? ?? 0,
        forcedEliminations: json['forcedEliminations'] as int? ?? 0,
        longestChain: json['longestChain'] as int? ?? 0,
        maxCandidateSetSize: json['maxCandidateSetSize'] as int? ?? 0,
        unresolvedChoices: json['unresolvedChoices'] as int? ?? 0,
        guessesRequired: json['guessesRequired'] as int? ?? 0,
        highestTechniqueLevel: json['highestTechniqueLevel'] as int? ?? 0,
        solvedByDeduction: json['solvedByDeduction'] as bool? ?? false,
      );
}

/// Combined, deterministic difficulty score.
@immutable
class DifficultyScore {
  final double humanScore;
  final double computationalScore;
  final double finalScore;
  final Difficulty difficulty;
  final DifficultyMetrics humanMetrics;
  final SolverMetrics computationalMetrics;
  final bool solvedByDeduction;

  const DifficultyScore({
    required this.humanScore,
    required this.computationalScore,
    required this.finalScore,
    required this.difficulty,
    required this.humanMetrics,
    required this.computationalMetrics,
    required this.solvedByDeduction,
  });

  Map<String, dynamic> toJson() => {
        'humanScore': humanScore,
        'computationalScore': computationalScore,
        'finalScore': finalScore,
        'difficulty': difficulty.nameValue,
        'humanMetrics': humanMetrics.toJson(),
        'computationalMetrics': computationalMetrics.toJson(),
        'solvedByDeduction': solvedByDeduction,
      };

  factory DifficultyScore.fromJson(Map<String, dynamic> json) =>
      DifficultyScore(
        humanScore: (json['humanScore'] as num).toDouble(),
        computationalScore: (json['computationalScore'] as num).toDouble(),
        finalScore: (json['finalScore'] as num).toDouble(),
        difficulty: DifficultyX.fromName(json['difficulty'] as String?),
        humanMetrics: DifficultyMetrics.fromJson(
            json['humanMetrics'] as Map<String, dynamic>? ?? {}),
        computationalMetrics: SolverMetrics.fromJson(
            json['computationalMetrics'] as Map<String, dynamic>? ?? {}),
        solvedByDeduction: json['solvedByDeduction'] as bool? ?? false,
      );
}

/// Metrics exposed by the constraint solver (computational difficulty).
@immutable
class SolverMetrics {
  final int recursiveCalls;
  final int maxSearchDepth;
  final int branchCount;
  final int candidatesEliminated;
  final int forcedPlacements;
  final int propagationRounds;
  final Duration solveTime;

  const SolverMetrics({
    required this.recursiveCalls,
    required this.maxSearchDepth,
    required this.branchCount,
    required this.candidatesEliminated,
    required this.forcedPlacements,
    required this.propagationRounds,
    required this.solveTime,
  });

  const SolverMetrics.empty()
      : recursiveCalls = 0,
        maxSearchDepth = 0,
        branchCount = 0,
        candidatesEliminated = 0,
        forcedPlacements = 0,
        propagationRounds = 0,
        solveTime = Duration.zero;

  Map<String, dynamic> toJson() => {
        'recursiveCalls': recursiveCalls,
        'maxSearchDepth': maxSearchDepth,
        'branchCount': branchCount,
        'candidatesEliminated': candidatesEliminated,
        'forcedPlacements': forcedPlacements,
        'propagationRounds': propagationRounds,
        'solveTimeMillis': solveTime.inMilliseconds,
      };

  factory SolverMetrics.fromJson(Map<String, dynamic> json) => SolverMetrics(
        recursiveCalls: json['recursiveCalls'] as int? ?? 0,
        maxSearchDepth: json['maxSearchDepth'] as int? ?? 0,
        branchCount: json['branchCount'] as int? ?? 0,
        candidatesEliminated: json['candidatesEliminated'] as int? ?? 0,
        forcedPlacements: json['forcedPlacements'] as int? ?? 0,
        propagationRounds: json['propagationRounds'] as int? ?? 0,
        solveTime: Duration(
            milliseconds: json['solveTimeMillis'] as int? ?? 0),
      );
}