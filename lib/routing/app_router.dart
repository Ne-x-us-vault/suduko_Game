import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../features/home/home_screen.dart';
import '../features/gameplay/game_screen.dart';
import '../features/statistics/stats_screen.dart';
import '../features/settings/settings_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'play',
            builder: (context, state) => const GameScreen(),
          ),
          GoRoute(
            path: 'stats',
            builder: (context, state) => const StatsScreen(),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}
