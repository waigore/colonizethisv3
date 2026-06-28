import 'dart:async';

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/main.dart' as app_main;
import 'package:flutter/widgets.dart';

void main() {
  test('bootstrap initializes bindings and runApp in the same zone', () async {
    Zone? bindingZone;
    Zone? runAppZone;

    final bootstrapFuture = runZonedGuarded<Future<void>>(
      () async {
        await app_main.bootstrapApp(
          ensureBindingInitialized: () {
            bindingZone = Zone.current;
          },
          initSessionLogBuffer: () {},
          ensureMapTerrainLoaded: () async {},
          initHive: () async {},
          openHiveBoxSafely: (_) async {},
          ensureDesktopWindowStartup: () async {},
          runAppFn: (_) {
            runAppZone = Zone.current;
          },
          // Skip Cinzel preload under unit tests; production awaits bundled
          // registration before runApp (see `preloadEditorialMonocleFonts`).
          preloadFonts: () async {},
        );
      },
      (Object error, StackTrace stackTrace) {
        fail('unexpected zoned error: $error\n$stackTrace');
      },
    );

    await bootstrapFuture;

    expect(bindingZone, isNotNull);
    expect(runAppZone, isNotNull);
    expect(identical(bindingZone, runAppZone), isTrue);
  });

  test('bootstrap awaits startup initialization before runApp', () async {
    final callOrder = <String>[];
    final openedBoxes = <String>[];

    await app_main.bootstrapApp(
      ensureBindingInitialized: () {
        callOrder.add('binding');
      },
      initSessionLogBuffer: () {
        callOrder.add('session');
      },
      ensureMapTerrainLoaded: () async {
        callOrder.add('terrain');
      },
      initHive: () async {
        callOrder.add('hive');
      },
      openHiveBoxSafely: (name) async {
        callOrder.add('box:$name');
        openedBoxes.add(name);
      },
      ensureDesktopWindowStartup: () async {
        callOrder.add('desktop');
      },
      runAppFn: (Widget app) {
        callOrder.add('runApp');
      },
      preloadFonts: () async {
        callOrder.add('fonts');
      },
    );

    expect(
      callOrder,
      equals([
        'binding',
        'session',
        'terrain',
        'hive',
        'box:${HiveBoxNames.settings}',
        'box:${HiveBoxNames.games}',
        'box:${HiveBoxNames.offlineQueue}',
        'desktop',
        'fonts',
        'runApp',
      ]),
    );
    expect(
      openedBoxes,
      equals([
        HiveBoxNames.settings,
        HiveBoxNames.games,
        HiveBoxNames.offlineQueue,
      ]),
    );
  });
}
