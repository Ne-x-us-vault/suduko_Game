import 'dart:convert';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exceptions.dart';
import '../core/logging/log_service.dart';
import '../game/achievements/achievement_service.dart';
import '../game/settings/game_settings.dart';
import '../game/statistics/statistics_service.dart';
import 'kv_storage.dart';

/// Persists application data behind a clean abstraction.
///
/// Responsibilities:
///   • settings, statistics, achievements, recent puzzle ids, game history
///   • live game session recovery
///   • schema versioning + migrations
///   • graceful recovery from corrupt data (never crashes the app)
class PersistenceService {
  static const _storagePrefix = 'queens.';

  final KVStorage storage;

  PersistenceService({required this.storage});

  // ---------------------------------------------------------------------------
  // Schema / version
  // ---------------------------------------------------------------------------

  Future<int> readSchemaVersion() async {
    final raw = await storage.read('${_storagePrefix}schema');
    if (raw == null) return 1; // absent store = schema 1
    try {
      return int.parse(raw);
    } catch (_) {
      return 1;
    }
  }

  Future<void> _writeSchemaVersion(int version) async {
    await storage.write('${_storagePrefix}schema', '$version');
  }

  /// Detects a newer incompatible schema and quarantines it so the app can
  /// still start with empty data rather than crashing.
  Future<void> migrateIfNeeded() async {
    final current = await readSchemaVersion();
    if (current == kSchemaVersion) return;
    LogService.info('Storage schema $current -> $kSchemaVersion');
    if (current > kSchemaVersion) {
      // Newer data than this app understands — keep it quarantined.
      throw const PersistenceException(
          'Data was written by a newer app version');
    }
    await _writeSchemaVersion(kSchemaVersion);
  }

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  Future<GameSettings> loadSettings() async {
    final raw = await storage.read('${_storagePrefix}settings');
    if (raw == null) return const GameSettings();
    try {
      return GameSettings.fromJson(_decode(raw));
    } catch (e) {
      LogService.warning('Failed to parse settings: $e');
      return const GameSettings();
    }
  }

  Future<void> saveSettings(GameSettings settings) async {
    await storage.write(
        '${_storagePrefix}settings', jsonEncode(settings.toJson()));
  }

  // ---------------------------------------------------------------------------
  // Statistics
  // ---------------------------------------------------------------------------

  Future<PlayerStatistics> loadStatistics() async {
    final raw = await storage.read('${_storagePrefix}statistics');
    if (raw == null) return PlayerStatistics();
    try {
      return PlayerStatistics.fromJson(_decode(raw));
    } catch (e) {
      LogService.warning('Failed to parse statistics: $e');
      return PlayerStatistics();
    }
  }

  Future<void> saveStatistics(PlayerStatistics stats) async {
    await storage.write('${_storagePrefix}statistics', jsonEncode(stats.toJson()));
  }

  // ---------------------------------------------------------------------------
  // Achievements
  // ---------------------------------------------------------------------------

  Future<Map<AchievementId, AchievementState>> loadAchievements() async {
    final raw = await storage.read('${_storagePrefix}achievements');
    if (raw == null) return {};
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      final map = <AchievementId, AchievementState>{};
      for (final item in list) {
        try {
          final state = AchievementState.fromJson(item);
          map[state.id] = state;
        } catch (_) {
          // Skip one bad record — never crash on it.
        }
      }
      return map;
    } catch (e) {
      LogService.warning('Failed to parse achievements: $e');
      return {};
    }
  }

  Future<void> saveAchievements(
      Map<AchievementId, AchievementState> achievements) async {
    final list = achievements.values.map((a) => a.toJson()).toList();
    await storage.write(
        '${_storagePrefix}achievements', jsonEncode(list));
  }

  // ---------------------------------------------------------------------------
  // Recent puzzle ids (duplicate avoidance)
  // ---------------------------------------------------------------------------

  Future<List<String>> loadRecentPuzzleIds() async {
    final raw = await storage.read('${_storagePrefix}recent_ids');
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRecentPuzzleIds(List<String> ids) async {
    await storage.write('${_storagePrefix}recent_ids', jsonEncode(ids));
  }

  // ---------------------------------------------------------------------------
  // Active session
  // ---------------------------------------------------------------------------

  /// Stores a game in progress so it can be resumed after process death.
  Future<void> saveActiveSession(Map<String, dynamic> payload) async {
    await storage.write('${_storagePrefix}active_session', jsonEncode(payload));
  }

  Future<Map<String, dynamic>?> loadActiveSession() async {
    final raw = await storage.read('${_storagePrefix}active_session');
    if (raw == null) return null;
    try {
      return _decode(raw);
    } catch (e) {
      LogService.warning('Failed to parse active session: $e');
      return null;
    }
  }

  Future<void> clearActiveSession() async {
    await storage.remove('${_storagePrefix}active_session');
  }

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------

  Future<void> resetStatistics() async {
    await storage.remove('${_storagePrefix}statistics');
  }

  Future<void> resetAll() async {
    await storage.remove('${_storagePrefix}settings');
    await storage.remove('${_storagePrefix}statistics');
    await storage.remove('${_storagePrefix}achievements');
    await storage.remove('${_storagePrefix}recent_ids');
    await storage.remove('${_storagePrefix}active_session');
    await storage.remove('${_storagePrefix}game_history');
    await storage.remove('${_storagePrefix}streak');
    await storage.remove('${_storagePrefix}schema');
  }

  Map<String, dynamic> _decode(String raw) {
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }
}