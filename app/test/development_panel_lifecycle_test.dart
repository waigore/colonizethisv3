// Flame lifecycle + repeated mount/unmount for Development panel (Refs #4687).
// Shell map pause: development_panel_shell_map_pause_test.dart.

import 'package:colonizethis_app/features/game/flame/region_map/ct_region_map_game.dart';
import 'package:colonizethis_app/features/game/screens/development/development_panel_keys.dart';
import 'package:colonizethis_app/features/game/screens/development/development_screen.dart';
import 'package:colonizethis_app/features/game/screens/development/development_screen_body.dart';
import 'package:colonizethis_app/providers/shell_main_map_pause_provider.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'ct_region_map_test_support_core.dart';
import 'development_panel_lifecycle_support.dart';
import 'development_panel_test_support.dart';
import 'panel_fixtures/core.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openDevelopmentPanelTestHiveBox(suiteId: 'lifecycle');
    await warmCtRegionMapCachesForTests();
  });

  tearDownAll(() async {
    await gamesBox.close();
  });

  testWidgets(
    'ten DevelopmentScreenBody mount/unmount cycles leave no stacked panel map engines (Refs #4687)',
    (WidgetTester tester) async {
      final game = buildDevelopmentPanelGoldenGame();

      for (var cycle = 0; cycle < 10; cycle++) {
        await tester.pumpWidget(
          buildAppShell(
            child: SizedBox(
              width: 900,
              height: 760,
              child: DevelopmentScreenBody(
                game: game,
                humanPlayerId: kPanelTestHumanPlayerId,
              ),
            ),
            overrides: developmentPanelLifecycleOverrides(gamesBox, game),
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
          ),
        );
        await pumpDevelopmentPanelReady(tester);
        expect(
          find.byKey(DevelopmentPanelKeys.panelMapKeyForRegion(kRegionOldWorld)),
          findsOneWidget,
        );
        expect(countDevelopmentPanelRegionMapGameWidgets(tester), 1);
        final panelGame =
            developmentPanelSingleRegionMapGame(tester) as CtRegionMapGame;

        await tester.pumpWidget(
          buildAppShell(
            child: const SizedBox.shrink(),
            overrides: developmentPanelLifecycleOverrides(gamesBox, game),
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
          ),
        );
        await tester.pump();
        expect(countDevelopmentPanelRegionMapGameWidgets(tester), 0);
        expect(panelGame.paused, isTrue);
      }
    },
  );

  testWidgets(
    'DevelopmentScreen wraps body with shell map pause scope (Refs #4687)',
    (WidgetTester tester) async {
      final game = buildDevelopmentPanelGoldenGame();
      final container = ProviderContainer(
        overrides: developmentPanelLifecycleOverrides(gamesBox, game),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: DevelopmentScreen(
              game: game,
              humanPlayerId: kPanelTestHumanPlayerId,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(container.read(shellMainMapPauseHoldProvider), 1);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SizedBox.shrink()),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(container.read(shellMainMapPauseHoldProvider), 0);
    },
  );
}
