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
      return isDark ? AppColors.white : AppColors.black;
    }
    if (cell.isError) {
      return isDark ? AppColors.grey800 : AppColors.grey200;
    }
    if (cell.isHint) return isDark ? AppColors.grey700 : AppColors.grey100;
    if (isSameNumber && cell.isFilled) {
      return isDark ? AppColors.grey900 : AppColors.grey100;
    }
    if (isPeer) {
      return isDark ? AppColors.grey800 : AppColors.grey100;
    }
    if (cell.isOriginal) {
      return isDark ? AppColors.grey900 : AppColors.cellOriginal;
    }
    return isDark ? AppColors.black : AppColors.cellUser;
  }

  Color _textColor(bool isDark) {
    if (cell.isSelected) {
      return isDark ? AppColors.black : AppColors.white;
    }
    if (cell.isOriginal) {
      return isDark ? AppColors.white : AppColors.black;
    }
    if (cell.isHint) return isDark ? AppColors.grey400 : AppColors.grey600;
    if (cell.isError) return isDark ? AppColors.grey400 : AppColors.grey600;
    if (isSameNumber && cell.isFilled) {
      return isDark ? AppColors.white : AppColors.black;
    }
    return isDark ? AppColors.grey300 : AppColors.grey700;
  }

  Color _topBorderColor(bool isDark) {
    if (cell.isSelected) return isDark ? AppColors.white : AppColors.black;
    return isDark ? AppColors.grey800 : AppColors.gridThin;
  }

  double get _topBorderWidth => cell.isSelected ? 2.0 : 0.5;

  Color _leftBorderColor(bool isDark) {
    if (cell.isSelected) return isDark ? AppColors.white : AppColors.black;
    return isDark ? AppColors.grey800 : AppColors.gridThin;
  }

  double get _leftBorderWidth => cell.isSelected ? 2.0 : 0.5;

  Color _rightBorderColor(bool isDark, bool isBoxEdge) {
    if (cell.isSelected) return isDark ? AppColors.white : AppColors.black;
    if (isBoxEdge) {
      return isDark ? AppColors.grey700 : AppColors.gridThick;
    }
    return isDark ? AppColors.grey800 : AppColors.gridThin;
  }

  double _rightBorderWidth(bool isBoxEdge) {
    if (cell.isSelected) return 2.0;
    return isBoxEdge ? 2.0 : 0.5;
  }

  Color _bottomBorderColor(bool isDark, bool isBoxEdge) {
    if (cell.isSelected) return isDark ? AppColors.white : AppColors.black;
    if (isBoxEdge) {
      return isDark ? AppColors.grey700 : AppColors.gridThick;
    }
    return isDark ? AppColors.grey800 : AppColors.gridThin;
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
