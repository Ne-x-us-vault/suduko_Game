/// Persistent aggregate statistics. All counters are real recorded values.
class PlayerStatistics {
  int gamesStarted;
  int gamesCompleted;
  int fastestTimeSeconds;
  int totalTimeSeconds;
  int bestScore;
  int totalScore;
  int totalMistakes;
  int totalHints;
  int totalQueensPlaced;
  int currentStreak;
  int longestStreak;
  String? lastDailyCompletionDate; // yyyy-MM-dd
  int dailyChallengesCompleted;
  int quickPlayCompletions;
  Map<String, int> completionsByDifficulty;
  Map<String, int> completionsBySize;
  int noMistakeSolves;
  int noHintSolves;

  PlayerStatistics({
    this.gamesStarted = 0,
    this.gamesCompleted = 0,
    this.fastestTimeSeconds = 0,
    this.totalTimeSeconds = 0,
    this.bestScore = 0,
    this.totalScore = 0,
    this.totalMistakes = 0,
    this.totalHints = 0,
    this.totalQueensPlaced = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastDailyCompletionDate,
    this.dailyChallengesCompleted = 0,
    this.quickPlayCompletions = 0,
    Map<String, int>? completionsByDifficulty,
    Map<String, int>? completionsBySize,
    this.noMistakeSolves = 0,
    this.noHintSolves = 0,
  })  : completionsByDifficulty = completionsByDifficulty ?? {},
        completionsBySize = completionsBySize ?? {};

  double get averageTimeSeconds =>
      gamesCompleted == 0 ? 0 : totalTimeSeconds / gamesCompleted;

  double get averageScore =>
      gamesCompleted == 0 ? 0 : totalScore / gamesCompleted;

  double get completionRate =>
      gamesStarted == 0 ? 0 : (gamesCompleted / gamesStarted * 100);

  void recordGameStart() => gamesStarted++;

  /// Records a completion event.
  void recordCompletion({
    required int timeSeconds,
    required int score,
    required int mistakes,
    required int hints,
    required int queensPlaced,
    required String difficultyName,
    required String sizeName,
    required bool isDaily,
    required bool isQuickPlay,
  }) {
    gamesCompleted++;
    totalTimeSeconds += timeSeconds;
    totalScore += score;
    totalMistakes += mistakes;
    totalHints += hints;
    totalQueensPlaced += queensPlaced;

    if (fastestTimeSeconds == 0 || timeSeconds < fastestTimeSeconds) {
      fastestTimeSeconds = timeSeconds;
    }
    if (score > bestScore) bestScore = score;
    if (mistakes == 0) noMistakeSolves++;
    if (hints == 0) noHintSolves++;

    completionsByDifficulty[difficultyName] =
        (completionsByDifficulty[difficultyName] ?? 0) + 1;
    completionsBySize[sizeName] =
        (completionsBySize[sizeName] ?? 0) + 1;

    if (isDaily) {
      dailyChallengesCompleted++;
    }
    if (isQuickPlay) {
      quickPlayCompletions++;
    }
  }

  Map<String, dynamic> toJson() => {
        'gamesStarted': gamesStarted,
        'gamesCompleted': gamesCompleted,
        'fastestTimeSeconds': fastestTimeSeconds,
        'totalTimeSeconds': totalTimeSeconds,
        'bestScore': bestScore,
        'totalScore': totalScore,
        'totalMistakes': totalMistakes,
        'totalHints': totalHints,
        'totalQueensPlaced': totalQueensPlaced,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastDailyCompletionDate': lastDailyCompletionDate,
        'dailyChallengesCompleted': dailyChallengesCompleted,
        'quickPlayCompletions': quickPlayCompletions,
        'completionsByDifficulty': completionsByDifficulty,
        'completionsBySize': completionsBySize,
        'noMistakeSolves': noMistakeSolves,
        'noHintSolves': noHintSolves,
      };

  factory PlayerStatistics.fromJson(Map<String, dynamic> json) =>
      PlayerStatistics(
        gamesStarted: json['gamesStarted'] as int? ?? 0,
        gamesCompleted: json['gamesCompleted'] as int? ?? 0,
        fastestTimeSeconds: json['fastestTimeSeconds'] as int? ?? 0,
        totalTimeSeconds: json['totalTimeSeconds'] as int? ?? 0,
        bestScore: json['bestScore'] as int? ?? 0,
        totalScore: json['totalScore'] as int? ?? 0,
        totalMistakes: json['totalMistakes'] as int? ?? 0,
        totalHints: json['totalHints'] as int? ?? 0,
        totalQueensPlaced: json['totalQueensPlaced'] as int? ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        lastDailyCompletionDate: json['lastDailyCompletionDate'] as String?,
        dailyChallengesCompleted: json['dailyChallengesCompleted'] as int? ?? 0,
        quickPlayCompletions: json['quickPlayCompletions'] as int? ?? 0,
        completionsByDifficulty: _stringIntMap(json['completionsByDifficulty']),
        completionsBySize: _stringIntMap(json['completionsBySize']),
        noMistakeSolves: json['noMistakeSolves'] as int? ?? 0,
        noHintSolves: json['noHintSolves'] as int? ?? 0,
      );

  static Map<String, int> _stringIntMap(dynamic value) {
    if (value is! Map) return {};
    return value.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
  }
}