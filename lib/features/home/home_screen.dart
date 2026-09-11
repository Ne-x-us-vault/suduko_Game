import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utilities/date_utils.dart' as du;
import '../../game/model/game_mode.dart';
import '../../game/streaks/streak_service.dart';
import '../../routing/play_config.dart';
import '../../state/app_services.dart';
import '../../state/settings_controller.dart';

/// Home screen: entry point with Play (quick play), Daily Challenge, and
/// navigation to Stats / Achievements / Settings / About.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(appServicesProvider);
    final settings = ref.watch(settingsControllerProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final stats = services?.stats;
    final streak =
        stats == null ? 0 : StreakService.computeStreak(stats, DateTime.now());
    final todayDone = stats?.lastDailyCompletionDate == du.DateUtils.dateKey(DateTime.now());
    final hasResume = services?.hasActiveSession ?? false;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  Icon(Icons.grid_view_rounded,
                      size: 72, color: scheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'QUEENS',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'One queen per row, column, and region.\nNo two queens may touch.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
                  ),
                  const Spacer(flex: 2),
                  if (hasResume) ...[
                    OutlinedButton.icon(
                      onPressed: () => context.push('/play',
                          extra: const ResumeConfig()),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('RESUME'),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton.icon(
                    onPressed: () => context.push('/play'),
                    icon: const Icon(Icons.grid_view_rounded),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text('PLAY'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: () => context.push('/daily'),
                    icon: Icon(
                      todayDone
                          ? Icons.check_circle_rounded
                          : Icons.calendar_today_rounded,
                    ),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                          todayDone ? 'DAILY — DONE TODAY' : 'DAILY CHALLENGE'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => context.push('/stats'),
                    icon: const Icon(Icons.bar_chart_rounded),
                    label: const Text('My Stats'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StreakPill(
                        icon: Icons.local_fire_department_rounded,
                        value: streak,
                      ),
                      const SizedBox(width: 24),
                      _StreakPill(
                        icon: Icons.emoji_events_rounded,
                        value: stats?.longestStreak ?? 0,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('current streak',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                      const SizedBox(width: 40),
                      Text('best streak',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                  const Spacer(flex: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Settings',
                        onPressed: () => context.push('/settings'),
                        icon: const Icon(Icons.settings_rounded),
                      ),
                      IconButton(
                        tooltip: 'Achievements',
                        onPressed: () => context.push('/achievements'),
                        icon: const Icon(Icons.emoji_events_rounded),
                      ),
                      IconButton(
                        tooltip: 'About',
                        onPressed: () => context.push('/about'),
                        icon: const Icon(Icons.info_outline_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    settings.strictMode ? 'Strict mode on' : '',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Signals the game screen to resume the active session instead of starting a
/// fresh puzzle.
class ResumeConfig extends PlayConfig {
  const ResumeConfig()
      : super(mode: GameMode.quickPlay, resume: true);
}

class _StreakPill extends StatelessWidget {
  final IconData icon;
  final int value;

  const _StreakPill({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = value > 0;
    return Column(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor:
              enabled ? scheme.primary.withValues(alpha: 0.12) : scheme.surfaceContainerHighest,
          child: Icon(icon,
              size: 26,
              color: enabled ? scheme.primary : scheme.outline),
        ),
        const SizedBox(height: 6),
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: enabled ? scheme.onSurface : scheme.outline,
              ),
        ),
      ],
    );
  }
}