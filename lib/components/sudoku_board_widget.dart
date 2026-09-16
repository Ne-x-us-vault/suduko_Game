import 'package:flutter/material.dart';
import 'package:sudoku_game/models.dart';
import 'package:sudoku_game/components/sudoku_cell_widget.dart';
import 'package:sudoku_game/theme.dart';

class SudokuBoardWidget extends StatelessWidget {
  final SudokuBoard board;
  final Function(int row, int col) onCellTap;

  const SudokuBoardWidget({
    super.key,
    required this.board,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Find selected cell info
    int selectedRow = -1;
    int selectedCol = -1;
    int selectedValue = 0;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (board.cells[r][c].isSelected) {
          selectedRow = r;
          selectedCol = c;
          selectedValue = board.cells[r][c].value;
        }
      }
    }

    final selectedBox = selectedRow >= 0 ? (selectedRow ~/ 3) * 3 + (selectedCol ~/ 3) : -1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.maxWidth;
        return Container(
          width: boardSize,
          height: boardSize,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1D26) : AppColors.paper,
            border: Border.all(
              color: isDark ? const Color(0xFF3D4255) : AppColors.gridThick,
              width: 3.0,
            ),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Column(
              children: List.generate(3, (boxRow) {
                return Expanded(
                  child: Row(
                    children: List.generate(3, (boxCol) {
                      return Expanded(
                        child: _buildBox(
                          boxRow,
                          boxCol,
                          selectedRow,
                          selectedCol,
                          selectedBox,
                          selectedValue,
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBox(
    int boxRow,
    int boxCol,
    int selectedRow,
    int selectedCol,
    int selectedBox,
    int selectedValue,
  ) {
    final thisBox = boxRow * 3 + boxCol;

    return Column(
      children: List.generate(3, (localRow) {
        return Expanded(
          child: Row(
            children: List.generate(3, (localCol) {
              final row = boxRow * 3 + localRow;
              final col = boxCol * 3 + localCol;
              final cell = board.cells[row][col];

              final isPeer = selectedRow >= 0 &&
                  (row == selectedRow || col == selectedCol || thisBox == selectedBox);
              final isSameNumber = selectedValue > 0 &&
                  cell.value == selectedValue &&
                  !cell.isSelected;

              return SudokuCellWidget(
                cell: cell,
                onTap: () => onCellTap(row, col),
                boxRow: localRow,
                boxCol: localCol,
                isPeer: isPeer && !cell.isSelected,
                isSameNumber: isSameNumber,
              );
            }),
          ),
        );
      }),
    );
  }
}
