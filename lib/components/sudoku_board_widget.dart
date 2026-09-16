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
                        child: _buildBox(boxRow, boxCol),
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

  Widget _buildBox(int boxRow, int boxCol) {
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
