import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/achievements/achievement_service.dart';
import '../../state/app_services.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(appServicesProvider);
    final achievements = services?.achievements;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final locked = AchievementService.definitions
        .where((d) => achievements?[d.id]?.unlocked != true)
        .length;
    final unlocked = AchievementService.definitions.length - locked;

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: SafeArea(
        child: achievements == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            '$unlocked/${AchievementService.definitions.length}',
                            style: theme.textTheme.displayMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'unlocked',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: AchievementService.definitions.isEmpty
                                  ? 0
                                  : unlocked /
                                      AchievementService.definitions.length,
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final def in AchievementService.definitions)
                    _AchievementTile(
                      definition: def,
                      unlocked: achievements[def.id]?.unlocked == true,
                      unlockedAt: achievements[def.id]?.unlockedAt,
                    ),
                ],
              ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final AchievementDefinition definition;
  final bool unlocked;
  final DateTime? unlockedAt;

  const _AchievementTile({
    required this.definition,
    required this.unlocked,
    required this.unlockedAt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: ListTile(
        leading: Icon(
          definition.icon,
          size: 32,
          color: unlocked ? scheme.primary : scheme.outline,
        ),
        title: Text(
          definition.title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: unlocked ? scheme.onSurface : scheme.onSurfaceVariant,
          ),
        ),
        subtitle: Text(definition.description),
        trailing: unlocked
            ? Text(
                _fmtDate(unlockedAt),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              )
            : null,
      ),
    );
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    final local = d.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}