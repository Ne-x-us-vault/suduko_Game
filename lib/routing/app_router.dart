import 'package:go_router/go_router.dart';

import '../features/about/about_screen.dart';
import '../features/achievements/achievements_screen.dart';
import '../features/gameplay/game_screen.dart';
import '../features/home/home_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/statistics/stats_screen.dart';
import '../game/model/game_mode.dart';
import 'play_config.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/play',
        name: 'play',
        builder: (context, state) {
          final config = state.extra is PlayConfig
              ? (state.extra! as PlayConfig)
              : PlayConfig.quickPlayDefault;
          return GameScreen(config: config);
        },
      ),
      GoRoute(
        path: '/daily',
        name: 'daily',
        builder: (context, state) => const GameScreen(
          config: PlayConfig(mode: GameMode.dailyChallenge),
        ),
      ),
      GoRoute(
        path: '/stats',
        name: 'stats',
        builder: (context, state) => const StatsScreen(),
      ),
      GoRoute(
        path: '/achievements',
        name: 'achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
    ],
  );
}