/// Deterministic pseudo-random number generator (xorshift32).
///
/// Used for all puzzle generation so that the same `board size + seed +
/// generatorVersion + generation configuration` always yields the same puzzle
/// on every platform and every Dart version.
///
/// xorshift32 uses only 32-bit shift/xor/and operations, which are bit-exact
/// on both the Dart VM and dart2js/dart2wasm, unlike `dart:math` `Random`
/// (not guaranteed stable across releases) or algorithms requiring 64-bit
/// multiplication (which loses precision in JS).
library;

class SeededRandom {
  int _state;

  SeededRandom(int seed) : _state = _seedState(seed);

  /// Create from an explicit internal state (for reproducible chains).
  SeededRandom.withState(int state) : _state = state & 0xFFFFFFFF;

  static int _seedState(int seed) {
    var x = seed & 0xFFFFFFFF;
    if (x == 0) x = 0x6D2B79F5;
    // Avalanche the seed.
    x ^= x << 13;
    x &= 0xFFFFFFFF;
    x ^= x >> 17;
    x ^= x << 5;
    x &= 0xFFFFFFFF;
    if (x == 0) x = 0x6D2B79F5;
    return x;
  }

  int _step() {
    var x = _state;
    x ^= x << 13;
    x &= 0xFFFFFFFF;
    x ^= x >> 17;
    x ^= x << 5;
    x &= 0xFFFFFFFF;
    _state = x;
    return x;
  }

  /// Uniform int in [0, max) (exclusive). [max] must be > 0.
  int nextInt(int max) {
    if (max <= 0) return 0;
    if (max == 1) return 0;
    return _step() % max;
  }

  /// Uniform double in [0, 1).
  double nextDouble() => _step() / 4294967296.0;

  /// Shuffles [list] deterministically in place.
  void shuffle<E>(List<E> list) {
    for (int i = list.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }

  /// Picks one item deterministically.
  E pick<E>(List<E> items) => items[nextInt(items.length)];

  /// Current internal state.
  int get state => _state;
}

/// Deterministic 32-bit string hash using xorshift-style avalanche.
/// Bit-exact across platforms (no multiplication, safe for JS).
int fnv1a(String input) {
  var hash = 0x811C9DC5;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash ^= hash << 13;
    hash &= 0xFFFFFFFF;
    hash ^= hash >> 17;
    hash ^= hash << 5;
    hash &= 0xFFFFFFFF;
  }
  return hash;
}