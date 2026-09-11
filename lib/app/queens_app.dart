import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_services.dart';
import '../state/game_controller.dart';
import '../state/settings_controller.dart';
import '../routing/app_router.dart';
import '../themes/app_theme.dart';

/// Root widget. Handles lifecycle (pause + persist on background), themes, and
/// routing.
class QueensApp extends ConsumerStatefulWidget {
  const QueensApp({super.key});

  @override
  ConsumerState<QueensApp> createState() => _QueensAppState();
}

class _QueensAppState extends ConsumerState<QueensApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // After the first frame, wire live hooks into the game controller and
    // load persisted settings (the provider is seeded with defaults until
    // then so the first build is never blocked by async I/O).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final services = ref.read(appServicesProvider);
      final controller = ref.read(gameStateProvider.notifier);
      if (services != null) {
        wireController(services, controller);
      }
      ref.read(settingsControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(gameStateProvider.notifier);
    final game = controller.current;
    final services = ref.read(appServicesProvider);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        if (game != null && !game.isSolved && !game.isPaused) {
          controller.pause();
        }
        if (game != null && services != null) {
          services.saveSession(controller.current!);
        }
        break;
      case AppLifecycleState.resumed:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final light = settings.highContrast
        ? AppTheme.highContrastLight
        : AppTheme.lightTheme;
    final dark =
        settings.highContrast ? AppTheme.highContrastDark : AppTheme.darkTheme;

    return MaterialApp.router(
      title: 'QUEENS',
      debugShowCheckedModeBanner: false,
      theme: light,
      darkTheme: dark,
      themeMode: settings.themeMode,
      routerConfig: AppRouter.router,
      builder: (context, child) {
        // Respect the platform text scale (large-text accessibility) but
        // clamp to a sane maximum so the board stays usable.
        final media = MediaQuery.of(context);
        final scale = media.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.35,
        );
        return MediaQuery(
          data: media.copyWith(textScaler: scale),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}