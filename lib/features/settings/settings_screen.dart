import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/hints/hint_service.dart';
import '../../game/settings/game_settings.dart';
import '../../state/app_services.dart';
import '../../state/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SectionLabel('APPEARANCE'),
              _SwitchTile(
                title: 'Dark mode',
                value: settings.themeMode == ThemeMode.dark,
                onChanged: (v) => controller
                    .setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
              ),
              _SwitchTile(
                title: 'High contrast',
                subtitle: 'Stronger region colors and boundaries',
                value: settings.highContrast,
                onChanged: controller.setHighContrast,
              ),
              _SwitchTile(
                title: 'Reduce motion',
                value: settings.reducedMotion,
                onChanged: controller.setReducedMotion,
              ),
              const Divider(),
              const _SectionLabel('GAMEPLAY'),
              _SwitchTile(
                title: 'Strict mode',
                subtitle: 'Block illegal placements instead of allowing mistakes',
                value: settings.strictMode,
                onChanged: controller.setStrictMode,
              ),
              _SwitchTile(
                title: 'Show mistakes',
                subtitle: 'Highlight conflicting queens in red',
                value: settings.showMistakes,
                onChanged: controller.setShowMistakes,
              ),
              _SwitchTile(
                title: 'Auto marks',
                subtitle: 'Automatically cross off rows, columns and neighbors',
                value: settings.autoMarks,
                onChanged: controller.setAutoMarks,
              ),
              const Divider(),
              const _SectionLabel('FEEDBACK'),
              _SwitchTile(
                title: 'Sound',
                value: settings.soundEnabled,
                onChanged: controller.setSoundEnabled,
              ),
              _SwitchTile(
                title: 'Haptics',
                value: settings.hapticsEnabled,
                onChanged: controller.setHapticsEnabled,
              ),
              const Divider(),
              const _SectionLabel('HINTS'),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SegmentedButton<HintLevel>(
                  segments: const [
                    ButtonSegment(
                      value: HintLevel.subtle,
                      label: Text('Subtle'),
                      icon: Icon(Icons.visibility_outlined),
                    ),
                    ButtonSegment(
                      value: HintLevel.normal,
                      label: Text('Normal'),
                      icon: Icon(Icons.visibility),
                    ),
                    ButtonSegment(
                      value: HintLevel.direct,
                      label: Text('Direct'),
                      icon: Icon(Icons.touch_app_outlined),
                    ),
                  ],
                  selected: {settings.hintLevel},
                  onSelectionChanged: (selection) =>
                      controller.setHintLevel(selection.first),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Animation intensity',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Slider(
                      value: settings.animationIntensity,
                      onChanged: controller.setAnimationIntensity,
                    ),
                  ],
                ),
              ),
              const Divider(),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _confirmResetStats(context, ref),
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('RESET STATISTICS'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _confirmResetAll(context, ref),
                icon: const Icon(Icons.delete_forever_rounded),
                label: const Text('ERASE ALL DATA'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmResetStats(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset statistics?'),
        content: const Text('This clears all recorded game stats. It cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('RESET'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(appServicesProvider)?.resetStatistics();
    }
  }

  Future<void> _confirmResetAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erase all data?'),
        content: const Text(
            'This removes settings, stats, achievements and any saved session.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ERASE'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final services = ref.read(appServicesProvider);
      await services?.resetAllLocalData();
      ref
          .read(settingsControllerProvider.notifier)
          .update(const GameSettings());
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}