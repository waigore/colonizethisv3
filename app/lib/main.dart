import 'dart:async';
import 'dart:io' show Directory;

import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:session_log_buffer/session_log_buffer.dart';

import 'app.dart';
import 'config/constants.dart';
import 'config/ct_e2e.dart';
import 'config/map_terrain_config.dart';
import 'core/services/app_event_handler_scope.dart';

/// Opens one Hive box; failures are isolated so another box (e.g. games) still opens.
Future<void> _openHiveBoxSafely(String name) async {
  try {
    await Hive.openBox<dynamic>(name);
  } catch (e, st) {
    // Boxes may be locked (e.g. another instance) or corrupt; app still runs where possible.
    dataLogger(
      'hive',
    ).w('failed to open box "$name"', error: e, stackTrace: st);
  }
}

@visibleForTesting
Future<void> bootstrapApp({
  required void Function() ensureBindingInitialized,
  required void Function() initSessionLogBuffer,
  required Future<void> Function() ensureMapTerrainLoaded,
  required Future<void> Function() initHive,
  required Future<void> Function(String name) openHiveBoxSafely,
  required void Function(Widget app) runAppFn,
}) async {
  ensureBindingInitialized();
  initSessionLogBuffer();
  await ensureMapTerrainLoaded();
  await initHive();
  await openHiveBoxSafely(HiveBoxNames.settings);
  await openHiveBoxSafely(HiveBoxNames.games);
  await openHiveBoxSafely(HiveBoxNames.offlineQueue);
  runAppFn(const ProviderScope(child: AppEventHandlerScope(child: App())));
}

/// Integration tests (`integration_test/`) call this after
/// [IntegrationTestWidgetsFlutterBinding.ensureInitialized] so the test binding
/// is not replaced. Uses a **temporary** Hive directory when [kCtE2EEnabled] to
/// avoid file locks with a dev desktop install. **SPEC:** `SPEC/program/e2e-integration-tests.md`.
@visibleForTesting
Future<void> bootstrapForIntegrationTest() async {
  await bootstrapApp(
    ensureBindingInitialized: () {},
    initSessionLogBuffer: SessionLogBuffer.init,
    ensureMapTerrainLoaded: MapTerrainConfig.ensureLoaded,
    initHive: () async {
      if (kCtE2EEnabled) {
        final tmp = Directory.systemTemp.createTempSync('ct_e2e_hive_');
        Hive.init(tmp.path);
        return;
      }
      await Hive.initFlutter();
    },
    openHiveBoxSafely: _openHiveBoxSafely,
    runAppFn: runApp,
  );
}

void main() {
  runZonedGuarded(
    () async {
      await bootstrapApp(
        ensureBindingInitialized: WidgetsFlutterBinding.ensureInitialized,
        initSessionLogBuffer: SessionLogBuffer.init,
        ensureMapTerrainLoaded: MapTerrainConfig.ensureLoaded,
        initHive: Hive.initFlutter,
        openHiveBoxSafely: _openHiveBoxSafely,
        runAppFn: runApp,
      );
    },
    (Object error, StackTrace stackTrace) {
      appLogger().e(
        'uncaught async error',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}
