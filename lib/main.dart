import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/queens_app.dart';
import 'persistence/kv_storage.dart';
import 'persistence/persistence_service.dart';
import 'state/app_services.dart';
import 'state/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = await createDefaultStorage();
  final persistence = PersistenceService(storage: storage);

  final services = AppServices(persistence: persistence);
  await services.load();
  await services.tryRestoreSession();

  final initialSettings = await persistence.loadSettings();

  runApp(
    ProviderScope(
      overrides: [
        persistenceProvider.overrideWithValue(persistence),
        appServicesProvider.overrideWithValue(services),
        initialSettingsProvider.overrideWithValue(initialSettings),
      ],
      child: const QueensApp(),
    ),
  );
}
