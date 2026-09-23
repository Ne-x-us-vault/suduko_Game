import 'package:flutter/material.dart';
import 'package:sudoku_game/models.dart';
import 'package:sudoku_game/theme.dart';
import 'package:sudoku_game/screens/game_screen.dart';

class DifficultyMeta {
  final Difficulty difficulty;
  final String label;
  final int clues;
  final String estTime;

  const DifficultyMeta(this.difficulty, this.label, this.clues, this.estTime);
}

const _difficulties = [
  DifficultyMeta(Difficulty.easy, 'Easy', 38, '~15 min'),
  DifficultyMeta(Difficulty.medium, 'Medium', 30, '~25 min'),
  DifficultyMeta(Difficulty.hard, 'Hard', 25, '~40 min'),
  DifficultyMeta(Difficulty.expert, 'Expert', 22, '~60 min'),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GameStats _stats = GameStats();
  Difficulty _selected = Difficulty.medium;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _stats,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  const _SectionLabel('DIFFICULTY'),
                  const SizedBox(height: 12),
                  _buildDifficultyGrid(),
                  const SizedBox(height: 20),
                  _buildNewGameButton(),
                  const SizedBox(height: 36),
                  _buildStatsCard(),
                  const SizedBox(height: 20),
                  Text(
                    'Gridline Sudoku v1.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                      color: context.inkMuted.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: context.accent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: context.accent.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '#',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.onAccent,
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
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Gridline',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
              ),
              Text(
                'S U D O K U',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3.5,
                  color: context.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyGrid() {
    return Column(
      children: [
        Row(
          children: [
            _buildDifficultyCard(_difficulties[0]),
            const SizedBox(width: 12),
            _buildDifficultyCard(_difficulties[1]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildDifficultyCard(_difficulties[2]),
            const SizedBox(width: 12),
            _buildDifficultyCard(_difficulties[3]),
          ],
        ),
      ],
    );
  }

  Widget _buildDifficultyCard(DifficultyMeta meta) {
    final isSelected = _selected == meta.difficulty;

    return Expanded(
      child: Semantics(
        selected: isSelected,
        button: true,
        child: GestureDetector(
          onTap: () => setState(() => _selected = meta.difficulty),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isSelected ? context.accent : context.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? context.accent
                    : context.line.withValues(alpha: 0.9),
                width: 1.4,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: context.accent.withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      meta.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.onAccent
                            : context.ink,
                      ),
                    ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 160),
                      opacity: isSelected ? 1 : 0,
                      child: const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: AppColors.onAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${meta.clues} clues',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.onAccent.withValues(alpha: 0.85)
                        : context.inkMuted,
                  ),
                ),
                Text(
                  meta.estTime,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? AppColors.onAccent.withValues(alpha: 0.7)
                        : context.inkMuted.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewGameButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _startNewGame(_selected),
        icon: const Icon(Icons.play_arrow_rounded, size: 20),
        label: const Text('New Game'),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Row(
          children: [
            _buildStat('${_stats.totalGamesPlayed}', 'Played'),
            _buildDivider(),
            _buildStat('${_stats.gamesWon}', 'Won'),
            _buildDivider(),
            _buildStat(_stats.winRate, 'Win rate'),
            _buildDivider(),
            _buildStat(_stats.maxStreak.toString(), 'Best streak'),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: context.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: context.inkMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      color: context.line,
    );
  }

  void _startNewGame(Difficulty difficulty) {
    _stats.startNewGame();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            GameScreen(difficulty: difficulty),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: context.accent,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
            color: context.inkMuted,
          ),
        ),
      ],
    );
  }
}