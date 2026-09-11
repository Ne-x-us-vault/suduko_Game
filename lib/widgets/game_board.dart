import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/model/position.dart';
import '../game/model/puzzle.dart';
import '../state/game_controller.dart';
import '../state/game_state.dart';
import '../themes/app_theme.dart';

/// Interactive queen-placement board.
///
/// Painted with a single CustomPaint for performance (one painter, no
/// per-cell widgets during paint). Per-cell taps and semantics are provided
/// by a lightweight gesture/semantics layer on top.
class GameBoard extends ConsumerStatefulWidget {
  final BoardColors colors;

  /// Invoked when a placement was rejected because strict mode forbids it.
  final VoidCallback? onInvalidPlacement;

  const GameBoard({
    super.key,
    required this.colors,
    this.onInvalidPlacement,
  });

  @override
  ConsumerState<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends ConsumerState<GameBoard> {
  Position? _selected;

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameStateProvider);
    if (game == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final puzzle = game.puzzle;

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cell = constraints.maxWidth / puzzle.size;
          return RepaintBoundary(
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: BoardPainter(
                      puzzle: puzzle,
                      queens: game.queens,
                      marks: game.allMarks,
                      autoMarks: game.autoMarks,
                      manualMarks: game.manualMarks,
                      selected: _selected,
                      conflicts: game.conflictHighlight,
                      hintCells:
                          game.activeHint?.affectedCells ?? const [],
                      solved: game.isSolved,
                      colors: widget.colors,
                      cellSize: cell,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Stack(
                    children: [
                      for (int r = 0; r < puzzle.size; r++)
                        for (int c = 0; c < puzzle.size; c++)
                          _CellInput(
                            key: ValueKey('cell_${r}_$c'),
                            left: c * cell,
                            top: r * cell,
                            size: cell,
                            label: _semanticLabel(game, r, c),
                            onTap: () => _place(game, r, c),
                            onLongPress: () => _mark(game, r, c),
                            onSecondaryTap: () => _mark(game, r, c),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _place(GameState game, int r, int c) {
    if (game.isSolved) return;
    setState(() => _selected = Position(r, c));
    final result =
        ref.read(gameStateProvider.notifier).placeQueen(Position(r, c));
    if (result == PlacementResult.rejectedStrict) {
      widget.onInvalidPlacement?.call();
    }
  }

  void _mark(GameState game, int r, int c) {
    if (game.isSolved) return;
    setState(() => _selected = Position(r, c));
    ref.read(gameStateProvider.notifier).toggleCandidate(Position(r, c));
  }

  String _semanticLabel(GameState game, int r, int c) {
    final region = game.puzzle.regionMap[r][c] + 1;
    final pos = Position(r, c);
    final String status;
    if (game.hasQueen(pos)) {
      status = 'queen';
    } else if (game.isManualMarked(pos) || game.autoMarks.contains(pos)) {
      status = 'candidate';
    } else {
      status = 'empty';
    }
    return 'Row ${r + 1}, Column ${c + 1}, Region $region, $status';
  }
}

class _CellInput extends StatelessWidget {
  final double left;
  final double top;
  final double size;
  final String label;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onSecondaryTap;

  const _CellInput({
    super.key,
    required this.left,
    required this.top,
    required this.size,
    required this.label,
    required this.onTap,
    required this.onLongPress,
    required this.onSecondaryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      width: size,
      height: size,
      child: Semantics(
        label: label,
        button: false,
        onTap: onTap,
        onLongPress: onLongPress,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onLongPress: onLongPress,
          onSecondaryTap: onSecondaryTap,
        ),
      ),
    );
  }
}

class BoardPainter extends CustomPainter {
  final Puzzle puzzle;
  final List<Position> queens;
  final Set<Position> marks;
  final Set<Position> autoMarks;
  final Set<Position> manualMarks;
  final Position? selected;
  final Set<Position> conflicts;
  final List<Position> hintCells;
  final bool solved;
  final BoardColors colors;
  final double cellSize;

  BoardPainter({
    required this.puzzle,
    required this.queens,
    required this.marks,
    required this.autoMarks,
    required this.manualMarks,
    required this.selected,
    required this.conflicts,
    required this.hintCells,
    required this.solved,
    required this.colors,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = puzzle.size;

    // ---- Region fills ----
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final rid = puzzle.regionMap[r][c];
        final fill = colors.regionFills[rid % colors.regionFills.length];
        final rect = Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize);
        canvas.drawRect(rect, Paint()..color = fill);
      }
    }

    // ---- Highlight states (under content) ----
    final highlightPaint = Paint();
    if (solved) {
      highlightPaint.color = colors.completed;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), highlightPaint);
    }
    for (final p in hintCells) {
      highlightPaint.color = colors.hintHighlight;
      canvas.drawRect(
          Rect.fromLTWH(p.col * cellSize, p.row * cellSize, cellSize, cellSize),
          highlightPaint);
    }
    if (selected != null && !solved) {
      highlightPaint.color = colors.selected;
      canvas.drawRect(
          Rect.fromLTWH(selected!.col * cellSize, selected!.row * cellSize,
              cellSize, cellSize),
          highlightPaint);
    }
    for (final p in conflicts) {
      highlightPaint.color = colors.conflict;
      canvas.drawRect(
          Rect.fromLTWH(p.col * cellSize, p.row * cellSize, cellSize, cellSize),
          highlightPaint);
    }

    // ---- Region boundaries ----
    _drawRegionBoundaries(canvas, n);

    // ---- Inner cell grid (subtle) ----
    final gridPaint = Paint()
      ..color = colors.cellStroke
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (int r = 1; r < n; r++) {
      canvas.drawLine(Offset(0, r * cellSize), Offset(size.width, r * cellSize), gridPaint);
    }
    for (int c = 1; c < n; c++) {
      canvas.drawLine(Offset(c * cellSize, 0), Offset(c * cellSize, size.height), gridPaint);
    }

    // ---- Board outer border ----
    final outerPaint = Paint()
      ..color = colors.boardStroke
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), outerPaint);

    // ---- X marks ----
    for (final p in marks) {
      final isAuto = autoMarks.contains(p);
      _drawX(canvas, p, isAuto ? colors.mark.withValues(alpha: 0.5) : colors.mark);
    }

    // ---- Queens ----
    for (final p in queens) {
      _drawQueen(canvas, p);
    }
  }

  void _drawRegionBoundaries(Canvas canvas, int n) {
    // At each cell, if the cell right/down changes region, draw a heavy
    // boundary. Color comes from the region's stroke color for clarify.
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final rid = puzzle.regionMap[r][c];
        final stroke = colors.regionStrokes[rid % colors.regionStrokes.length];

        // Right edge
        if (c < n - 1 && puzzle.regionMap[r][c + 1] != rid) {
          final paint = Paint()
            ..color = stroke
            ..strokeWidth = 2.2
            ..style = PaintingStyle.stroke;
          canvas.drawLine(
            Offset((c + 1) * cellSize, r * cellSize),
            Offset((c + 1) * cellSize, (r + 1) * cellSize),
            paint,
          );
        }
        // Bottom edge
        if (r < n - 1 && puzzle.regionMap[r + 1][c] != rid) {
          final paint = Paint()
            ..color = stroke
            ..strokeWidth = 2.2
            ..style = PaintingStyle.stroke;
          canvas.drawLine(
            Offset(c * cellSize, (r + 1) * cellSize),
            Offset((c + 1) * cellSize, (r + 1) * cellSize),
            paint,
          );
        }
      }
    }
  }

  void _drawX(Canvas canvas, Position p, Color color) {
    final d = cellSize * 0.18;
    final center = cellSize / 2;
    final x = p.col * cellSize;
    final y = p.row * cellSize;
    final paint = Paint()
      ..color = color
      ..strokeWidth = math.max(1.6, cellSize * 0.07)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(x + center - d, y + center - d), Offset(x + center + d, y + center + d), paint);
    canvas.drawLine(
        Offset(x + center + d, y + center - d), Offset(x + center - d, y + center + d), paint);
  }

  void _drawQueen(Canvas canvas, Position p) {
    final x = p.col * cellSize;
    final y = p.row * cellSize;
    final c = Offset(x + cellSize / 2, y + cellSize / 2);
    final radius = cellSize * 0.34;
    final paint = Paint()..color = colors.queen;

    // Crown: three peaks on a base band, sitting on the cell center.
    final w = radius * 1.5;
    final h = radius * 1.25;
    final topLeftY = c.dy - h * 0.55;
    final baseY = c.dy + h * 0.55;
    final path = Path()
      ..moveTo(c.dx - w, baseY)
      ..lineTo(c.dx - w, topLeftY + h * 0.35)
      ..lineTo(c.dx - w * 0.55, topLeftY)
      ..lineTo(c.dx - w * 0.20, topLeftY + h * 0.45)
      ..lineTo(c.dx, topLeftY)
      ..lineTo(c.dx + w * 0.20, topLeftY + h * 0.45)
      ..lineTo(c.dx + w * 0.55, topLeftY)
      ..lineTo(c.dx + w, topLeftY + h * 0.35)
      ..lineTo(c.dx + w, baseY)
      ..close();
    canvas.drawPath(path, paint);
    // Band on the crown.
    final bandPaint = Paint()
      ..color = colors.queen.withValues(alpha: 0.9)
      ..strokeWidth = math.max(1.2, cellSize * 0.05)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(c.dx - w, baseY), Offset(c.dx + w, baseY), bandPaint);
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) =>
      old.puzzle != puzzle ||
      old.queens != queens ||
      old.marks != marks ||
      old.selected != selected ||
      old.conflicts != conflicts ||
      old.hintCells != hintCells ||
      old.solved != solved ||
      old.colors != colors ||
      old.cellSize != cellSize;
}