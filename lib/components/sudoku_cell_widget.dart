import 'package:flutter/material.dart';
import 'package:sudoku_game/models.dart';
import 'package:sudoku_game/theme.dart';

class SudokuCellWidget extends StatelessWidget {
  final SudokuCell cell;
  final VoidCallback onTap;
  final int boxRow;
  final int boxCol;
  final bool isSameNumber;
  final bool isPeer;

  const SudokuCellWidget({
    super.key,
    required this.cell,
    required this.onTap,
    required this.boxRow,
    required this.boxCol,
    this.isSameNumber = false,
    this.isPeer = false,
  });

  @override
  Widget build(BuildContext context) {
    final isRightBoxEdge = boxCol == 2;
    final isBottomBoxEdge = boxRow == 2;
    final bgColor = _backgroundColor(context);
    final txtColor = _textColor(context);
    final fontWeight = cell.isOriginal ? FontWeight.w800 : FontWeight.w600;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              top: BorderSide(
                color: _borderColor(context),
                width: (cell.isSelected || boxRow == 0)
                    ? (cell.isSelected ? 2.4 : 0.8)
                    : 0.6,
              ),
              left: BorderSide(
                color: _borderColor(context),
                width: (cell.isSelected || boxCol == 0)
                    ? (cell.isSelected ? 2.4 : 0.8)
                    : 0.6,
              ),
              right: BorderSide(
                color: _edgeColor(context, isRightBoxEdge),
                width: _edgeWidth(context, isRightBoxEdge),
              ),
              bottom: BorderSide(
                color: _edgeColor(context, isBottomBoxEdge),
                width: _edgeWidth(context, isBottomBoxEdge),
              ),
            ),
          ),
          child: cell.isFilled
              ? FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Text(
                      '${cell.value}',
                      style: TextStyle(
                        fontWeight: fontWeight,
                        color: txtColor,
                      ),
                    ),
                  ),
                )
              : cell.hasNotes
                  ? _buildNotes(cell.notes, context)
                  : null,
        ),
      ),
    );
  }

  Color _backgroundColor(BuildContext context) {
    if (cell.isSelected) return context.accent;
    if (cell.isError) return context.errorSoft;
    if (cell.isHint) return context.hintSoft;
    if (isSameNumber && cell.isFilled) return context.accentSoft;
    if (isPeer) return context.paper;
    return context.surface;
  }

  Color _textColor(BuildContext context) {
    if (cell.isSelected) return AppColors.onAccent;
    if (cell.isError) return context.error;
    if (cell.isHint) return context.hintInk;
    if (cell.isOriginal) return context.ink;
    return context.ink;
  }

  Color _borderColor(BuildContext context) {
    if (cell.isSelected) return context.accent;
    return context.line;
  }

  Color _edgeColor(BuildContext context, bool isBoxEdge) {
    if (cell.isSelected) return context.accent;
    return isBoxEdge ? context.lineStrong : context.line;
  }

  double _edgeWidth(BuildContext context, bool isBoxEdge) {
    if (cell.isSelected) return 2.4;
    return isBoxEdge ? 1.8 : 0.6;
  }

  Widget _buildNotes(Set<int> notes, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(1.5),
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(9, (i) {
          final num = i + 1;
          if (notes.contains(num)) {
            return Center(
              child: FittedBox(
                child: Text(
                  '$num',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: context.inkMuted,
                  ),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ),
    );
  }
}