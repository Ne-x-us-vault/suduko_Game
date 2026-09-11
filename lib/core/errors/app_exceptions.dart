/// Domain and infrastructure exceptions for the QUEENS game.
library;

/// Thrown when the puzzle generator fails to produce a valid, uniquely
/// solvable puzzle within its configured limits.
class PuzzleGenerationException implements Exception {
  final int size;
  final int seed;
  final int attempts;
  final String? reason;

  const PuzzleGenerationException({
    required this.size,
    required this.seed,
    required this.attempts,
    this.reason,
  });

  @override
  String toString() =>
      'PuzzleGenerationException(size=$size, seed=$seed, attempts=$attempts${reason == null ? '' : ', reason=$reason'})';
}

/// Thrown when a puzzle fails validation.
class InvalidPuzzleException implements Exception {
  final String message;
  const InvalidPuzzleException(this.message);

  @override
  String toString() => 'InvalidPuzzleException($message)';
}

/// Thrown when local persisted data cannot be read or is structurally
/// invalid. Callers are expected to recover gracefully.
class PersistenceException implements Exception {
  final String message;
  const PersistenceException(this.message);

  @override
  String toString() => 'PersistenceException($message)';
}