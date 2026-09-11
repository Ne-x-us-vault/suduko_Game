import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/game_board.dart';
import '../../state/game_state.dart';
import '../../generator/puzzle_generator.dart';
import '../../model/puzzle.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gen = PuzzleGenerator();
      final puzzle = gen.generate(6, Difficulty.easy);
      ref.read(gameStateProvider.notifier).startNewGame(puzzle);
    });
  }

  void _showWinDialog() {
    final gameState = ref.read(gameStateProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Puzzle Solved!'),
        content: Text('Time: ${gameState?.elapsed.inSeconds ~/ 60}:${(gameState?.elapsed.inSeconds % 60).toString().padLeft(2, '0')}\nMistakes: ${gameState?.mistakes}'),
        actions: [
          TextButton(onPressed: () {
            Navigator.pop(ctx);
            context.pop();
          }, child: const Text('Finish')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);

    if (gameState != null && gameState.isSolved) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showWinDialog());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('QUEENS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final gen = PuzzleGenerator();
              ref.read(gameStateProvider.notifier).startNewGame(gen.generate(6, Difficulty.easy));
            },
          ),
        ],
      ),
      body: gameState == null 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatChip(label: 'Mistakes', value: gameState.mistakes.toString()),
                    _StatChip(label: 'Hints', value: gameState.hintsUsed.toString()),
                    _StatChip(label: 'Time', value: '${gameState.elapsed.inMinutes.toString().padLeft(2, '0')}:${(gameState.elapsed.inSeconds % 60).toString().padLeft(2, '0')}'),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GameBoard(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ActionBtn(icon: Icons.undo, onPressed: () {
                      ref.read(gameStateProvider.notifier).undo();
                    }),
                    _ActionBtn(icon: Icons.lightbulb, onPressed: () {
                      ref.read(gameStateProvider.notifier).getHint();
                    }),
                    _ActionBtn(icon: Icons.redo, onPressed: () {}),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _ActionBtn({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      onPressed: onPressed,
      child: Icon(icon),
    );
  }
}
