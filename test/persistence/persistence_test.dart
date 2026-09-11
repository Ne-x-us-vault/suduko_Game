import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:queens_game/data/storage/kv_storage.dart';
import 'package:queens_game/data/storage/migrations.dart';
import 'package:queens_game/game/statistics/statistics_service.dart';
import 'package:queens_game/state/persistence_service.dart';

void main() {
  group('MemoryStorage', () {
    test('write / read / delete / keys', () async {
      final storage = MemoryStorage();
      await storage.write('a', '1');
      await storage.write('b', '2');
      expect(await storage.read('a'), '1');
      expect(await storage.read('missing'), isNull);
      expect(await storage.keys(), containsAll(['a', 'b']));
      await storage.delete('a');
      expect(await storage.read('a'), isNull);
      expect(await storage.keys(), ['b']);
    });

    test('quarantines corrupt JSON files', () async {
      final storage = MemoryStorage();
      await storage.write('session.json', '{bad json[[[');
      expect(await storage.quarantineCorruptFiles(), 1);
    });
  });

  group('PersistenceService', () {
    test('loads with default schema when fresh', () async {
      final storage = MemoryStorage();
      final svc = PersistenceService(storage: storage);
      await svc.load();
      expect(svc.version, 1);
    });

    test('saves and restores session JSON', () async {
      final storage = MemoryStorage();
      final svc = PersistenceService(storage: storage);
      await svc.load();
      final session = {
        'puzzle': <String, dynamic>{
          'id': 't1',
          'size': 6,
          'regionMap': [
            [0, 0, 1, 1, 2, 2],
            [0, 0, 1, 1, 2, 2],
            [3, 3, 3, 3, 4, 4],
            [3, 3, 3, 3, 4, 4],
            [5, 5, 5, 5, 5, 5],
            [5, 5, 5, 5, 5, 5],
          ],
          'solution': [
            {'row': 0, 'col': 1},
            {'row': 1, 'col': 3},
            {'row': 2, 'col': 0},
            {'row': 3, 'col': 2},
          ],
          'seed': 0,
          'generatorVersion': 1,
          'difficultyScore': <String, dynamic>{
            'humanScore': 0,
            'computationalScore': 0,
            'finalScore': 0,
            'difficulty': 'easy',
            'humanMetrics': <String, dynamic>{},
            'computationalMetrics': <String, dynamic>{},
            'solvedByDeduction': false,
          },
        },
        'placed': <dynamic>[],
        'mistakes': 0,
        'hintsUsed': 0,
        'secondsElapsed': 0,
        'startedAt': DateTime.utc(2026, 9, 12).toIso8601String(),
        'config': <String, dynamic>{
          'strictMode': true,
          'showMistakes': true,
          'difficulty': 'hard',
        },
      };
      await svc.saveSession(session);
      final restored = await svc.restoreSession();
      expect(restored, isNotNull);
      expect(restored!['puzzle']['id'], 't1');
    });

    test('clearSession erases the session', () async {
      final storage = MemoryStorage();
      final svc = PersistenceService(storage: storage);
      await svc.load();
      await svc.saveSession({'puzzle': {}});
      await svc.clearSession();
      expect(await svc.restoreSession(), isNull);
    });

    test('saves and restores statistics', () async {
      final storage = MemoryStorage();
      final svc = PersistenceService(storage: storage);
      await svc.load();
      final stats = PlayerStatistics(gamesStarted: 10, gamesCompleted: 7);
      await svc.saveStatistics(stats);
      final restored = await svc.restoreStatistics();
      expect(restored, isNotNull);
      expect(restored!.gamesStarted, 10);
      expect(restored.gamesCompleted, 7);
    });

    test('migrateIfNeeded no-ops on current schema', () async {
      final storage = MemoryStorage();
      final svc = PersistenceService(storage: storage);
      await svc.load();
      // Should not throw; schema stays 1.
      expect(svc.version, 1);
    });

    test('corrupt session file is quarantined on load', () async {
      final storage = MemoryStorage();
      await storage.write('session.json', '{not valid}');
      final svc = PersistenceService(storage: storage);
      await svc.load();
      expect(await svc.restoreSession(), isNull);
    });

    test('settings save/restore round-trips', () async {
      final storage = MemoryStorage();
      final svc = PersistenceService(storage: storage);
      await svc.load();
      await svc.saveSettings({'strictMode': true});
      final restored = await svc.restoreSettings();
      expect(restored?['strictMode'], isTrue);
    });

    test('clearAll erases all keys', () async {
      final storage = MemoryStorage();
      final svc = PersistenceService(storage: storage);
      await svc.load();
      await svc.saveSettings({'a': 1});
      await svc.saveStatistics(PlayerStatistics());
      await svc.saveSession({'b': 2});
      await svc.clearAll();
      expect(await svc.restoreSettings(), isNull);
      expect(await svc.restoreStatistics(), isNull);
      expect(await svc.restoreSession(), isNull);
    });
  });

  group('Migration', () {
    test('migrateSchemaV1ToV2 is a no-op and returns null', () {
      expect(migrateSchemaV1ToV2({}), isNull);
    });
  });
}