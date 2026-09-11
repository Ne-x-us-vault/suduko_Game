import '../../core/utilities/date_utils.dart';
import '../statistics/statistics_service.dart';

/// Stateless streak service. All streak logic operates on the persisted
/// `PlayerStatistics` so state is never duplicated.
class StreakService {
  StreakService._();

  /// Call after a Daily Challenge completion. Returns the new streak value.
  static int recordDailyCompletion(PlayerStatistics stats, DateTime now) {
    final today = DateUtils.dateKey(now);
    final last = stats.lastDailyCompletionDate;

    if (last == null || !DateUtils.isNextDay(last, today)) {
      // First completion, or a missed day — reset to 1 (if this is today's
      // first completion).
      if (last == today) {
        // Already recorded today; no change.
        return stats.currentStreak;
      }
      stats.currentStreak = 1;
    } else {
      stats.currentStreak++;
    }
    if (stats.currentStreak > stats.longestStreak) {
      stats.longestStreak = stats.currentStreak;
    }
    stats.lastDailyCompletionDate = today;
    return stats.currentStreak;
  }

  /// Current streak for display, considering whether a day was missed.
  static int computeStreak(PlayerStatistics stats, DateTime now) {
    final today = DateUtils.dateKey(now);
    final last = stats.lastDailyCompletionDate;
    if (last == null) return 0;
    if (last == today) return stats.currentStreak;
    if (DateUtils.isNextDay(last, today)) return stats.currentStreak;
    return 0; // streak broken by a missed day
  }
}