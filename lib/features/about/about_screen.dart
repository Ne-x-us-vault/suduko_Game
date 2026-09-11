import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Icon(Icons.grid_view_rounded,
                        size: 64, color: scheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      'QUEENS',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'v$_version',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Rules',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const _RuleTile(
                icon: Icons.grid_3x3_rounded,
                text: 'You are given a board divided into colored regions, '
                    'each of which contains exactly one queen.',
              ),
              const _RuleTile(
                icon: Icons.straighten_rounded,
                text: 'Every row and every column also contains exactly '
                    'one queen.',
              ),
              const _RuleTile(
                icon: Icons.blur_circular_rounded,
                text: 'No two queens may touch — not even diagonally or in '
                    'the eight adjacent cells.',
              ),
              const SizedBox(height: 20),
              Text(
                'How it is made',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Every board is generated locally on your device with a fully '
                    'deterministic generator, verified to have exactly one '
                    'solution. Difficulties are classified by a deduction '
                    'engine that mirrors how humans actually solve.',
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 20),
              Text(
                'Privacy',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Everything is stored on this device. No accounts, no ads, '
                    'no network requests, no tracking.',
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RuleTile({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}