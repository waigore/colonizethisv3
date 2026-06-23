// Pin the 320 dp minimum-viewport contract for the in-game
// `ProductionScreen` (`UiScreenIds.productionScreen`) full-screen feature
// surface — extending the existing screen-, panel-, dialog-, and
// unit-panel-level pins (`mobile_320dp_min_viewport_test.dart`,
// `panels_320dp_min_viewport_test.dart`,
// `dialogs_320dp_min_viewport_test.dart`,
// `unit_panels_320dp_min_viewport_test.dart`,
// `trade_screen_320dp_min_viewport_test.dart`,
// `diplomacy_screen_320dp_min_viewport_test.dart`,
// `technology_screen_320dp_min_viewport_test.dart`) to the in-game
// production route opened from the empire shell.
//
// `ProductionScreen` mounts `CtGameFeatureScreenShell` with the dark
// editorial-monocle `CtTopBar` (back chevron + literal `Map` label + 18 ×
// 18 px production icon + literal title `Production`, 36 dp height)
// above an observe-mode-aware body. At `kMinViewportWidth` (320 dp) the
// available width collapses to 320 dp; the chrome and the
// `ProductionPanel` body (already pinned in
// `panels_320dp_min_viewport_test.dart`) must still lay out together
// without `RenderFlex` overflow per `SPEC/ui/mobile-adaptation.md` § 7
// and the screen spec (`SPEC/ui/production-panel.md` § Top bar,
// § Layout, and § States and variants).
//
// Each test asserts:
//
//  * `WidgetTester.takeException()` is `null` so no `RenderFlex` overflow
//    exception (which Flutter surfaces via `FlutterError.onError`)
//    escapes the framework — the contract every other
//    `*_320dp_min_viewport_test.dart` file relies on.
//  * The dark `ProductionScreen.topBarKey` resolves to a `CtTopBar`
//    whose literal title `Production` and back label `Map` both render
//    so the layout actually exercises the production chrome at 320 dp
//    rather than no-op'ing on an off-screen widget.
//  * For the default (non-observe) path: the `ProductionPanel` body
//    mounts and both `Available` and `Allocation` section labels render
//    inside the narrow `_ProductionPanelNarrowLayout` (`<
//    kNarrowBreakpoint` selected at 320 dp per
//    `SPEC/ui/production-panel.md` § Layout).
//  * For the global-observe path: `ObserveModeNotDefinedPanel` is
//    mounted with the literal `Production` title and the
//    `ProductionPanel` body is absent.
//  * A wide negative control at 1024 × 768 dp pumps without exception
//    against the same fixture so a regression in the overflow contract
//    upstream of `ProductionScreen` itself would still surface.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// SPEC: `SPEC/ui/production-panel.md` § Top bar, § Layout, and
// § States and variants.
// Refs #2870 S10 (no horizontal overflow at 320 dp on every covered
// screen).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/flame/region_map_component.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/screens/production_screen.dart';
import 'package:colonizethis_app/features/game/shell_player_context.dart';
import 'package:colonizethis_app/features/game/widgets/observe_mode_not_defined_panel.dart';
import 'package:colonizethis_app/features/game/widgets/production_panel.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'production_panel_test_fixtures.dart';

/// Minimum supported viewport dimensions for SPEC/ui/mobile-adaptation.md
/// § 7. Width matches [kMinViewportWidth]; height (640 dp) mirrors the
/// existing screen-, panel-, and dialog-level pin files.
const Size _kMinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel — comfortably above every per-screen
/// breakpoint so the same screen renders its default chrome. Mirrors
/// the contract used by `mobile_320dp_min_viewport_test.dart`,
/// `panels_320dp_min_viewport_test.dart`,
/// `dialogs_320dp_min_viewport_test.dart`,
/// `unit_panels_320dp_min_viewport_test.dart`,
/// `trade_screen_320dp_min_viewport_test.dart`, and
/// `diplomacy_screen_320dp_min_viewport_test.dart`.
const Size _kWideRegressionViewport = Size(1024, 768);

/// Builds a [ShellPlayerContext] mirroring the global-observe branch
/// surfaced by `shellPlayerContextProvider`. Mirrors the helper used by
/// `trade_screen_320dp_min_viewport_test.dart` and
/// `diplomacy_screen_320dp_min_viewport_test.dart` so the observe pin
/// exercises the same path the in-app observe session takes.
ShellPlayerContext _globalObserveShellContext() {
  return const ShellPlayerContext(
    effectiveHumanPlayerId: null,
    viewingPlayerId: null,
    mapVisibilityMode: CtMapVisibilityMode.full,
    playerView: null,
    omniscientDetail: true,
    // `showPlayerChrome: false` flips `shellPanelsNotDefined(ref)` to
    // true so `ProductionScreen.bodyBuilder` short-circuits to the
    // `ObserveModeNotDefinedPanel` sentinel per
    // SPEC/ui/observe-mode.md and SPEC/ui/production-panel.md
    // § States and variants.
    showPlayerChrome: false,
    canMutateViaUi: false,
    debugCommandTargetPlayerId: null,
    inObservePhase: true,
    // ignore: avoid_hardcoded_strings_in_widgets
    observeBannerLabel: 'Observing: global',
    treasuryNotDefined: true,
    cargoNotDefined: true,
  );
}

/// Pumps the [ProductionScreen] at [size] under the running
/// editorial-monocle theme. Sets the surface size (so the binding's
/// render-flex math sees the minimum viewport) and overrides MediaQuery
/// so widget code that reads `MediaQuery.sizeOf(context).width`
/// resolves to the same value — the pattern already used by every
/// other `*_320dp_min_viewport_test.dart` file. Overrides
/// `currentGameProvider` (and optionally `shellPlayerContextProvider`
/// for the global-observe branch) so the shell renders without
/// touching Hive / GameService; passes an empty `panelTopologyOverride`
/// so the panel does not attempt to look up `GameService.getMapData`.
Future<void> _pumpProductionScreenAtSize(
  WidgetTester tester, {
  required Size size,
  required Game game,
  required Player player,
  bool globalObserve = false,
}) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
        if (globalObserve)
          shellPlayerContextProvider.overrideWithValue(
            _globalObserveShellContext(),
          ),
      ],
      child: MaterialApp(
        theme: AppThemes.editorialMonocle,
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: ProductionScreen(
            game: game,
            player: player,
            attachGameToUiListener: false,
            panelTopologyOverride: const MapTopology(),
            panelTileMapByRegionOverride: null,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  suppressLogsForTests();

  late Game game;
  late Player humanPlayer;

  setUpAll(() {
    // Refs #3656: ProductionScreen takes its `game`/`player` directly and is
    // pumped with `panelTopologyOverride: const MapTopology()` +
    // `panelTileMapByRegionOverride: null`, so it consumes no generated
    // map/topology data. The hand-built production fixture (a single human with
    // a full stockpile/worker pool) renders the same default-path
    // `ProductionPanel` Available/Allocation body the heavier panels pin uses,
    // replacing the ~11s procedural map generation.
    humanPlayer = productionPanelTestFullPlayer();
    game = productionPanelTestGameFor(humanPlayer);
  });

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — ProductionScreen (default) @ '
    '320 dp (Refs #2870 S10)',
    () {
      testWidgets(
        'AC (positive) ProductionScreen default @ 320×640: no RenderFlex '
        'overflow exception, dark CtTopBar (title `Production`, back '
        'label `Map`) + ProductionPanel narrow body (both `Available` '
        'and `Allocation` labels) all render',
        (WidgetTester tester) async {
          await _pumpProductionScreenAtSize(
            tester,
            size: _kMinViewport,
            game: game,
            player: humanPlayer,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: ProductionScreen must '
                'not emit a RenderFlex overflow exception at '
                'kMinViewportWidth (320 dp). The dark CtTopBar (36 dp '
                'tall — back chevron + `Map` label + 18 × 18 px '
                'production icon + `Production` title) above the '
                'ProductionPanel narrow body (Available stacked above '
                'Allocation, per SPEC/ui/production-panel.md § Layout) '
                'must lay out within the 320 dp column.',
          );

          final topBarFinder = find.byKey(ProductionScreen.topBarKey);
          expect(topBarFinder, findsOneWidget);
          final CtTopBar topBar = tester.widget<CtTopBar>(topBarFinder);
          expect(topBar.title, ProductionScreen.topBarTitle);
          expect(topBar.backButtonLabel, ProductionScreen.topBarBackLabel);

          expect(
            find.descendant(
              of: topBarFinder,
              matching: find.byType(CtBackButton),
            ),
            findsOneWidget,
            reason:
                'The CtTopBar back chevron must remain reachable at '
                '320 dp so the user can navigate back to the map '
                '(SPEC/ui/production-panel.md § Top bar — back '
                'affordance reads "← Map").',
          );

          expect(
            find.byType(ProductionPanel),
            findsOneWidget,
            reason:
                'Default (non-observe) path must mount the '
                '`ProductionPanel` body at 320 dp. '
                'SPEC/ui/production-panel.md § Layout.',
          );

          // The narrow `_ProductionPanelNarrowLayout` is selected at
          // `MediaQuery.sizeOf(context).width < kNarrowBreakpoint`, so
          // at 320 dp both `Available` and `Allocation` section labels
          // must render stacked vertically. Pinning both labels proves
          // the panel actually laid out a non-empty body inside the
          // 320 dp column rather than rendering a placeholder (matches
          // the AC already pinned by `panels_320dp_min_viewport_test.dart`).
          expect(
            find.text('Available'),
            findsOneWidget,
            reason:
                'Narrow layout must render the `Available` section '
                'label at 320 dp (SPEC/ui/production-panel.md § Layout '
                '— narrow path: Available stacked above Allocation).',
          );
          expect(
            find.text('Allocation'),
            findsOneWidget,
            reason:
                'Narrow layout must render the `Allocation` section '
                'label at 320 dp (SPEC/ui/production-panel.md § Layout '
                '— narrow path: Available stacked above Allocation).',
          );

          expect(
            find.byType(ObserveModeNotDefinedPanel),
            findsNothing,
            reason:
                'Default path must NOT render the observe sentinel — '
                'that is the global-observe variant covered by the '
                'second group below.',
          );
        },
      );

      testWidgets(
        'Negative control: ProductionScreen default @ 1024×768 also '
        'pumps without exception (regression sentinel for the overflow '
        'contract — keeps the 320 dp positive pin meaningful)',
        (WidgetTester tester) async {
          await _pumpProductionScreenAtSize(
            tester,
            size: _kWideRegressionViewport,
            game: game,
            player: humanPlayer,
          );

          expect(tester.takeException(), isNull);
          expect(find.byKey(ProductionScreen.topBarKey), findsOneWidget);
          expect(find.byType(ProductionPanel), findsOneWidget);
          expect(find.text('Available'), findsOneWidget);
          expect(find.text('Allocation'), findsOneWidget);
        },
      );
    },
  );

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — ProductionScreen (global '
    'observe) @ 320 dp (Refs #2870 S10)',
    () {
      testWidgets(
        'AC (positive) ProductionScreen global-observe @ 320×640: no '
        'RenderFlex overflow exception, dark CtTopBar still paints, '
        'ObserveModeNotDefinedPanel sentinel renders, ProductionPanel '
        'body is absent',
        (WidgetTester tester) async {
          await _pumpProductionScreenAtSize(
            tester,
            size: _kMinViewport,
            game: game,
            player: humanPlayer,
            globalObserve: true,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: ProductionScreen '
                'global-observe body must not emit a RenderFlex '
                'overflow exception at kMinViewportWidth (320 dp). '
                'The dark CtTopBar plus the '
                "`ObserveModeNotDefinedPanel(title: 'Production')` "
                'sentinel must lay out within the 320 dp column.',
          );

          expect(
            find.byKey(ProductionScreen.topBarKey),
            findsOneWidget,
            reason:
                'Observe override only swaps the body (see SPEC/ui/'
                'production-panel.md § States and variants); the dark '
                'CtTopBar must still paint so the AC for the chrome '
                'is exercised at 320 dp under both variants.',
          );

          final observePanelFinder = find.byType(ObserveModeNotDefinedPanel);
          expect(observePanelFinder, findsOneWidget);
          final ObserveModeNotDefinedPanel observePanel = tester
              .widget<ObserveModeNotDefinedPanel>(observePanelFinder);
          // SPEC/ui/production-panel.md § States and variants requires
          // the literal `Production` title under the observe sentinel.
          expect(observePanel.title, ProductionScreen.topBarTitle);

          expect(
            find.byType(ProductionPanel),
            findsNothing,
            reason:
                'Global-observe path MUST NOT mount the '
                'ProductionPanel body — SPEC/ui/production-panel.md '
                '§ States and variants reserves the observe sentinel '
                'for that branch.',
          );
        },
      );

      testWidgets(
        'Negative control: ProductionScreen global-observe @ 1024×768 '
        'also pumps without exception (regression sentinel for the '
        'overflow contract under the observe variant)',
        (WidgetTester tester) async {
          await _pumpProductionScreenAtSize(
            tester,
            size: _kWideRegressionViewport,
            game: game,
            player: humanPlayer,
            globalObserve: true,
          );

          expect(tester.takeException(), isNull);
          expect(find.byKey(ProductionScreen.topBarKey), findsOneWidget);
          expect(find.byType(ObserveModeNotDefinedPanel), findsOneWidget);
          expect(find.byType(ProductionPanel), findsNothing);
        },
      );
    },
  );
}
