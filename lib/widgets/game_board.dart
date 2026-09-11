import 'package:flutter/material.dart';
import '../model/position.dart';
import '../model/puzzle.dart';
import '../state/game_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../validation/constraint_engine.dart';

class GameBoard extends ConsumerWidget {
  const GameBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) return const Center(child: CircularProgressIndicator());

    final puzzle = gameState.puzzle;
    final placements = gameState.queenPlacements;
    final candidates = gameState.candidateMarks;

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          double cellSize = constraints.maxWidth / puzzle.size;
          return CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxWidth),
            painter: BoardPainter(
              puzzle: puzzle,
              placements: placements,
              candidates: candidates,
              cellSize: cellSize,
            ),
            child: GestureDetector(
              onTapDown: (details) {
                double localX = details.localPosition.dx;
                double localY = details.localPosition.dy;
                int col = (localX / cellSize).floor();
                int row = (localY / cellSize).floor();
                if (row >= 0 && row < puzzle.size && col >= 0 && col < puzzle.size) {
                  ref.read(gameStateProvider.notifier).placeQueen(Position(row, col));
                }
              },
              onLongPressStart: (details) {
                double localX = details.localPosition.dx;
                double localY = details.localPosition.dy;
                int col = (localX / cellSize).floor();
                int row = (localY / cellSize).floor();
                if (row >= 0 && row < puzzle.size && col >= 0 && col < puzzle.size) {
                  ref.read(gameStateProvider.notifier).toggleCandidate(Position(row, col));
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class BoardPainter extends CustomPainter {
  final Puzzle puzzle;
  final List<Position> placements;
  final Set<Position> candidates;
  final double cellSize;

  BoardPainter({required this.puzzle, required this.placements, required this.candidates, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.black;

    for (int i = 0; i <= puzzle.size; i++) {
      canvas.drawLine(Offset(i * cellSize, 0), Offset(i * cellSize, size.height), paint);
      canvas.drawLine(Offset(0, i * cellSize), Offset(size.width, i * cellSize), paint);
    }

    for (int r = 0; r < puzzle.size; r++) {
      for (int c = 0; c < puzzle.size; c++) {
        final regionId = puzzle.regionMap[r][c];
        final regionPaint = Paint()
          ..color = Colors.primaries[regionId % Colors.primaries.length].withOpacity(0.2)
          ..style = PaintingStyle.fill;
        canvas.drawRect(Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize), regionPaint);
      }
    }

    final queenPaint = Paint()..color = Colors.black;
    for (var pos in placements) {
      canvas.drawCircle(
        Offset(pos.col * cellSize + cellSize / 2, pos.row * cellSize + cellSize / 2),
        cellSize * 0.3,
        queenPaint,
      );
    }

    final xPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (var pos in candidates) {
      double offset = cellSize * 0.2;
      double center = cellSize / 2;
      canvas.drawLine(Offset(pos.col * cellSize + offset, pos.row * cellSize + offset), 
                     Offset((pos.col + 1) * cellSize - offset, (pos.row + 1) * cellSize - offset), xPaint);
      canvas.drawLine(Offset((pos.col + 1) * cellSize - offset, pos.row * cellSize + offset), 
                     Offset(pos.col * cellSize + offset, (pos.row + 1) * cellSize - offset), xPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
