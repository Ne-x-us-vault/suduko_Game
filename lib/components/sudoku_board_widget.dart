import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sudoku_game/models.dart';
import 'package:sudoku_game/components/sudoku_cell_widget.dart';
import 'package:sudoku_game/theme.dart';

class SudokuBoardWidget extends StatelessWidget {
  final SudokuBoard board;
  final ValueChanged<(int, int)> onCellTap;

  const SudokuBoardWidget({
    super.key,
    required this.board,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    final (selectedRow, selectedCol, selectedValue) = _selectedInfo();

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = math.min(constraints.maxWidth, constraints.maxHeight);
        return SizedBox(
          width: boardSize,
          height: boardSize,
          child: Container(
            width: boardSize,
            height: boardSize,
            decoration: BoxDecoration(
              color: context.surface,
              border: Border.all(color: context.lineStrong, width: 2),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Column(
                children: List.generate(3, (boxRow) {
                  return Expanded(
                    child: Row(
                      children: List.generate(3, (boxCol) {
                        return Expanded(
                          child: _buildBox(
                            context,
                            boxRow,
                            boxCol,
                            selectedRow,
                            selectedCol,
                            selectedValue,
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  (int, int, int) _selectedInfo() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (board.cells[r][c].isSelected) {
          return (r, c, board.cells[r][c].value);
        }
      }
    }
    return (-1, -1, 0);
  }

  Widget _buildBox(
    BuildContext context,
    int boxRow,
    int boxCol,
    int selectedRow,
    int selectedCol,
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
                  (row == selectedRow ||
                      col == selectedCol ||
                      thisBox == (selectedRow ~/ 3) * 3 + (selectedCol ~/ 3));
              final isSameNumber = selectedValue > 0 &&
                  cell.value == selectedValue &&
                  !cell.isSelected;

              if (cell.isSelected) {
                return SudokuCellWidget(
                  cell: cell,
                  onTap: () => onCellTap((row, col)),
                  boxRow: localRow,
                  boxCol: localCol,
                );
              }
              return SudokuCellWidget(
                cell: cell,
                onTap: () => onCellTap((row, col)),
                boxRow: localRow,
                boxCol: localCol,
                isPeer: isPeer,
                isSameNumber: isSameNumber,
              );
            }),
          ),
        );
      }),
    );
  }
}