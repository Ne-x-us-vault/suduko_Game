import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/model/difficulty.dart';
import '../../state/app_services.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(appServicesProvider);
    final stats = services?.stats;

    return Scaffold(
      appBar: AppBar(title: const Text('My Stats')),
      body: SafeArea(
        child: stats == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _StatCard(
                          label: 'Games',
                          value: '${stats.gamesCompleted}',
                          icon: Icons.sports_score_rounded,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'Win rate',
                          value: '${stats.completionRate.toStringAsFixed(0)}%',
                          icon: Icons.trending_up_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _StatCard(
                          label: 'Best score',
                          value: '${stats.bestScore}',
                          icon: Icons.stars_rounded,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'Fastest',
                          value: _fmtSeconds(stats.fastestTimeSeconds),
                          icon: Icons.bolt_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SectionCard(
                      title: 'Overview',
                      rows: [
                        ('Total score', '${stats.totalScore}'),
                        ('Games started', '${stats.gamesStarted}'),
                        ('Total time', _fmtSeconds(stats.totalTimeSeconds)),
                        ('Avg time', _fmtSeconds(stats.averageTimeSeconds.round())),
                        ('Total mistakes', '${stats.totalMistakes}'),
                        ('Total hints', '${stats.totalHints}'),
                        ('Queens placed', '${stats.totalQueensPlaced}'),
                        ('No-mistake solves', '${stats.noMistakeSolves}'),
                        ('No-hint solves', '${stats.noHintSolves}'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Streak',
                      rows: [
                        ('Current', '${stats.currentStreak} day${stats.currentStreak == 1 ? '' : 's'}'),
                        ('Longest', '${stats.longestStreak} day${stats.longestStreak == 1 ? '' : 's'}'),
                        ('Daily completed', '${stats.dailyChallengesCompleted}'),
                        ('Quick play', '${stats.quickPlayCompletions}'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'By difficulty',
                      rows: [
                        for (final d in Difficulty.values)
                          (
                            d.label,
                            '${stats.completionsByDifficulty[d.nameValue] ?? 0}',
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'By board size',
                      rows: [
                        for (var s = 5; s <= 10; s++)
                          ('$s×$s', '${stats.completionsBySize['$s'] ?? 0}'),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  String _fmtSeconds(int seconds) {
    if (seconds <= 0) return '—';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 26, color: scheme.primary),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<(String, String)> rows;

  const _SectionCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label,
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text(value,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}