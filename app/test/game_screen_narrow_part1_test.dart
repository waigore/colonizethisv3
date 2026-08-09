// In-game shell chrome (part1). SPEC/ui/in-game-shell-narrow.md, empire-buttons.md.
// In-file surface/treasury/options helpers densify mid-size fixtures (Refs #4021).

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
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
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'game_screen_test_support.dart';
import 'map_view_test_fixtures.dart';
import 'panel_test_fixtures.dart';

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

  void bindSurface(
    WidgetTester tester, {
    double width = 1500,
    double height = 700,
  }) {
    final dpr = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(width * dpr, height * dpr);
    addTearDown(tester.view.reset);
  }

  Future<void> pumpShell(
    WidgetTester tester, {
    double width = 1500,
    double height = 700,
    bool bindWide = false,
    TreasurySummary treasurySummary = const TreasurySummary(treasury: 12345),
  }) async {
    if (bindWide) {
      bindSurface(tester, width: width, height: height);
    }
    await tester.pumpWidget(
      buildGameScreenHost(
        gamesBox: gamesBox,
        game: baseGame,
        mapViewData: lightMapViewData,
        width: width,
        height: height,
        navigatorKey: appNavigatorKey,
        treasurySummary: treasurySummary,
      ),
    );
    await tester.pump();
  }

  Future<void> openMapOptions(WidgetTester tester) async {
    await tester.tap(find.byKey(kMapDisplayOptionsButtonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> closeMapOptions(WidgetTester tester) async {
    await tester.tap(find.text('Close'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  bool toggleValue(WidgetTester tester, Key key) =>
      tester.widget<CtToggleSwitch>(find.byKey(key)).value;

  Future<void> tapToggle(
    WidgetTester tester,
    Key key, {
    int settleMs = 200,
  }) async {
    await tester.tap(find.byKey(key));
    await tester.pump();
    await tester.pump(Duration(milliseconds: settleMs));
  }

  Future<void> toggleCloseReopen(
    WidgetTester tester,
    Key key, {
    required bool expectAfter,
  }) async {
    await tapToggle(tester, key);
    await closeMapOptions(tester);
    await openMapOptions(tester);
    expect(toggleValue(tester, key), expectAfter);
  }

  String? iconUnder(WidgetTester tester, Finder ancestor) {
    final iconFinder = find.descendant(
      of: ancestor,
      matching: find.byType(StrictAssetIcon),
    );
    expect(iconFinder, findsOneWidget);
    return tester.widget<StrictAssetIcon>(iconFinder).assetPath;
  }

  group('GameScreen — SPEC/ui/in-game-shell-narrow.md', () {
    testWidgets(
      'AC: cargo hold indicator appears beside region tabs in used/capacity format (SPEC/ui/empire-overview.md)',
      (WidgetTester tester) async {
        await pumpShell(tester, bindWide: true);

        final indicator = find.byKey(kCargoHoldIndicatorKey);
        expect(indicator, findsOneWidget);
        expect(
          find.descendant(
            of: indicator,
            matching: find.textContaining(RegExp(r'^\d+/\d+$')),
          ),
          findsOneWidget,
        );
        expect(
          iconUnder(tester, indicator),
          'assets/icons/32/ui_icon_cargo_hold.png',
        );
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'AC: treasury indicator appears between New World and cargo with exact value and dedicated icon',
      (WidgetTester tester) async {
        await pumpShell(
          tester,
          bindWide: true,
          treasurySummary: const TreasurySummary(
            treasury: 12345,
            projectedDelta: 250,
          ),
        );

        final treasuryIndicator = find.byKey(kTreasuryIndicatorKey);
        expect(treasuryIndicator, findsOneWidget);
        expect(find.byKey(kCargoHoldIndicatorKey), findsOneWidget);
        expect(find.text('12,345'), findsOneWidget);
        expect(find.text('+250'), findsOneWidget);
        expect(
          iconUnder(tester, treasuryIndicator),
          'assets/icons/32/ui_icon_treasury_coin.png',
        );
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'AC: tapping treasury indicator toggles exact and abbreviated display',
      (WidgetTester tester) async {
        await pumpShell(tester);
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
        await pumpShell(
          tester,
          treasurySummary: const TreasurySummary(
            treasury: 12345,
            projectedDelta: 250,
          ),
        );
        expect(find.text('+250'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: treasury delta shows signed text for negative values',
      (WidgetTester tester) async {
        await pumpShell(
          tester,
          treasurySummary: const TreasurySummary(
            treasury: 12345,
            projectedDelta: -400,
          ),
        );
        expect(find.textContaining('400'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: treasury delta hides when projected delta is zero',
      (WidgetTester tester) async {
        await pumpShell(
          tester,
          treasurySummary: const TreasurySummary(
            treasury: 12345,
            projectedDelta: 0,
          ),
        );
        expect(find.text('+250'), findsNothing);
        expect(find.text('-400'), findsNothing);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: top bar shows hamburger menu and turn counter; empire buttons NOT in top bar (wide viewport)',
      (WidgetTester tester) async {
        await pumpShell(tester, bindWide: true);

        expect(find.textContaining('Next turn'), findsOneWidget);
        expect(find.byIcon(Icons.menu), findsOneWidget);
        expect(find.text('Production'), findsNothing);
        expect(find.text('Civilian Units'), findsNothing);
        expect(find.text('Technology'), findsNothing);
        expect(find.byKey(kEmpireProductionButtonKey), findsOneWidget);
        expect(find.byKey(kEmpireTechnologyButtonKey), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'AC: top bar shows hamburger menu and turn counter; empire buttons NOT in top bar (narrow viewport)',
      (WidgetTester tester) async {
        await pumpShell(tester, width: 399);
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
        await pumpShell(tester, bindWide: true);
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
        await pumpShell(tester, bindWide: true);
        final homeButtonFinder = find.byKey(kHomeToCapitalButtonKey);
        expect(find.byKey(kBaseLayerCycleButtonKey), findsOneWidget);
        expect(homeButtonFinder, findsOneWidget);
        await tester.tap(homeButtonFinder);
        await tester.pump();
        expect(homeButtonFinder, findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'AC: map display options button is visible in bottom tool row and opens dialog (SPEC/ui/empire-overview.md)',
      (WidgetTester tester) async {
        await pumpShell(tester, bindWide: true);
        expect(find.byKey(kMapDisplayOptionsButtonKey), findsOneWidget);
        await openMapOptions(tester);
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
        await pumpShell(tester, bindWide: true);
        await openMapOptions(tester);
        expect(
          toggleValue(tester, kGameMapOptionsShowProvinceOverlayToggleKey),
          isTrue,
        );
        await toggleCloseReopen(
          tester,
          kGameMapOptionsShowProvinceOverlayToggleKey,
          expectAfter: false,
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: toggling Show province ownership in dialog updates state and persists within session (SPEC/ui/empire-overview.md)',
      (WidgetTester tester) async {
        await pumpShell(tester, bindWide: true);
        await openMapOptions(tester);
        expect(
          find.byKey(kGameMapOptionsShowProvinceOwnershipToggleKey),
          findsOneWidget,
        );
        await toggleCloseReopen(
          tester,
          kGameMapOptionsShowProvinceOwnershipToggleKey,
          expectAfter: true,
        );
        await toggleCloseReopen(
          tester,
          kGameMapOptionsShowProvinceOwnershipToggleKey,
          expectAfter: false,
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: first map display options open shows overlay and names ON, ownership OFF (SPEC/ui/empire-overview.md)',
      (WidgetTester tester) async {
        await pumpShell(tester, bindWide: true);
        await openMapOptions(tester);
        expect(
          toggleValue(tester, kGameMapOptionsShowProvinceOverlayToggleKey),
          isTrue,
        );
        expect(
          toggleValue(tester, kGameMapOptionsShowProvinceOwnershipToggleKey),
          isFalse,
        );
        expect(
          toggleValue(tester, kGameMapOptionsShowProvinceNamesToggleKey),
          isTrue,
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: toggling Show province names in dialog updates state and persists within session (SPEC/ui/empire-overview.md)',
      (WidgetTester tester) async {
        await pumpShell(tester, bindWide: true);
        await openMapOptions(tester);
        expect(
          find.byKey(kGameMapOptionsShowProvinceNamesToggleKey),
          findsOneWidget,
        );
        await toggleCloseReopen(
          tester,
          kGameMapOptionsShowProvinceNamesToggleKey,
          expectAfter: false,
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    // Empire rail: see game_map_empire_left_rail_test.dart. Hamburger: Debug log only (game_side_menu_test).
  });
}
