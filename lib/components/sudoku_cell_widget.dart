import 'package:flutter/material.dart';
import 'package:sudoku_game/models.dart';
import 'package:sudoku_game/theme.dart';

class SudokuCellWidget extends StatelessWidget {
  final SudokuCell cell;
  final VoidCallback onTap;
  final int boxRow;
  final int boxCol;
  final bool isSameRow;
  final bool isSameCol;
  final bool isSameBox;
  final bool isSameNumber;
  final bool isPeer;

  const SudokuCellWidget({
    super.key,
    required this.cell,
    required this.onTap,
    required this.boxRow,
    required this.boxCol,
    this.isSameRow = false,
    this.isSameCol = false,
    this.isSameBox = false,
    this.isSameNumber = false,
    this.isPeer = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = _backgroundColor(isDark);
    final txtColor = _textColor(isDark);
    final fontWeight = cell.isOriginal ? FontWeight.w700 : FontWeight.w500;

    final isRightBoxEdge = boxCol == 2;
    final isBottomBoxEdge = boxRow == 2;

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
                color: _topBorderColor(isDark),
                width: _topBorderWidth,
              ),
              left: BorderSide(
                color: _leftBorderColor(isDark),
                width: _leftBorderWidth,
              ),
              right: BorderSide(
                color: _rightBorderColor(isDark, isRightBoxEdge),
                width: _rightBorderWidth(isRightBoxEdge),
              ),
              bottom: BorderSide(
                color: _bottomBorderColor(isDark, isBottomBoxEdge),
                width: _bottomBorderWidth(isBottomBoxEdge),
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
                  ? _buildNotes(cell.notes, isDark)
                  : null,
        ),
      ),
    );
  }

  Color _backgroundColor(bool isDark) {
    if (cell.isSelected) {
      return isDark
          ? AppColors.teal.withValues(alpha: 0.2)
          : AppColors.cellSelected;
    }
    if (cell.isError) {
      return isDark
          ? AppColors.rose.withValues(alpha: 0.12)
          : AppColors.roseSoft;
    }
    if (cell.isHint) return AppColors.cellHint;
    if (isSameNumber && cell.isFilled) {
      return isDark
          ? AppColors.teal.withValues(alpha: 0.08)
          : AppColors.tealSoft.withValues(alpha: 0.5);
    }
    if (isPeer) {
      return isDark
          ? const Color(0xFF22252E)
          : const Color(0xFFF5F6F8);
    }
    if (cell.isOriginal) {
      return isDark ? const Color(0xFF1E2028) : AppColors.cellOriginal;
    }
    return isDark ? const Color(0xFF252830) : AppColors.cellUser;
  }

  Color _textColor(bool isDark) {
    if (cell.isOriginal) {
      return isDark ? const Color(0xFFE5E7EB) : AppColors.ink;
    }
    if (cell.isHint) return AppColors.amber;
    if (cell.isError) return AppColors.rose;
    if (isSameNumber && cell.isFilled) {
      return isDark ? AppColors.teal : AppColors.teal;
    }
    return isDark
        ? AppColors.teal.withValues(alpha: 0.9)
        : AppColors.teal;
  }

  Color _topBorderColor(bool isDark) {
    if (cell.isSelected) return AppColors.teal;
    return isDark ? const Color(0xFF2D3040) : AppColors.gridThin;
  }

  double get _topBorderWidth => cell.isSelected ? 2.0 : 0.5;

  Color _leftBorderColor(bool isDark) {
    if (cell.isSelected) return AppColors.teal;
    return isDark ? const Color(0xFF2D3040) : AppColors.gridThin;
  }

  double get _leftBorderWidth => cell.isSelected ? 2.0 : 0.5;

  Color _rightBorderColor(bool isDark, bool isBoxEdge) {
    if (cell.isSelected) return AppColors.teal;
    if (isBoxEdge) {
      return isDark ? const Color(0xFF3D4255) : AppColors.gridThick;
    }
    return isDark ? const Color(0xFF2D3040) : AppColors.gridThin;
  }

  double _rightBorderWidth(bool isBoxEdge) {
    if (cell.isSelected) return 2.0;
    return isBoxEdge ? 2.0 : 0.5;
  }

  Color _bottomBorderColor(bool isDark, bool isBoxEdge) {
    if (cell.isSelected) return AppColors.teal;
    if (isBoxEdge) {
      return isDark ? const Color(0xFF3D4255) : AppColors.gridThick;
    }
    return isDark ? const Color(0xFF2D3040) : AppColors.gridThin;
  }

  double _bottomBorderWidth(bool isBoxEdge) {
    if (cell.isSelected) return 2.0;
    return isBoxEdge ? 2.0 : 0.5;
  }

  Widget _buildNotes(Set<int> notes, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(1),
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
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.slate : AppColors.muted,
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
