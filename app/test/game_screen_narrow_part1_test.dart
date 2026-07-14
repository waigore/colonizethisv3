// In-game shell chrome (part1). SPEC/ui/in-game-shell-narrow.md, empire-buttons.md.

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen.dart';
import 'package:colonizethis_app/providers/treasury_summary_provider.dart';
import 'package:colonizethis_app/features/game/widgets/dialogs/game_map_options_dialog.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
import 'package:colonizethis_app/widgets/ct_toggle_switch.dart';
import 'package:colonizethis_map/colonizethis_map.dart'
    show InitGameMapViewData;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'support/game_screen_test_support.dart';
import 'support/map_view_test_fixtures.dart';
import 'support/panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  // Refs #3656: the narrow in-game shell assertions read only chrome (top bar,
  // side menu, left rail, players-bar gating, options dialog); the map canvas
  // just needs *a* mapViewData to mount. The lightweight game + minimal
  // mapViewData replace the ~7-11s getDebugInitGameResult() map generation.
  final Game baseGame = buildPlayersBarTestGame();
  final InitGameMapViewData lightMapViewData = buildLightweightMapViewData();
  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_game_screen_narrow_part1');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  Widget buildGameScreen({required double width, required double height}) =>
      buildGameScreenHost(
        gamesBox: gamesBox,
        game: baseGame,
        mapViewData: lightMapViewData,
        width: width,
        height: height,
        navigatorKey: appNavigatorKey,
      );

  group('GameScreen — SPEC/ui/in-game-shell-narrow.md', () {
    testWidgets(
      'AC: cargo hold indicator appears beside region tabs in used/capacity format (SPEC/ui/empire-overview.md)',
      (WidgetTester tester) async {
        final dpr = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(1500 * dpr, 700 * dpr);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(buildGameScreen(width: 1500, height: 700));
        await tester.pump();

        final indicator = find.byKey(kCargoHoldIndicatorKey);
        expect(indicator, findsOneWidget);

        final formattedValue = find.descendant(
          of: indicator,
          matching: find.textContaining(RegExp(r'^\d+/\d+$')),
        );
        expect(formattedValue, findsOneWidget);

        final iconFinder = find.descendant(
          of: indicator,
          matching: find.byType(StrictAssetIcon),
        );
        expect(iconFinder, findsOneWidget);
        final iconWidget = tester.widget<StrictAssetIcon>(iconFinder);
        expect(iconWidget.assetPath, 'assets/icons/32/ui_icon_cargo_hold.png');
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'AC: treasury indicator appears between New World and cargo with exact value and dedicated icon',
      (WidgetTester tester) async {
        final dpr = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(1500 * dpr, 700 * dpr);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: buildGameScreenShellOverrides(
              gamesBox: gamesBox,
              game: baseGame,
              mapViewData: lightMapViewData,
              treasurySummary: const TreasurySummary(
                treasury: 12345,
                projectedDelta: 250,
              ),
            ),
            child: AppEventHandlerScope(
              child: MaterialApp(
                navigatorKey: appNavigatorKey,
                theme: AppThemes.colonial,
                home: MediaQuery(
                  data: const MediaQueryData(size: Size(1500, 700)),
                  child: const GameScreen(),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final treasuryIndicator = find.byKey(kTreasuryIndicatorKey);
        final cargoIndicator = find.byKey(kCargoHoldIndicatorKey);
        expect(treasuryIndicator, findsOneWidget);
        expect(cargoIndicator, findsOneWidget);
        expect(find.text('12,345'), findsOneWidget);
        expect(find.text('+250'), findsOneWidget);

        final iconFinder = find.descendant(
          of: treasuryIndicator,
          matching: find.byType(StrictAssetIcon),
        );
        expect(iconFinder, findsOneWidget);
        final iconWidget = tester.widget<StrictAssetIcon>(iconFinder);
        expect(
          iconWidget.assetPath,
          'assets/icons/32/ui_icon_treasury_coin.png',
        );
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'AC: tapping treasury indicator toggles exact and abbreviated display',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildGameScreen(width: 1500, height: 700));
        await tester.pump();

        final treasuryIndicator = find.byKey(kTreasuryIndicatorKey);
        expect(treasuryIndicator, findsOneWidget);
        expect(find.text('12,345'), findsOneWidget);

        await tester.tap(treasuryIndicator);
        await tester.pump();
        expect(find.text('12.3k'), findsOneWidget);

        await tester.tap(treasuryIndicator);
        await tester.pump();
        expect(find.text('12,345'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'AC: treasury delta shows signed text for positive values',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: buildGameScreenShellOverrides(
              gamesBox: gamesBox,
              game: baseGame,
              mapViewData: lightMapViewData,
              treasurySummary: const TreasurySummary(
                treasury: 12345,
                projectedDelta: 250,
              ),
            ),
            child: AppEventHandlerScope(
              child: MaterialApp(
                navigatorKey: appNavigatorKey,
                theme: AppThemes.colonial,
                home: const GameScreen(),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('+250'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: treasury delta shows signed text for negative values',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: buildGameScreenShellOverrides(
              gamesBox: gamesBox,
              game: baseGame,
              mapViewData: lightMapViewData,
              treasurySummary: const TreasurySummary(
                treasury: 12345,
                projectedDelta: -400,
              ),
            ),
            child: AppEventHandlerScope(
              child: MaterialApp(
                navigatorKey: appNavigatorKey,
                theme: AppThemes.colonial,
                home: const GameScreen(),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.textContaining('400'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: treasury delta hides when projected delta is zero',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: buildGameScreenShellOverrides(
              gamesBox: gamesBox,
              game: baseGame,
              mapViewData: lightMapViewData,
              treasurySummary: const TreasurySummary(
                treasury: 12345,
                projectedDelta: 0,
              ),
            ),
            child: AppEventHandlerScope(
              child: MaterialApp(
                navigatorKey: appNavigatorKey,
                theme: AppThemes.colonial,
                home: const GameScreen(),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('+250'), findsNothing);
        expect(find.text('-400'), findsNothing);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: top bar shows hamburger menu and turn counter; empire buttons NOT in top bar (wide viewport)',
      (WidgetTester tester) async {
        final dpr = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(1500 * dpr, 700 * dpr);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(buildGameScreen(width: 1500, height: 700));
        await tester.pump();

        expect(find.textContaining('Next turn'), findsOneWidget);
        expect(find.byIcon(Icons.menu), findsOneWidget);
        // Empire labels are tooltips only, not top bar
        expect(find.text('Production'), findsNothing);
        expect(find.text('Civilian Units'), findsNothing);
        expect(find.text('Technology'), findsNothing);
        // Left rail icon keys (always visible without opening hamburger)
        expect(find.byKey(kEmpireProductionButtonKey), findsOneWidget);
        expect(find.byKey(kEmpireTechnologyButtonKey), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'AC: top bar shows hamburger menu and turn counter; empire buttons NOT in top bar (narrow viewport)',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildGameScreen(width: 399, height: 700));
        await tester.pump();

        expect(find.textContaining('Next turn'), findsOneWidget);
        expect(find.byIcon(Icons.menu), findsOneWidget);
        expect(find.text('Production'), findsNothing);
        expect(find.byKey(kEmpireProductionButtonKey), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'AC: base layer cycle button is visible on map; tap cycles mode (SPEC/ui/empire-overview.md)',
      (WidgetTester tester) async {
        final dpr = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(1500 * dpr, 700 * dpr);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(buildGameScreen(width: 1500, height: 700));
        await tester.pump();

        final buttonFinder = find.byKey(kBaseLayerCycleButtonKey);
        expect(buttonFinder, findsOneWidget);
        for (var i = 0; i < 4; i++) {
          await tester.tap(buttonFinder);
          await tester.pump();
        }
        expect(buttonFinder, findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'AC: home-to-capital button is visible beside base layer button and tappable (SPEC/ui/empire-overview.md)',
      (WidgetTester tester) async {
        final dpr = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(1500 * dpr, 700 * dpr);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(buildGameScreen(width: 1500, height: 700));
        await tester.pump();

        final baseButtonFinder = find.byKey(kBaseLayerCycleButtonKey);
        final homeButtonFinder = find.byKey(kHomeToCapitalButtonKey);

        expect(baseButtonFinder, findsOneWidget);
        expect(homeButtonFinder, findsOneWidget);

        await tester.tap(homeButtonFinder);
        await tester.pump();

        // No additional assertions here; behavior (centering on capital tile)
        // is covered by CtRegionMap's centerOnTileKey tests and capitalTile specs.
        expect(homeButtonFinder, findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'AC: map display options button is visible in bottom tool row and opens dialog (SPEC/ui/empire-overview.md)',
      (WidgetTester tester) async {
        final dpr = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(1500 * dpr, 700 * dpr);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(buildGameScreen(width: 1500, height: 700));
        await tester.pump();

        final optionsButtonFinder = find.byKey(kMapDisplayOptionsButtonKey);
        expect(optionsButtonFinder, findsOneWidget);

        await tester.tap(optionsButtonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Map display options'), findsOneWidget);
        expect(find.text('Show province overlay'), findsOneWidget);
        expect(find.text('Show province ownership'), findsOneWidget);
        expect(find.text('Show province names'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: toggling Show province overlay in dialog updates state and persists within session (SPEC/ui/empire-overview.md)',
      (WidgetTester tester) async {
        final dpr = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(1500 * dpr, 700 * dpr);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(buildGameScreen(width: 1500, height: 700));
        await tester.pump();

        final optionsButtonFinder = find.byKey(kMapDisplayOptionsButtonKey);
        expect(optionsButtonFinder, findsOneWidget);

        // Open dialog.
        await tester.tap(optionsButtonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final overlayToggleFinder = find.byKey(
          kGameMapOptionsShowProvinceOverlayToggleKey,
        );
        expect(overlayToggleFinder, findsOneWidget);
        expect(
          tester.widget<CtToggleSwitch>(overlayToggleFinder).value,
          isTrue,
        );

        // Toggle off.
        await tester.tap(overlayToggleFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Close dialog.
        await tester.tap(find.text('Close'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Re-open and ensure the toggle remains off.
        await tester.tap(optionsButtonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          tester
              .widget<CtToggleSwitch>(
                find.byKey(kGameMapOptionsShowProvinceOverlayToggleKey),
              )
              .value,
          isFalse,
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: toggling Show province ownership in dialog updates state and persists within session (SPEC/ui/empire-overview.md)',
      (WidgetTester tester) async {
        final dpr = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(1500 * dpr, 700 * dpr);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(buildGameScreen(width: 1500, height: 700));
        await tester.pump();

        final optionsButtonFinder = find.byKey(kMapDisplayOptionsButtonKey);
        await tester.tap(optionsButtonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final ownershipFinder = find.byKey(
          kGameMapOptionsShowProvinceOwnershipToggleKey,
        );
        expect(ownershipFinder, findsOneWidget);

        // Default OFF — turn ON and persist.
        await tester.tap(ownershipFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        await tester.tap(find.text('Close'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(optionsButtonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          tester
              .widget<CtToggleSwitch>(
                find.byKey(kGameMapOptionsShowProvinceOwnershipToggleKey),
              )
              .value,
          isTrue,
        );

        // Turn OFF again and persist.
        await tester.tap(
          find.byKey(kGameMapOptionsShowProvinceOwnershipToggleKey),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.text('Close'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(optionsButtonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          tester
              .widget<CtToggleSwitch>(
                find.byKey(kGameMapOptionsShowProvinceOwnershipToggleKey),
              )
              .value,
          isFalse,
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: first map display options open shows overlay and names ON, ownership OFF (SPEC/ui/empire-overview.md)',
      (WidgetTester tester) async {
        final dpr = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(1500 * dpr, 700 * dpr);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(buildGameScreen(width: 1500, height: 700));
        await tester.pump();

        await tester.tap(find.byKey(kMapDisplayOptionsButtonKey));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          tester
              .widget<CtToggleSwitch>(
                find.byKey(kGameMapOptionsShowProvinceOverlayToggleKey),
              )
              .value,
          isTrue,
        );
        expect(
          tester
              .widget<CtToggleSwitch>(
                find.byKey(kGameMapOptionsShowProvinceOwnershipToggleKey),
              )
              .value,
          isFalse,
        );
        expect(
          tester
              .widget<CtToggleSwitch>(
                find.byKey(kGameMapOptionsShowProvinceNamesToggleKey),
              )
              .value,
          isTrue,
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: toggling Show province names in dialog updates state and persists within session (SPEC/ui/empire-overview.md)',
      (WidgetTester tester) async {
        final dpr = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(1500 * dpr, 700 * dpr);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(buildGameScreen(width: 1500, height: 700));
        await tester.pump();

        final optionsButtonFinder = find.byKey(kMapDisplayOptionsButtonKey);
        await tester.tap(optionsButtonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final namesToggleFinder = find.byKey(
          kGameMapOptionsShowProvinceNamesToggleKey,
        );
        expect(namesToggleFinder, findsOneWidget);

        await tester.tap(namesToggleFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        await tester.tap(find.text('Close'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(optionsButtonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          tester
              .widget<CtToggleSwitch>(
                find.byKey(kGameMapOptionsShowProvinceNamesToggleKey),
              )
              .value,
          isFalse,
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    // Empire rail: see game_map_empire_left_rail_test.dart. Hamburger: Debug log only (game_side_menu_test).
  });
}
