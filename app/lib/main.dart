import 'dart:async';
import 'dart:io' show Directory;

import 'package:colonizethis_app/package_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:session_log_buffer/session_log_buffer.dart';

import 'app.dart';
import 'config/constants.dart';
import 'config/ct_e2e.dart';
import 'config/map_terrain_config.dart';
import 'config/themes.dart';
import 'core/services/app_event_handler_scope.dart';
import 'core/services/blessed_ai_profile_loader.dart';
import 'core/services/desktop_window_startup_service.dart';
import 'features/shell/new_game_leader_dialog_builder.dart';

/// Opens one Hive box; failures are isolated so another box (e.g. games) still opens.
Future<void> _openHiveBoxSafely(String name) async {
  try {
    await Hive.openBox<dynamic>(name);
  } catch (e, st) {
    // Boxes may be locked (e.g. another instance) or corrupt; app still runs where possible.
    packageLogger(
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
  required Future<void> Function() ensureDesktopWindowStartup,
  required void Function(Widget app) runAppFn,
  Future<void> Function()? preloadFonts,
}) async {
  ensureBindingInitialized();
  initSessionLogBuffer();
  await ensureMapTerrainLoaded();
  await initHive();
  await openHiveBoxSafely(HiveBoxNames.settings);
  await openHiveBoxSafely(HiveBoxNames.games);
  await openHiveBoxSafely(HiveBoxNames.offlineQueue);
  await ensureDesktopWindowStartup();
  // Warm blessed AI profile asset bundle for new-game UI and turn resolution.
  await BlessedAiProfileLoader.loadCatalog();
  // Await bundled Cinzel registration for the editorial-monocle theme;
  // `preloadEditorialMonocleFonts` hard-errors when assets are missing.
  // Skipped under e2e to avoid font bootstrap in integration_test. Tests
  // inject a no-op via [preloadFonts] so the suite stays hermetic.
  final preload =
      preloadFonts ??
      () => preloadEditorialMonocleFonts(skipInTests: kCtE2EEnabled);
  await preload();
  // Composition root wires the shell feature's new-game leader dialog builder
  // into the core event-handler scope so `core/services/` stays free of
  // `features/shell/` imports (Refs #3546). SPEC/program/app-ui-wiring.md.
  runAppFn(
    const ProviderScope(
      child: AppEventHandlerScope(
        extraDialogBuilders: {
          newGameLeaderSelectionDialogId: buildNewGameLeaderSelectionDialog,
        },
        child: App(),
      ),
    ),
  );
}

/// Integration tests (`integration_test/`) call this after
/// [IntegrationTestWidgetsFlutterBinding.ensureInitialized] so the test binding
/// is not replaced. Uses a **temporary** Hive directory when [kCtE2EEnabled] to
/// avoid file locks with a dev desktop install. **SPEC:** `SPEC/program/e2e-integration-tests.md`.
@visibleForTesting
Future<void> bootstrapForIntegrationTest() async {
  await bootstrapApp(
    ensureBindingInitialized: () {},
    // Skip SessionLogBuffer.init: it sets Logger.level to debug and replaces
    // Logger.defaultFilter, undoing suppressLogsForTests() and adding listener
    // overhead — Linux e2e then misses fleet NW wall-clock (Quality workflow).
    initSessionLogBuffer: kCtE2EEnabled ? () {} : SessionLogBuffer.init,
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
    ensureDesktopWindowStartup: () async {},
    runAppFn: runApp,
  );
}

void main() {
  // Bundled Cinzel only — no runtime HTTP fetch to fonts.gstatic.com.
  GoogleFonts.config.allowRuntimeFetching = false;
  runZonedGuarded(
    () async {
      await bootstrapApp(
        ensureBindingInitialized: WidgetsFlutterBinding.ensureInitialized,
        initSessionLogBuffer: SessionLogBuffer.init,
        ensureMapTerrainLoaded: MapTerrainConfig.ensureLoaded,
        initHive: Hive.initFlutter,
        openHiveBoxSafely: _openHiveBoxSafely,
        ensureDesktopWindowStartup:
            DesktopWindowStartupService.initializeIfSupported,
        runAppFn: runApp,
      );
    },
    (Object error, StackTrace stackTrace) {
      packageLogger().e(
        'uncaught async error',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}
