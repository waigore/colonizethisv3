// Pin the 320 dp minimum-viewport contract for the in-game `GameScreen`
// shell composite — extending the existing screen/panel/dialog/overlay
// pin files (`mobile_320dp_min_viewport_test.dart`,
// `panels_320dp_min_viewport_test.dart`,
// `dialogs_320dp_min_viewport_test.dart`,
// `unit_panels_320dp_min_viewport_test.dart`,
// `trade_screen_320dp_min_viewport_test.dart`) to the parent in-game
// shell screen the empire-overview chrome lives on
// (SPEC/ui/empire-overview.md, SPEC/ui/in-game-shell-narrow.md).
//
// Pumps the live `GameScreen` widget (via the same Riverpod fixture
// `game_screen_narrow_test.dart` uses) at exactly
// `kMinViewportWidth × 640` (320 × 640 dp) under
// `AppThemes.editorialMonocle` and asserts:
//
//  * The live `GameScreen` mounts end-to-end and the narrow chrome
//    surfaces every key control:
//    - the hamburger menu icon (`Icons.menu`) per
//      `SPEC/ui/in-game-shell-narrow.md` § Top bar,
//    - the "Next turn" label (turn counter) per the same § Top bar,
//    - the left-rail empire buttons keyed by
//      `kEmpireProductionButtonKey` / `kEmpireTechnologyButtonKey`
//      per `SPEC/ui/empire-overview.md` § Left rail.
//  * The narrow in-game chrome measurements from
//    `SPEC/ui/mobile-adaptation.md` § In-game shell: at < 600 dp the
//    left-rail empire buttons render at 26 × 26 dp (Req 8) and the
//    bottom-left corner-control buttons render at 24 × 24 dp (Req 9),
//    while the 1024 × 768 wide control renders them at the default
//    36 × 36 dp / 32 × 32 dp so the breakpoint comparator direction is
//    pinned from both sides.
//  * The wide-only floating `GameMapPlayersBar` (keyed by
//    `kGameMapPlayersBarKey`) is NOT present at narrow widths, pinning
//    Refs #2870 Requirement 6 ("Players bar hidden" below the shell
//    breakpoint).
//  * A wide negative control at 1024 × 768 dp pumps without exception
//    against the same fixture so a regression in the host overflow
//    contract upstream of the shell itself would be caught, mirroring
//    the contrast pattern in the sibling 320 dp pin files. At wide
//    widths `GameMapPlayersBar` reappears so the contrast also pins the
//    Req 6 narrow-only suppression.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin) and
// § 4 In-game shell narrow measurement table (left rail 26 × 26 dp,
// corner controls 24 × 24 dp).
// SPEC: `SPEC/ui/empire-overview.md` (left-rail empire buttons + top bar).
// SPEC: `SPEC/ui/in-game-shell-narrow.md` § Top bar.
// Refs #2870 S10 (no horizontal overflow at 320 dp on every covered
// screen) + Req 6 (players bar hidden at < 600 dp) + Req 8/9 (narrow
// left-rail 26 × 26 dp / corner-control 24 × 24 dp measurements, S3).

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/features/game/flame/game_map_corner_controls.dart';
import 'package:colonizethis_app/features/game/flame/game_map_empire_left_rail.dart';
import 'package:colonizethis_app/features/game/flame/game_screen.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/home_fleet_cargo_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_app/providers/treasury_summary_provider.dart';
import 'package:colonizethis_map/colonizethis_map.dart' show InitGameMapViewData;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'support/map_view_test_fixtures.dart';
import 'support/panel_test_fixtures.dart';

/// Minimum supported viewport dimensions for SPEC/ui/mobile-adaptation.md
/// § 7. Width matches [kMinViewportWidth]; height (640 dp) mirrors the
/// existing sibling screen-level pin files
/// (`mobile_320dp_min_viewport_test.dart`,
/// `panels_320dp_min_viewport_test.dart`).
const Size _kMinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel — comfortably above every per-screen
/// breakpoint so the same `GameScreen` renders its wide layout without
/// any narrow concessions. Mirrors the contract used by the sibling
/// 320 dp pin files; the contrast keeps the 320 dp positive pin
/// meaningful by catching regressions in the host overflow detection
/// itself, and pins Refs #2870 Requirement 6 from the wide side (the
/// players bar reappears at ≥ 600 dp).
const Size _kWideRegressionViewport = Size(1024, 768);

void main() {
  suppressLogsForTests();

  // Refs #3656: this min-viewport pin asserts only narrow/wide shell chrome
  // (top bar, left rail, players-bar gating, no overflow); the map canvas just
  // needs *a* mapViewData to mount. The lightweight game + minimal mapViewData
  // replace the ~7-11s getDebugInitGameResult() map generation.
  final Game baseGame = buildPlayersBarTestGame();
  final InitGameMapViewData lightMapViewData = buildLightweightMapViewData();
  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_game_screen_320dp');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  // Mirrors `gameShellOverrides` in `game_screen_narrow_test.dart` so the
  // 320 dp pin renders the same in-game shell composite the existing
  // narrow chrome tests exercise at 399 dp / 1500 dp. Reusing the live
  // Riverpod fixture (not a hand-built mock) is what makes this an
  // SPEC § 7 "every covered screen" pin rather than a chrome-only smoke
  // test.
  gameShellOverrides({
    required Game game,
    required InitGameMapViewData? mapViewData,
    TreasurySummary treasurySummary = const TreasurySummary(treasury: 12345),
  }) => [
    gamesBoxProvider.overrideWith((ref) => gamesBox),
    gameServiceProvider.overrideWith(
      (ref) => GameService(gamesBox, GameSaveAdapter()),
    ),
    currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
    currentOrdersProvider.overrideWith(
      () => CurrentOrdersNotifier(const Orders()),
    ),
    mapViewDataProvider.overrideWith((ref) => mapViewData),
    gameIdsWithIntroShownProvider.overrideWith(
      () => GameIdsWithIntroShownNotifier({game.id}),
    ),
    appEventBusProvider.overrideWith((ref) {
      final bus = AppEventBus.create();
      ref.onDispose(bus.dispose);
      return bus;
    }),
    homeFleetCargoSummaryProvider.overrideWith(
      (ref) => const HomeFleetCargoSummary(used: 0, capacity: 0),
    ),
    treasurySummaryProvider.overrideWith((ref) => treasurySummary),
  ];

  /// Pumps the live `GameScreen` at [size] under the running
  /// editorial-monocle theme. Sets the surface size (so the binding's
  /// render flex math sees the minimum viewport) and overrides
  /// MediaQuery so screen code that reads
  /// `MediaQuery.sizeOf(context).width` resolves to the same value —
  /// the pattern used by the sibling 320 dp pin files. Uses a single
  /// `tester.pump()` (no `pumpAndSettle`) because the in-game shell
  /// keeps recurring Flame / animation tickers running indefinitely;
  /// the SPEC § 7 contract under test is the first-frame layout, which
  /// is fully resolved after a single pump.
  Future<void> pumpGameScreenAtSize(
    WidgetTester tester, {
    required Size size,
  }) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      ProviderScope(
        overrides: gameShellOverrides(
          game: baseGame,
          mapViewData: lightMapViewData,
        ),
        child: AppEventHandlerScope(
          child: MaterialApp(
            navigatorKey: appNavigatorKey,
            theme: AppThemes.editorialMonocle,
            home: MediaQuery(
              data: MediaQueryData(size: size),
              child: const GameScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — GameScreen @ 320 dp (Refs #2870 '
    'S10 + Req 6)',
    () {
      testWidgets(
        'AC (positive) GameScreen @ 320×640: narrow top bar + '
        'left-rail chrome renders end-to-end without overflow, '
        'players bar is hidden (Req 6)',
        (WidgetTester tester) async {
          await pumpGameScreenAtSize(tester, size: _kMinViewport);

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: at kMinViewportWidth '
                '(320 dp) the live GameScreen composite must pump without '
                'a RenderFlex overflow exception. The narrow GameTopBar '
                'layout (hamburger + trailing Next-turn button only) '
                'closes the prior ~116 px top-bar overflow gap.',
          );

          expect(
            find.byType(GameScreen),
            findsOneWidget,
            reason:
                'GameScreen must mount end-to-end so the 320 dp pin '
                'actually exercises the live in-game shell composite '
                'rather than the test fixture failing earlier in the '
                'pumpWidget chain.',
          );

          expect(
            find.byIcon(Icons.menu),
            findsOneWidget,
            reason:
                'SPEC/ui/in-game-shell-narrow.md § Top bar: the '
                'hamburger menu icon must remain visible at the '
                'minimum supported viewport (320 dp); the narrow top '
                'bar shows only the hamburger and turn counter.',
          );

          expect(
            find.textContaining('Next turn'),
            findsOneWidget,
            reason:
                'SPEC/ui/in-game-shell-narrow.md § Top bar: the turn '
                'counter (rendered through the "Next turn" label) '
                'must remain visible at the minimum supported '
                'viewport (320 dp) alongside the hamburger control.',
          );

          expect(
            find.byKey(kEmpireProductionButtonKey),
            findsOneWidget,
            reason:
                'SPEC/ui/empire-overview.md § Left rail: the empire '
                'production rail button must remain mounted at the '
                'minimum supported viewport (320 dp) so the narrow '
                'left rail (Refs #2870 Req 8, 26 × 26 dp) still '
                'exposes empire navigation.',
          );

          expect(
            find.byKey(kEmpireTechnologyButtonKey),
            findsOneWidget,
            reason:
                'SPEC/ui/empire-overview.md § Left rail: the empire '
                'technology rail button must remain mounted at the '
                'minimum supported viewport (320 dp), pairing with '
                'the production button above.',
          );

          expect(
            find.byKey(kGameMapPlayersBarKey),
            findsNothing,
            reason:
                'Refs #2870 Requirement 6 (players bar hidden at '
                '< 600 dp): the wide-only `GameMapPlayersBar` floating '
                'chip column must NOT be present in the widget tree '
                'at the minimum supported viewport (320 dp). The '
                'narrow shell suppresses it via '
                '`if (!isNarrow && widget.game.victory == null)` in '
                '`game_map_area_build.dart`.',
          );
        },
        timeout: const Timeout(Duration(seconds: 20)),
      );

      testWidgets(
        'AC (positive) GameScreen @ 320×640: left-rail empire buttons '
        'render at 26 × 26 dp and corner-control buttons at 24 × 24 dp '
        '(Refs #2870 Req 8 / 9, S3)',
        (WidgetTester tester) async {
          await pumpGameScreenAtSize(tester, size: _kMinViewport);

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 4 In-game shell: the '
                'narrow chrome must lay out without exception before its '
                'measurements are asserted.',
          );

          expect(
            tester.getSize(find.byKey(kEmpireProductionButtonKey)),
            const Size(
              GameMapEmpireLeftRail.narrowButtonSize,
              GameMapEmpireLeftRail.narrowButtonSize,
            ),
            reason:
                'Refs #2870 Req 8 / SPEC/ui/mobile-adaptation.md § 4 '
                'In-game shell: below the 600 dp shell breakpoint each '
                'left-rail empire button compresses to '
                '${GameMapEmpireLeftRail.narrowButtonSize} × '
                '${GameMapEmpireLeftRail.narrowButtonSize} dp '
                '(mockup `.empire-btn @media (max-width:600px)`).',
          );

          expect(
            tester.getSize(find.byKey(kBaseLayerCycleButtonKey)),
            const Size(
              GameMapCornerControls.narrowButtonSize,
              GameMapCornerControls.narrowButtonSize,
            ),
            reason:
                'Refs #2870 Req 9 / SPEC/ui/mobile-adaptation.md § 4 '
                'In-game shell: below the 600 dp shell breakpoint each '
                'bottom-left corner-control button compresses to '
                '${GameMapCornerControls.narrowButtonSize} × '
                '${GameMapCornerControls.narrowButtonSize} dp '
                '(mockup `.corner-btn @media (max-width:600px)`).',
          );
        },
        timeout: const Timeout(Duration(seconds: 20)),
      );

      testWidgets(
        'Negative control: GameScreen @ 1024×768 also pumps without '
        'exception, left-rail chrome still renders, players bar '
        'reappears at wide widths (Req 6 wide-side contrast)',
        (WidgetTester tester) async {
          await pumpGameScreenAtSize(
            tester,
            size: _kWideRegressionViewport,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'Regression sentinel: the same GameScreen fixture '
                'must pump without exception at a comfortably wide '
                'viewport (1024 × 768). Without this contrast a '
                'future refactor that broke the host overflow contract '
                'upstream of GameScreen itself would silently invalidate '
                'the 320 dp positive pin above.',
          );

          expect(find.byType(GameScreen), findsOneWidget);

          expect(
            find.byKey(kEmpireProductionButtonKey),
            findsOneWidget,
            reason:
                'Wide layout must still mount the empire production '
                'rail button — the contrast keeps the narrow pin '
                'honest about exercising the same shell composite.',
          );

          expect(
            tester.getSize(find.byKey(kEmpireProductionButtonKey)),
            const Size(
              GameMapEmpireLeftRail.buttonSize,
              GameMapEmpireLeftRail.buttonSize,
            ),
            reason:
                'Refs #2870 Req 8 wide-side contrast: at viewport width '
                '≥ the 600 dp shell breakpoint each left-rail empire '
                'button renders at the default '
                '${GameMapEmpireLeftRail.buttonSize} × '
                '${GameMapEmpireLeftRail.buttonSize} dp, so the narrow '
                '26 × 26 dp assertion above pins the breakpoint '
                'comparator direction rather than a static size.',
          );

          expect(
            tester.getSize(find.byKey(kBaseLayerCycleButtonKey)),
            const Size(
              GameMapCornerControls.buttonSize,
              GameMapCornerControls.buttonSize,
            ),
            reason:
                'Refs #2870 Req 9 wide-side contrast: at viewport width '
                '≥ the 600 dp shell breakpoint each corner-control '
                'button renders at the default '
                '${GameMapCornerControls.buttonSize} × '
                '${GameMapCornerControls.buttonSize} dp, keeping the '
                'narrow 24 × 24 dp assertion meaningful.',
          );

          expect(
            find.byKey(kGameMapPlayersBarKey),
            findsOneWidget,
            reason:
                'Refs #2870 Requirement 6 wide-side contrast: at '
                'viewport width ≥ shell breakpoint (600 dp) the '
                '`GameMapPlayersBar` floating chip column reappears '
                'in the widget tree (per the `!isNarrow` gate in '
                '`game_map_area_build.dart`). The wide control '
                'pinning its presence is what keeps the narrow '
                '`findsNothing` assertion above meaningful.',
          );
        },
        timeout: const Timeout(Duration(seconds: 20)),
      );
    },
  );
}
