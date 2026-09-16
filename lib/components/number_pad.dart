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
        // Number row
        Row(
          children: List.generate(9, (i) {
            final num = i + 1;
            final count = numberCounts[num] ?? 9;
            final isComplete = count == 0;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: GestureDetector(
                  onTap: isComplete ? null : () => onNumberTap(num),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 52,
                    decoration: BoxDecoration(
                      color: isComplete
                          ? Colors.transparent
                          : (isDark
                              ? const Color(0xFF252830)
                              : AppColors.paper),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isComplete
                            ? Colors.transparent
                            : (isDark
                                ? const Color(0xFF2D3040)
                                : AppColors.gridThin),
                        width: 1,
                      ),
                      boxShadow: isComplete
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: isDark ? 0.2 : 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$num',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: isComplete
                                ? Colors.transparent
                                : (isDark
                                    ? const Color(0xFFE5E7EB)
                                    : AppColors.ink),
                          ),
                        ),
                        if (!isComplete)
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.slate
                                    : AppColors.muted,
                              ),
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
        const SizedBox(height: 10),
        // Action row
        Row(
          children: [
            Expanded(
              child: _buildAction(
                context,
                icon: Icons.delete_outline_rounded,
                label: 'Erase',
                onTap: onErase,
                isActive: false,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAction(
                context,
                icon: Icons.edit_note_rounded,
                label: 'Notes',
                onTap: onNotesToggle,
                isActive: notesMode,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAction(
                context,
                icon: Icons.undo_rounded,
                label: 'Undo',
                onTap: onUndo,
                isActive: false,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isActive,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.teal.withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF252830) : AppColors.paper),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppColors.teal.withValues(alpha: 0.5)
                : (isDark ? const Color(0xFF2D3040) : AppColors.gridThin),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? AppColors.teal
                  : (isDark ? const Color(0xFF9CA3AF) : AppColors.slate),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? AppColors.teal
                    : (isDark ? AppColors.slate : AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
