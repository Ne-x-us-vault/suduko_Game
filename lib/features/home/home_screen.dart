import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'QUEENS',
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.black,
                letterSpacing: 4,
              ),
            ),
            const Text(
              'One queen per row, column, and region.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 60),
            _MenuButton(
              label: 'PLAY',
              icon: Icons.play_arrow_rounded,
              onPressed: () => context.push('/play'),
              isPrimary: true,
            ),
            const SizedBox(height: 16),
            _MenuButton(
              label: 'DAILY CHALLENGE',
              icon: Icons.calendar_today_rounded,
              onPressed: () => context.push('/play'), // Placeholder for daily logic
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _IconButton(
                  icon: Icons.bar_chart_rounded,
                  label: 'Stats',
                  onPressed: () => context.push('/stats'),
                ),
                const SizedBox(width: 32),
                _IconButton(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  onPressed: () => context.push('/settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Theme.of(context).colorScheme.primary : Colors.white,
          foregroundColor: isPrimary ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: isPrimary ? 4 : 0,
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _IconButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
