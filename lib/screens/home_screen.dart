import 'package:flutter/material.dart';
import 'package:sudoku_game/theme.dart';

enum Difficulty { easy, medium, hard, expert }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Difficulty _selectedDifficulty = Difficulty.medium;
  bool _hasUnfinishedPuzzle = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gridline Sudoku'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.graphite,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              _buildHeader(),
              const SizedBox(height: 32),
              _buildDifficultySelector(),
              const SizedBox(height: 24),
              _buildActionButtons(),
              const SizedBox(height: 24),
              _buildStatsRow(),
              const Spacer(),
              const Text(
                'Calm. Focused. Complete.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B6B6B),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.grid_on,
            size: 40,
            color: AppColors.teal,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gridline Sudoku',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: AppColors.graphite,
                  letterSpacing: -1,
                ),
              ),
              Text(
                'Calm. Focused. Complete.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.graphite,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cellSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gridLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Difficulty',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.graphite,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: Difficulty.values.map((diff) {
              final isSelected = diff == _selectedDifficulty;
              return FilterChip(
                label: Text(_difficultyLabel(diff),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.graphite,
                      fontSize: 12,
                    )),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _selectedDifficulty = diff);
                },
                selectedColor: AppColors.teal,
                backgroundColor: AppColors.cellSurface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _difficultyLabel(Difficulty diff) {
    switch (diff) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
      case Difficulty.expert:
        return 'Expert';
    }
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _startNewGame(_selectedDifficulty),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('New Game'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _hasUnfinishedPuzzle ? _continueGame : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _hasUnfinishedPuzzle ? AppColors.graphite : AppColors.gridLine,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Continue'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _StatCard(
          icon: Icons.star,
          label: 'Streak',
          value: 'Streak: 0',
          color: AppColors.gold,
        ),
        _StatCard(
          icon: Icons.history,
          label: 'Games',
          value: '0 played',
          color: AppColors.teal,
        ),
        _StatCard(
          icon: Icons.watch_later,
          label: 'Daily',
          value: 'Available',
          color: AppColors.coral,
        ),
      ],
    );
  }

  void _startNewGame(Difficulty difficulty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting game')),
    );
  }

  void _continueGame() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Continuing puzzle')),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  _StatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    Key? key,
  })  : icon = icon,
        label = label,
        value = value,
        color = color,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFFFFFFFF),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6B6B6B),
            ),
          ),
        ],
      ),
    );
  }
}