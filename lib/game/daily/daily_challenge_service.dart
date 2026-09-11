import 'dart:math';
import 'package:intl/intl.dart';
import '../model/puzzle.dart';
import '../generator/puzzle_generator.dart';

class DailyChallengeService {
  static int getDailySeed() {
    String dateString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    // Simple hash of date string to seed
    int seed = 0;
    for (int i = 0; i < dateString.length; i++) {
      seed += dateString.codeUnitAt(i) * (i + 1);
    }
    return seed;
  }

  static Puzzle getDailyPuzzle(int size, Difficulty difficulty) {
    final gen = PuzzleGenerator(getDailySeed());
    return gen.generate(size, difficulty);
  }
}
