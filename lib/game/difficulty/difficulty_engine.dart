import '../model/puzzle.dart';
import '../solver/queens_solver.dart';

class DifficultyEngine {
  static Difficulty calculateDifficulty(Puzzle puzzle) {
    // Computational difficulty = time to solve or recursion depth
    // Human difficulty = logic required
    // For now, we use a heuristic based on size and solver iterations
    
    if (puzzle.size <= 6) return Difficulty.easy;
    if (puzzle.size <= 8) return Difficulty.medium;
    if (puzzle.size <= 9) return Difficulty.hard;
    return Difficulty.expert;
  }
}
