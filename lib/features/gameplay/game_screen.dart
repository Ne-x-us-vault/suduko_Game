import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utilities/date_utils.dart' as du;
import '../../core/utilities/game_timer.dart';
import '../../game/achievements/achievement_service.dart';
import '../../game/model/difficulty.dart';
import '../../game/model/game_mode.dart';
import '../../game/model/puzzle.dart';
import '../../platform/share_service.dart';
import '../../routing/play_config.dart';
import '../../state/app_services.dart';
import '../../state/game_controller.dart';
import '../../state/game_state.dart';
import '../../state/settings_controller.dart';
import '../../themes/app_theme.dart';
import '../../widgets/game_board.dart';

/// Gameplay screen: renders the board, in-game controls, timer, and the
/// completion dialog. Supports Quick Play, Daily Challenge, and session
/// resume.
class GameScreen extends ConsumerStatefulWidget {
  final PlayConfig config;

  const GameScreen({super.key, required this.config});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _busy = true;
  String? _error;
  String? _lastHandledCompletionId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final controller = ref.read(gameStateProvider.notifier);
    final services = ref.read(appServicesProvider);

    // Resume path — an active/recovered session exists.
    if (widget.config.resume) {
      var existing = controller.current;
      if (existing == null && services?.restoredState != null) {
        controller.restoreGame(services!.restoredState!);
        existing = controller.current;
      }
      if (existing != null && !existing.isSolved) {
        if (mounted) setState(() => _busy = false);
        return;
      }
    }

    final settings = ref.read(settingsControllerProvider);
    try {
      final Puzzle puzzle;
      if (widget.config.mode == GameMode.dailyChallenge) {
        puzzle = await services!.generateDailyPuzzle();
      } else {
        puzzle = await services!.generatePuzzle(
          size: widget.config.size ?? 6,
          difficulty: widget.config.difficulty ?? Difficulty.easy,
          mode: widget.config.mode,
        );
      }
      controller.startNewGame(
        puzzle,
        mode: widget.config.mode,
        strict: settings.strictMode,
        showMistakes: settings.showMistakes,
        dailyDate: widget.config.mode == GameMode.dailyChallenge
            ? du.DateUtils.dateKey(DateTime.now())
            : null,
      );
      if (mounted) setState(() => _busy = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _busy = false;
        });
      }
    }
  }

  void _retry() {
    setState(() {
      _busy = true;
      _error = null;
    });
    _initialize();
  }

  Future<void> _confirmAndPop() async {
    final controller = ref.read(gameStateProvider.notifier);
    final game = controller.current;
    final hasProgress =
        game != null && !game.isSolved && (game.queens.isNotEmpty || game.manualMarks.isNotEmpty);
    if (!hasProgress) {
      if (mounted) context.pop();
      return;
    }
    final abandon = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave game?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('KEEP PLAYING'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('LEAVE'),
          ),
        ],
      ),
    );
    if (abandon == true && mounted) {
      controller.clear();
      final svc = ref.read(appServicesProvider);
      await svc?.clearSession();
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameStateProvider);
    final completion = ref.watch(lastCompletionProvider).value;
    final settings = ref.watch(settingsControllerProvider);
    final services = ref.watch(appServicesProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    _maybeShowCompletion(game, completion);

    if (_busy) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.config.mode.label)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: scheme.error),
                const SizedBox(height: 12),
                const Text('Could not generate this puzzle.'),
                const SizedBox(height: 6),
                Text('$_error',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _retry, child: const Text('TRY AGAIN')),
              ],
            ),
          ),
        ),
      );
    }

    final gameState = game; // non-null after successful init
    if (gameState == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDaily = gameState.mode == GameMode.dailyChallenge;
    final title = isDaily
        ? 'Daily Challenge'
        : '${gameState.puzzle.size}×${gameState.puzzle.size} • '
            '${gameState.puzzle.difficulty.label}';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmAndPop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _confirmAndPop),
          title: Text(title),
          actions: [
            IconButton(
              tooltip: 'Restart',
              onPressed: _busy || gameState.isSolved ? null : _confirmRestart,
              icon: const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              tooltip: 'Settings',
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.settings_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  _StatusRow(
                    elapsed: gameState.elapsed,
                    size: gameState.puzzle.size,
                    difficulty: gameState.puzzle.difficulty,
                    mistakes: gameState.mistakes,
                    hints: gameState.hintsUsed,
                    queens: gameState.queens.length,
                    showMistakes: gameState.showMistakes,
                    strict: gameState.isStrict,
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        children: [
                          GameBoard(
                            colors: AppTheme.boardColors(
                              brightness: theme.brightness,
                              highContrast: settings.highContrast,
                            ),
                            onInvalidPlacement: () {
                              final messenger = ScaffoldMessenger.of(context);
                              messenger.hideCurrentSnackBar();
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('That placement is not allowed.'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                          if (gameState.isPaused && !gameState.isSolved)
                            Positioned.fill(
                              child: ColoredBox(
                                color: scheme.scrim.withValues(alpha: 0.55),
                                child: Center(
                                  child: FilledButton.icon(
                                    onPressed: () => ref
                                        .read(gameStateProvider.notifier)
                                        .resume(),
                                    icon: const Icon(Icons.play_arrow_rounded),
                                    label: const Text('RESUME'),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  _ControlBar(
                    canUndo: ref.read(gameStateProvider.notifier).canUndo,
                    canRedo: ref.read(gameStateProvider.notifier).canRedo,
                    enabled: !gameState.isSolved,
                    isPaused: gameState.isPaused,
                    onUndo: () => ref.read(gameStateProvider.notifier).undo(),
                    onRedo: () => ref.read(gameStateProvider.notifier).redo(),
                    onHint: () => ref.read(gameStateProvider.notifier).useHint(),
                    onPause: () => ref.read(gameStateProvider.notifier).pause(),
                    onResume: () => ref.read(gameStateProvider.notifier).resume(),
                  ),
                  const SizedBox(height: 12),
                  if (isDaily && services != null)
                    Text(
                      services.stats.lastDailyCompletionDate ==
                              du.DateUtils.dateKey(DateTime.now())
                          ? 'Daily complete — come back tomorrow!'
                          : 'Your daily puzzle — one attempt.',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmRestart() {
    ref.read(gameStateProvider.notifier).restart();
  }

  void _maybeShowCompletion(GameState? game, CompletionRecord? record) {
    if (game == null || !game.isSolved || record == null) return;
    if (record.puzzle.id != game.puzzle.id) return;
    if (_lastHandledCompletionId == game.puzzle.id) return;
    _lastHandledCompletionId = game.puzzle.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => CompletionDialog(record: record, elapsed: game.elapsed),
      );
    });
  }
}

class _StatusRow extends StatelessWidget {
  final Duration elapsed;
  final int size;
  final Difficulty difficulty;
  final int mistakes;
  final int hints;
  final int queens;
  final bool showMistakes;
  final bool strict;

  const _StatusRow({
    required this.elapsed,
    required this.size,
    required this.difficulty,
    required this.mistakes,
    required this.hints,
    required this.queens,
    required this.showMistakes,
    required this.strict,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            formatElapsed(elapsed),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            '● $queens/$size',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (showMistakes || strict)
            Text(
              '✗ $mistakes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: mistakes > 0 ? scheme.error : scheme.onSurface,
                  ),
            ),
          if (hints > 0)
            Text(
              '💡 $hints',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  final bool canUndo;
  final bool canRedo;
  final bool enabled;
  final bool isPaused;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onHint;
  final VoidCallback onPause;
  final VoidCallback onResume;

  const _ControlBar({
    required this.canUndo,
    required this.canRedo,
    required this.enabled,
    required this.isPaused,
    required this.onUndo,
    required this.onRedo,
    required this.onHint,
    required this.onPause,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      _RoundButton(
        tooltip: 'Undo',
        icon: Icons.undo_rounded,
        onPressed: enabled && canUndo ? onUndo : null,
      ),
      _RoundButton(
        tooltip: 'Redo',
        icon: Icons.redo_rounded,
        onPressed: enabled && canRedo ? onRedo : null,
      ),
      _RoundButton(
        tooltip: 'Hint',
        icon: Icons.lightbulb_outline_rounded,
        onPressed: enabled ? onHint : null,
      ),
      _RoundButton(
        tooltip: isPaused ? 'Resume' : 'Pause',
        icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
        onPressed: enabled ? (isPaused ? onResume : onPause) : null,
      ),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: buttons,
    );
  }
}

class _RoundButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const _RoundButton({required this.tooltip, required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }
}

/// Shown exactly once per completed puzzle.
class CompletionDialog extends StatelessWidget {
  final CompletionRecord record;
  final Duration elapsed;

  const CompletionDialog({super.key, required this.record, required this.elapsed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final score = record.score;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      title: Column(
        children: [
          Icon(Icons.emoji_events_rounded, size: 56, color: scheme.primary),
          const SizedBox(height: 12),
          Text('Solved!',
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${record.mode.label} • ${record.puzzle.size}×${record.puzzle.size} • '
              '${record.puzzle.difficulty.label}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            _ScoreLine(label: 'Base', value: '${score.baseScore}'),
            _ScoreLine(
                label: 'Difficulty bonus', value: '+${score.difficultyBonus}'),
            _ScoreLine(label: 'Speed bonus', value: '+${score.speedBonus}'),
            _ScoreLine(label: 'Streak bonus', value: '+${score.streakBonus}'),
            if (score.perfect) const _ScoreLine(label: 'Perfect bonus', value: '+100'),
            if (score.mistakePenalty > 0)
              _ScoreLine(label: 'Mistake penalty', value: '-${score.mistakePenalty}'),
            if (score.hintPenalty > 0)
              _ScoreLine(label: 'Hint penalty', value: '-${score.hintPenalty}'),
            const Divider(height: 20),
            _ScoreLine(
                label: 'Total',
                value: '${score.finalScore}',
                emphasize: true),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Metric(label: 'Time', value: formatElapsed(elapsed)),
                _Metric(label: 'Mistakes', value: '${score.mistakes}'),
                _Metric(label: 'Hints', value: '${score.hintsUsed}'),
              ],
            ),
            if (record.streak > 1) ...[
              const SizedBox(height: 12),
              Text('🔥 ${record.streak} day streak',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.primary, fontWeight: FontWeight.w700)),
            ],
            if (record.newlyUnlocked.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Achievements unlocked!',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...record.newlyUnlocked.map((id) {
                        final def = AchievementService.definitionFor(id);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(def.icon, size: 18, color: scheme.primary),
                              const SizedBox(width: 8),
                              Text(def.title),
                            ],
                          ),
                        );
                      }),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => ShareService.shareResult(record.resultText),
          child: const Text('SHARE'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class _ScoreLine extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _ScoreLine({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: emphasize
                  ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
                  : theme.textTheme.bodyMedium),
          Text(value,
              style: emphasize
                  ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
                  : theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}