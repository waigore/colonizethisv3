// Full-widget open-to-interactive profiling anchors for GAME80001 (Refs #4687).
//
// CI surrogate for profile/release DevTools sessions on binding hosts: measures
// pump-to-interactive on the campaign-sized golden fixture including the panel
// minimap. Not a debug wall-clock 1s assertion — the standing 1 000 ms gate is
// profile/release on Linux desktop and Android emulator (see enforcement boundary
// in SPEC/program/development-panel-read-model.md).

import 'package:colonizethis_app/features/game/screens/development/development_panel_keys.dart';
import 'package:colonizethis_app/features/game/screens/development/development_screen_body.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'ct_region_map_test_support_core.dart';
import 'development_panel_open_path_timing_fixture.dart';
import 'development_panel_test_support.dart';
import 'panel_fixtures/core.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openDevelopmentPanelTestHiveBox(suiteId: 'surface_budget');
    await warmCtRegionMapCachesForTests();
  });

  tearDownAll(() async {
    await gamesBox.close();
  });

  List<Override> _developmentOverrides(Game game) => [
    gamesBoxProvider.overrideWith((ref) => gamesBox),
    gameServiceProvider.overrideWith(
      (ref) => DevelopmentPanelMapGameService(gamesBox, GameSaveAdapter()),
    ),
    currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
    currentOrdersProvider.overrideWith(() => CurrentOrdersNotifier(const Orders())),
  ];

  Future<int> _openToInteractiveMs(WidgetTester tester, Game game) async {
    final sw = Stopwatch()..start();
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
        overrides: _developmentOverrides(game),
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
      ),
    );
    await pumpDevelopmentPanelReady(tester);
    expect(find.byKey(DevelopmentPanelKeys.overviewKey), findsOneWidget);
    expect(find.byKey(DevelopmentPanelKeys.scopeListKey), findsOneWidget);
    expect(
      find.byKey(DevelopmentPanelKeys.panelMapKeyForRegion(kRegionOldWorld)),
      findsOneWidget,
    );
    sw.stop();
    return sw.elapsedMilliseconds;
  }

  testWidgets(
    'cold open paints overview, list, and Old World minimap (Refs #4687)',
    (WidgetTester tester) async {
      final game = buildDevelopmentPanelGoldenGame();
      final elapsedMs = await _openToInteractiveMs(tester, game);
      expect(elapsedMs, greaterThan(0));
    },
  );

  testWidgets(
    'same-turn re-open completes interactive paint (Refs #4687)',
    (WidgetTester tester) async {
      final game = buildDevelopmentPanelGoldenGame();

      await _openToInteractiveMs(tester, game);

      await tester.pumpWidget(
        buildAppShell(
          child: const SizedBox.shrink(),
          overrides: _developmentOverrides(game),
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
        ),
      );
      await tester.pump();

      final warmMs = await _openToInteractiveMs(tester, game);
      expect(warmMs, greaterThan(0));
    },
  );

  test(
    'read-model cold open path median stays bounded on golden fixture (Refs #4687)',
    () {
      const iterations = 20;
      final fixture = DevelopmentPanelOpenPathTimingFixture.build();
      final coldMicros = developmentPanelOpenPathTimeMicrosMedian(
        () {
          resolveDevelopmentPanelConnectivity(
            game: fixture.game,
            tileMapByRegion: fixture.mapData.tileMapByRegion,
            topology: fixture.mapData.combinedTopology,
            humanPlayerId: fixture.humanPlayerId,
          );
        },
        iterations: iterations,
      );
      // Debug CI upper bound for connectivity-only cold path (not the 1s UI gate).
      expect(
        coldMicros,
        lessThan(500000),
        reason: 'connectivity cold median ${coldMicros}µs over $iterations iterations',
      );
    },
  );
}
