import 'package:flutter/material.dart';
import 'package:sudoku_game/theme.dart';

class NumberPad extends StatelessWidget {
  final Function(int number) onNumberTap;
  final VoidCallback onErase;
  final VoidCallback onUndo;
  final VoidCallback onNotesToggle;
  final bool notesMode;
  final Map<int, int> numberCounts;

  const NumberPad({
    super.key,
    required this.onNumberTap,
    required this.onErase,
    required this.onUndo,
    required this.onNotesToggle,
    required this.notesMode,
    required this.numberCounts,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          children: List.generate(9, (i) {
            final num = i + 1;
            final count = numberCounts[num] ?? 9;
            final isComplete = count == 0;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: GestureDetector(
                  onTap: isComplete ? null : () => onNumberTap(num),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isComplete
                          ? Colors.transparent
                          : (isDark
                              ? AppColors.graphite.withValues(alpha: 0.8)
                              : AppColors.cellSurface),
                      borderRadius: BorderRadius.circular(8),
                      border: isComplete
                          ? null
                          : Border.all(
                              color: AppColors.gridLine.withValues(alpha: 0.5),
                              width: 1,
                            ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$num',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: isComplete
                                ? Colors.transparent
                                : (isDark ? AppColors.ivory : AppColors.graphite),
                          ),
                        ),
                        if (!isComplete)
                          Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 8,
                              color: (isDark
                                      ? AppColors.ivory
                                      : AppColors.graphite)
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.delete_outline,
                label: 'Erase',
                onTap: onErase,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.edit_note,
                label: 'Notes',
                onTap: onNotesToggle,
                isActive: notesMode,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.undo,
                label: 'Undo',
                onTap: onUndo,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.teal.withValues(alpha: 0.15)
              : (isDark
                  ? AppColors.graphite.withValues(alpha: 0.5)
                  : AppColors.cellSurface),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? AppColors.teal
                : AppColors.gridLine.withValues(alpha: 0.5),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? AppColors.teal
                  : (isDark ? AppColors.ivory : AppColors.graphite),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive
                    ? AppColors.teal
                    : (isDark
                        ? AppColors.ivory.withValues(alpha: 0.6)
                        : AppColors.graphite.withValues(alpha: 0.6)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
