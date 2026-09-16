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
    final screenWidth = MediaQuery.of(context).size.width;
    final boardSize = screenWidth - 48 - 16;

    return Container(
      width: boardSize,
      height: boardSize,
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.gridLine,
          width: 2.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: List.generate(3, (boxRow) {
          return Expanded(
            child: Row(
              children: List.generate(3, (boxCol) {
                return Expanded(
                  child: _buildBox(context, boxRow, boxCol),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBox(BuildContext context, int boxRow, int boxCol) {
    return Column(
      children: List.generate(3, (localRow) {
        return Expanded(
          child: Row(
            children: List.generate(3, (localCol) {
              final row = boxRow * 3 + localRow;
              final col = boxCol * 3 + localCol;
              final cell = board.cells[row][col];

              return SudokuCellWidget(
                cell: cell,
                onTap: () => onCellTap(row, col),
                boxRow: localRow,
                boxCol: localCol,
              );
            }),
          ),
        );
      }),
    );
  }
}
