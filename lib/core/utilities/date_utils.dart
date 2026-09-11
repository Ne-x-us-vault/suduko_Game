/// Date/time strategy for the Daily Challenge and streaks.
///
/// The Daily Challenge is tied to the player's *local* calendar date. All
/// comparisons are done on a normalized "date key" (yyyy-MM-dd) so timezones,
/// midnight and DST transitions behave predictably.

class DateUtils {
  DateUtils._();

  /// Normalized local date key for [date], e.g. `2026-09-11`.
  static String dateKey(DateTime date) {
    final local = date.toLocal();
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    return '${local.year}-$mm-$dd';
  }

  static DateTime parseDateKey(String key) {
    final parts = key.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  /// The date key for "yesterday" relative to [date].
  static String previousDateKey(DateTime date) {
    final local = date.toLocal();
    return dateKey(DateTime(local.year, local.month, local.day - 1));
  }

  /// True when [a] and [b] are consecutive calendar days (a is one day before b).
  static bool isNextDay(String a, String b) {
    final dateA = parseDateKey(a);
    final dateB = parseDateKey(b);
    return dateB.difference(dateA).inDays == 1;
  }

  /// Seconds until local midnight (for scheduling daily refresh).
  static Duration secondsUntilMidnight(DateTime now) {
    final local = now.toLocal();
    final nextMidnight = DateTime(local.year, local.month, local.day + 1);
    return nextMidnight.difference(now.toLocal());
  }
}