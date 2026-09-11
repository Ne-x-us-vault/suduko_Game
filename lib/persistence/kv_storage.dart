import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Low-level key/value storage abstraction. Two platform backends:
///   • FileStorage   — a single versioned JSON document on disk (Android/iOS)
///   • WebStorage    — SharedPreferences (Flutter Web)
abstract class KVStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

/// File-backed storage. One JSON document (indices + values) per key, stored
/// with a schema version marker so future migrations can be applied.
class FileStorage implements KVStorage {
  final String directoryPath;
  final Duration antiCorruptionCheckInterval = const Duration(minutes: 5);

  FileStorage({required this.directoryPath});

  String get _filePath => '$directoryPath/queens_store.json';

  Directory get _dir => Directory(directoryPath);

  Future<Map<String, dynamic>> _loadRaw() async {
    final file = File(_filePath);
    if (!await file.exists()) return {};
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (e) {
      // Corrupt store → quarantine the file so healthy data elsewhere is not
      // lost, then return empty.
      try {
        await file.rename('$_filePath.corrupt.${DateTime.now().millisecondsSinceEpoch}');
      } catch (_) {}
      return {};
    }
  }

  Future<Map<String, dynamic>> _loadAll() async {
    final raw = await _loadRaw();
    final data = raw['data'];
    return data is Map<String, dynamic> ? data : {};
  }

  Future<void> _save(Map<String, dynamic> all) async {
    if (!await _dir.exists()) {
      await _dir.create(recursive: true);
    }
    final doc = jsonEncode({'schemaVersion': 1, 'data': all});
    final file = File(_filePath);
    final tmp = File('$_filePath.tmp');
    await tmp.writeAsString(doc, flush: true);
    // Atomic rename — a crash mid-write never corrupts the primary file.
    if (await file.exists()) await file.delete();
    await tmp.rename(_filePath);
  }

  @override
  Future<String?> read(String key) async {
    final all = await _loadAll();
    final value = all[key];
    return value is String ? value : value == null ? null : jsonEncode(value);
  }

  @override
  Future<void> write(String key, String value) async {
    final all = await _loadAll();
    all[key] = value;
    await _save(all);
  }

  @override
  Future<void> remove(String key) async {
    final all = await _loadAll();
    all.remove(key);
    await _save(all);
  }
}

/// SharedPreferences-backed storage (used on web and as fallback).
class WebStorage implements KVStorage {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future<SharedPreferences> get _instance => _prefs;

  @override
  Future<String?> read(String key) async =>
      (await _instance).getString(key);

  @override
  Future<void> write(String key, String value) async {
    await (await _instance).setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await (await _instance).remove(key);
  }
}

/// Chooses and initialises the platform storage backend.
Future<KVStorage> createDefaultStorage() async {
  if (kIsWeb) {
    return WebStorage();
  }
  final dir = await getApplicationDocumentsDirectory();
  return FileStorage(directoryPath: dir.path);
}

/// In-memory storage for tests.
class MemoryStorage implements KVStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}