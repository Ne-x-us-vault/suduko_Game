import 'package:flutter/material.dart';
import 'package:sudoku_game/models.dart';
import 'package:sudoku_game/theme.dart';

class SudokuCellWidget extends StatelessWidget {
  final SudokuCell cell;
  final VoidCallback onTap;
  final int boxRow;
  final int boxCol;

  const SudokuCellWidget({
    super.key,
    required this.cell,
    required this.onTap,
    required this.boxRow,
    required this.boxCol,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final cellSize = (screenWidth - 48 - 16) / 9;

    Color backgroundColor;
    Color borderColor;
    Color textColor;
    FontWeight fontWeight = FontWeight.w400;
    double fontSize = cellSize * 0.5;

    if (cell.isSelected) {
      backgroundColor = AppColors.teal.withValues(alpha: 0.15);
    } else if (cell.isError) {
      backgroundColor = AppColors.errorBackground;
    } else if (cell.isHint) {
      backgroundColor = AppColors.gold.withValues(alpha: 0.15);
    } else {
      backgroundColor = isDark
          ? AppColors.graphite.withValues(alpha: 0.5)
          : AppColors.cellSurface;
    }

    if (cell.isSelected) {
      borderColor = AppColors.teal;
    } else if (cell.isError) {
      borderColor = AppColors.coral;
    } else {
      borderColor = Colors.transparent;
    }

    if (cell.isOriginal) {
      textColor = isDark ? AppColors.ivory : AppColors.graphite;
      fontWeight = FontWeight.w700;
    } else if (cell.isHint) {
      textColor = AppColors.gold;
      fontWeight = FontWeight.w500;
    } else if (cell.isError) {
      textColor = AppColors.errorText;
    } else {
      textColor = isDark
          ? AppColors.ivory.withValues(alpha: 0.8)
          : AppColors.graphite.withValues(alpha: 0.7);
      fontWeight = FontWeight.w400;
    }

    final isRightBoxEdge = boxCol == 2;
    final isBottomBoxEdge = boxRow == 2;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: cellSize,
        height: cellSize,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            top: BorderSide(
              color: borderColor,
              width: cell.isSelected ? 2.0 : 0.5,
            ),
            left: BorderSide(
              color: borderColor,
              width: cell.isSelected ? 2.0 : 0.5,
            ),
            right: BorderSide(
              color: isRightBoxEdge
                  ? AppColors.gridLine
                  : borderColor,
              width: isRightBoxEdge
                  ? 2.0
                  : (cell.isSelected ? 2.0 : 0.5),
            ),
            bottom: BorderSide(
              color: isBottomBoxEdge
                  ? AppColors.gridLine
                  : borderColor,
              width: isBottomBoxEdge
                  ? 2.0
                  : (cell.isSelected ? 2.0 : 0.5),
            ),
          ),
        ),
        child: cell.isFilled
            ? Center(
                child: Text(
                  '${cell.value}',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                    color: textColor,
                  ),
                ),
              )
            : cell.hasNotes
                ? _buildNotes(cell.notes, cellSize, isDark)
                : null,
      ),
    );
  }

  Widget _buildNotes(Set<int> notes, double cellSize, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(1.5),
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(9, (i) {
          final num = i + 1;
          if (notes.contains(num)) {
            return Center(
              child: Text(
                '$num',
                style: TextStyle(
                  fontSize: cellSize * 0.2,
                  fontWeight: FontWeight.w400,
                  color: isDark
                      ? AppColors.ivory.withValues(alpha: 0.6)
                      : AppColors.graphite.withValues(alpha: 0.5),
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
