import 'dart:async';

class GameTimer {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  final Function(Duration) onTick;

  GameTimer({required this.onTick});

  void start() {
    _stopwatch.start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsed = _stopwatch.elapsed;
      onTick(_elapsed);
    });
  }

  void pause() {
    _stopwatch.stop();
    _ticker?.cancel();
  }

  void resume() {
    _stopwatch.start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsed = _stopwatch.elapsed;
      onTick(_elapsed);
    });
  }

  void stop() {
    pause();
    _stopwatch.reset();
  }

  Duration get elapsed => _stopwatch.elapsed;
  
  String get formattedTime {
    final minutes = _elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
