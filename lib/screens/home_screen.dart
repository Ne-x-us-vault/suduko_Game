import 'package:flutter/material.dart';
import 'package:sudoku_game/models.dart';
import 'package:sudoku_game/theme.dart';
import 'package:sudoku_game/screens/game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Difficulty _selectedDifficulty = Difficulty.medium;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 56),
                _buildLogo(isDark),
                const SizedBox(height: 48),
                _buildSectionLabel('DIFFICULTY', isDark),
                const SizedBox(height: 14),
                _buildDifficultyGrid(isDark),
                const SizedBox(height: 32),
                _buildStartButton(isDark),
                const SizedBox(height: 48),
                _buildInfoSection(isDark),
                const SizedBox(height: 56),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.circular(0),
            boxShadow: [],
          ),
          child: const Center(
            child: Text(
              '#',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                'Gridline',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.black,
                  letterSpacing: -1.2,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sudoku',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  color: isDark ? AppColors.grey400 : AppColors.grey500,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: isDark ? AppColors.grey500 : AppColors.grey400,
      ),
    );
  }

  Widget _buildDifficultyGrid(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            _buildDifficultyCard(Difficulty.easy, 'Easy', '15 min', isDark),
            const SizedBox(width: 12),
            _buildDifficultyCard(Difficulty.medium, 'Medium', '25 min', isDark),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildDifficultyCard(Difficulty.hard, 'Hard', '40 min', isDark),
            const SizedBox(width: 12),
            _buildDifficultyCard(
                Difficulty.expert, 'Expert', '60+ min', isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildDifficultyCard(
    Difficulty difficulty,
    String label,
    String time,
    bool isDark,
  ) {
    final isSelected = _selectedDifficulty == difficulty;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDifficulty = difficulty),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.black
                : (isDark ? AppColors.grey900 : AppColors.white),
            borderRadius: BorderRadius.circular(0),
            border: Border.all(
              color: isSelected
                  ? AppColors.black
                  : (isDark ? AppColors.grey800 : AppColors.gridThin),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.white : AppColors.black),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.7)
                      : (isDark ? AppColors.grey500 : AppColors.grey400),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _startNewGame(_selectedDifficulty),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
        ),
        child: const Text(
          'New Game',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey900 : AppColors.white,
        borderRadius: BorderRadius.circular(0),
        border: Border.all(
          color: isDark ? AppColors.grey800 : AppColors.gridThin,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('0', 'Played', isDark),
          _buildDivider(isDark),
          _buildStat('0', 'Won', isDark),
          _buildDivider(isDark),
          _buildStat('--:--', 'Best', isDark),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.black,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.grey500 : AppColors.grey400,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 32,
      color: isDark ? AppColors.grey800 : AppColors.gridThin,
    );
  }

  void _startNewGame(Difficulty difficulty) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            GameScreen(difficulty: difficulty),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
