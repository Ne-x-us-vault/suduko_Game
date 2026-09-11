/// Timestamp-based game timer.
///
/// The elapsed duration is derived from wall-clock timestamps plus an
/// accumulated baseline, never from a running tick counter, so it stays
/// correct across pause/resume and app lifecycle events (backgrounding,
/// process death, etc.).
library;

import 'dart:async';

class GameTimer {
  Duration _accumulated = Duration.zero;
  DateTime? _runStart;
  Timer? _ticker;
  bool _paused = true;
  void Function(Duration elapsed) onTick;

  GameTimer({required this.onTick});

  bool get isRunning => !_paused;

  /// Starts (or restarts) the timer from zero.
  void start() {
    _accumulated = Duration.zero;
    resume();
  }

  void resume() {
    if (!_paused) return;
    _paused = false;
    _runStart = DateTime.now();
    _startTicker();
  }

  void pause() {
    if (_paused) return;
    _accumulated += DateTime.now().difference(_runStart!);
    _runStart = null;
    _paused = true;
    _ticker?.cancel();
    _ticker = null;
    onTick(_accumulated);
  }

  void stop() {
    pause();
    _accumulated = Duration.zero;
  }

  /// Current elapsed, correct regardless of whether the timer is paused.
  Duration get elapsed {
    final base = _accumulated;
    if (!_paused && _runStart != null) {
      return base + DateTime.now().difference(_runStart!);
    }
    return base;
  }

  /// Discard the accumulated baseline (used when restoring from storage);
  /// keeps running if it was running.
  void setElapsed(Duration value) {
    _accumulated = value;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!_paused) {
        onTick(elapsed);
      }
    });
  }

  void dispose() {
    _ticker?.cancel();
    _ticker = null;
  }
}

String formatElapsed(Duration d) {
  final minutes = d.inMinutes.toString().padLeft(2, '0');
  final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
  final hours = d.inHours;
  if (hours > 0) {
    return '$hours:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}