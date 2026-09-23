import 'package:flutter/material.dart';
import 'package:sudoku_game/theme.dart';

class NumberPad extends StatelessWidget {
  final ValueChanged<int> onNumberTap;
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
    return Column(
      children: [
        Row(
          children: List.generate(9, (i) {
            final num = i + 1;
            final count = numberCounts[num] ?? 9;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: _NumberKey(
                  number: num,
                  remaining: count,
                  onTap: () => onNumberTap(num),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildAction(
                context,
                icon: Icons.backspace_outlined,
                label: 'Erase',
                onTap: onErase,
                isActive: false,
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isActive ? context.accent : context.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? context.accent : context.line,
            width: 1.2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: context.accent.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? AppColors.onAccent : context.inkMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive ? AppColors.onAccent : context.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberKey extends StatelessWidget {
  final int number;
  final int remaining;
  final VoidCallback onTap;

  const _NumberKey({
    required this.number,
    required this.remaining,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final complete = remaining == 0;

    return GestureDetector(
      onTap: complete ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 54,
        decoration: BoxDecoration(
          color: complete ? Colors.transparent : context.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: complete
                ? Colors.transparent
                : context.line.withValues(alpha: 0.85),
            width: 1.2,
          ),
          boxShadow: complete
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$number',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: complete
                    ? context.inkMuted.withValues(alpha: 0.35)
                    : context.ink,
              ),
            ),
            SizedBox(
              height: 13,
              child: complete
                  ? Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: context.inkMuted.withValues(alpha: 0.5),
                    )
                  : Text(
                      '$remaining',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: remaining <= 2
                            ? context.error
                            : context.inkMuted,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}