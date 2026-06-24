// Pin the 320 dp minimum-viewport contract for the full-screen
// `TechnologyScreen` (GAME40001) Empire feature surface — extending the
// existing panel- and screen-level pins
// (`panels_320dp_min_viewport_test.dart` covers `TechnologyPanel`;
// `trade_screen_320dp_min_viewport_test.dart` and
// `game_screen_320dp_min_viewport_test.dart` cover their respective
// shells) to the Technology shell.
//
// `TechnologyScreen` mounts `CtGameFeatureScreenShell` with the dark
// editorial-monocle `CtTopBar` carrying the `Map` back affordance, the
// 18 × 18 pixel-art technology icon, the literal title `Technology`, and
// a Slots / Tree toggle in the trailing slot — the only Empire screen
// (besides Trade) whose top bar carries a trailing widget cluster. At
// `kMinViewportWidth` (320 dp) the available column collapses to 320 dp;
// the chrome (with both trailing toggles) plus the body must lay out
// without `RenderFlex` overflow.
//
// Each test asserts:
//
//  * `WidgetTester.takeException()` is `null` so no `RenderFlex` overflow
//    exception (which Flutter surfaces via `FlutterError.onError`) escapes
//    the framework — the contract every sibling `*_320dp_min_viewport_test.dart`
//    file relies on.
//  * The dark `technologyScreenTopBar` key resolves to a `CtTopBar` whose
//    literal title `Technology` and back label `Map` both render end-to-end
//    so the layout actually exercises the technology chrome at 320 dp.
//  * For the default (non-observe) path: the Slots toggle and Tree toggle
//    are both mounted inside the top bar's trailing slot at 320 dp, and
//    the `_SlotsBody` (`SingleChildScrollView` > `TechnologyPanel`) is
//    the visible body — pinning Req 15 (technology slots scroll
//    vertically at narrow) plus the wide-shell trailing chrome staying
//    intact at the minimum viewport.
//  * For the global-observe path: `ObserveModeNotDefinedPanel('Technology')`
//    is mounted and the `TechnologyPanel` body is absent.
//  * A wide negative control at 1024 × 768 dp pumps without exception
//    against the same fixture so a regression in the overflow contract
//    upstream of `TechnologyScreen` itself would be caught, mirroring
//    the contrast pattern in the sibling 320 dp pin files.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// SPEC: `SPEC/ui/technology-panel.md` § Top bar and § Slot behaviour.
// Refs #2870 S10 (no horizontal overflow at 320 dp on every covered
// screen) + Req 15 (technology slot cards and researched grid scroll
// vertically at narrow).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/flame/region_map_component.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/screens/technology_screen.dart';
import 'package:colonizethis_app/features/game/shell_player_context.dart';
import 'package:colonizethis_app/features/game/widgets/observe_mode_not_defined_panel.dart';
import 'package:colonizethis_app/features/game/widgets/technology_panel.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/panel_test_fixtures.dart';

/// Minimum supported viewport dimensions for SPEC/ui/mobile-adaptation.md
/// § 7. Width matches [kMinViewportWidth]; height (640 dp) mirrors the
/// existing sibling screen-level pin files
/// (`trade_screen_320dp_min_viewport_test.dart`,
/// `game_screen_320dp_min_viewport_test.dart`,
/// `panels_320dp_min_viewport_test.dart`).
const Size _kMinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel — comfortably above every per-screen
/// breakpoint so the same screen renders its default chrome. Mirrors
/// the contract used by `mobile_320dp_min_viewport_test.dart`,
/// `panels_320dp_min_viewport_test.dart`,
/// `dialogs_320dp_min_viewport_test.dart`,
/// `trade_screen_320dp_min_viewport_test.dart`, and
/// `game_screen_320dp_min_viewport_test.dart`.
const Size _kWideRegressionViewport = Size(1024, 768);

/// Builds a [ShellPlayerContext] mirroring the global-observe branch
/// surfaced by `shellPlayerContextProvider`. Mirrors the helper used by
/// `trade_screen_320dp_min_viewport_test.dart` so the observe pin
/// exercises the same path the in-app observe session takes.
ShellPlayerContext _globalObserveShellContext() {
  return const ShellPlayerContext(
    effectiveHumanPlayerId: null,
    viewingPlayerId: null,
    mapVisibilityMode: CtMapVisibilityMode.full,
    playerView: null,
    omniscientDetail: true,
    // `showPlayerChrome: false` flips `shellPanelsNotDefined(ref)` to
    // true so `TechnologyScreen.bodyBuilder` short-circuits to the
    // `ObserveModeNotDefinedPanel` sentinel per SPEC/ui/observe-mode.md.
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

/// Pumps the [TechnologyScreen] at [size] under the running editorial-monocle
/// theme. Sets the surface size (so the binding's render flex math sees
/// the minimum viewport) and overrides MediaQuery so widget code that
/// reads `MediaQuery.sizeOf(context).width` resolves to the same value
/// — the pattern already used by every other `*_320dp_min_viewport_test.dart`
/// file. Overrides `currentGameProvider` and `currentOrdersProvider`
/// (and optionally `shellPlayerContextProvider` for the global-observe
/// branch) so the shell renders without touching Hive / GameService.
Future<void> _pumpTechnologyScreenAtSize(
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
        currentOrdersProvider.overrideWith(
          () => CurrentOrdersNotifier(const Orders()),
        ),
        appEventBusProvider.overrideWith((ref) {
          final bus = AppEventBus.create();
          ref.onDispose(bus.dispose);
          return bus;
        }),
        if (globalObserve)
          shellPlayerContextProvider.overrideWithValue(
            _globalObserveShellContext(),
          ),
      ],
      child: MaterialApp(
        theme: AppThemes.editorialMonocle,
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: TechnologyScreen(game: game, player: player),
        ),
      ),
    ),
  );
  // Single pump is enough: TechnologyScreen's chrome paints synchronously
  // and the Slots body is a `SingleChildScrollView` around a `Column`
  // with no indefinite ticker. Mirrors the `await tester.pump()` branch
  // used by `trade_screen_320dp_min_viewport_test.dart` for the same
  // reason (`CtGameFeatureScreenShell` attaches a bus listener tied to
  // the live `currentGameProvider`; we want the 320 dp overflow
  // assertion to evaluate on the first frame).
  await tester.pump();
}

void main() {
  suppressLogsForTests();

  late Game game;
  late Player humanPlayer;

  setUpAll(() {
    // Lightweight fixture (Refs #3656): `TechnologyScreen` only reads
    // `game.players` / the supplied `player` (via `CtGameFeatureScreenShell`
    // and `TechnologyPanel`); no generated map/topology data is consumed, so
    // the full procedural map generator is avoided.
    game = buildTechnologyPanelTestGame();
    humanPlayer = game.players.firstWhere(
      (p) => p.isHuman,
      orElse: () => game.players.first,
    );
  });

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — TechnologyScreen (default Slots) '
    '@ 320 dp (Refs #2870 S10 + Req 15)',
    () {
      testWidgets(
        'AC (positive) TechnologyScreen default Slots @ 320×640: no '
        'RenderFlex overflow exception, dark CtTopBar (title `Technology`, '
        'back label `Map`) + Slots/Tree trailing toggles + Slots body '
        '(TechnologyPanel) all render',
        (WidgetTester tester) async {
          await _pumpTechnologyScreenAtSize(
            tester,
            size: _kMinViewport,
            game: game,
            player: humanPlayer,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: TechnologyScreen must '
                'not emit a RenderFlex overflow exception at '
                'kMinViewportWidth (320 dp). The dark CtTopBar '
                '(36 dp tall — back chevron + `Map` label + 18 × 18 px '
                'technology icon + `Technology` title + Slots/Tree '
                'toggle pair in the trailing slot) above the '
                '`SingleChildScrollView` > `TechnologyPanel` body must '
                'lay out within the 320 dp column.',
          );

          final topBarFinder = find.byKey(TechnologyScreen.topBarKey);
          expect(topBarFinder, findsOneWidget);
          final CtTopBar topBar = tester.widget<CtTopBar>(topBarFinder);
          expect(topBar.title, TechnologyScreen.topBarTitle);
          expect(topBar.backButtonLabel, TechnologyScreen.topBarBackLabel);
          expect(
            topBar.trailing,
            isNotNull,
            reason:
                'SPEC/ui/technology-panel.md § Top bar: the Slots/Tree '
                'toggle pair must live in the CtTopBar trailing slot '
                'even at 320 dp (Refs #2864 S1 + #2870 S10).',
          );

          expect(
            find.descendant(
              of: topBarFinder,
              matching: find.byKey(TechnologyScreen.slotsToggleKey),
            ),
            findsOneWidget,
            reason:
                'Slots toggle must remain mounted inside the top bar '
                'trailing slot at the minimum viewport so the Slots '
                'tab is still reachable on a 320 dp phone.',
          );
          expect(
            find.descendant(
              of: topBarFinder,
              matching: find.byKey(TechnologyScreen.treeToggleKey),
            ),
            findsOneWidget,
            reason:
                'Tree toggle must remain mounted inside the top bar '
                'trailing slot at the minimum viewport so the Tree '
                'tab is still reachable on a 320 dp phone.',
          );

          expect(
            find.byType(TechnologyPanel),
            findsOneWidget,
            reason:
                'Default Slots tab path must mount the live '
                '`TechnologyPanel` at 320 dp (Req 15 — slot cards and '
                'researched grid scroll vertically inside the parent '
                '`SingleChildScrollView`). SPEC/ui/technology-panel.md '
                '§ Slot behaviour.',
          );
          expect(
            find.byType(ObserveModeNotDefinedPanel),
            findsNothing,
            reason:
                'Default path must NOT render the observe sentinel — '
                'that is the global-observe variant covered by the '
                'observe group below.',
          );
        },
      );

      testWidgets(
        'Negative control: TechnologyScreen default Slots @ 1024×768 '
        'also pumps without exception (regression sentinel for the '
        'overflow contract — keeps the 320 dp positive pin meaningful)',
        (WidgetTester tester) async {
          await _pumpTechnologyScreenAtSize(
            tester,
            size: _kWideRegressionViewport,
            game: game,
            player: humanPlayer,
          );

          expect(tester.takeException(), isNull);
          expect(find.byKey(TechnologyScreen.topBarKey), findsOneWidget);
          expect(find.byType(TechnologyPanel), findsOneWidget);
        },
      );
    },
  );

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — TechnologyScreen (global observe) '
    '@ 320 dp (Refs #2870 S10)',
    () {
      testWidgets(
        'AC (positive) TechnologyScreen global-observe @ 320×640: no '
        'RenderFlex overflow exception, dark CtTopBar still paints, '
        '`ObserveModeNotDefinedPanel(title: "Technology")` sentinel '
        'renders, the live TechnologyPanel body is absent',
        (WidgetTester tester) async {
          await _pumpTechnologyScreenAtSize(
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
                'SPEC/ui/mobile-adaptation.md § 7: TechnologyScreen '
                'global-observe body must not emit a RenderFlex '
                'overflow exception at kMinViewportWidth (320 dp). The '
                'dark CtTopBar plus the `ObserveModeNotDefinedPanel('
                "title: 'Technology')` sentinel must lay out within "
                'the 320 dp column.',
          );

          expect(
            find.byKey(TechnologyScreen.topBarKey),
            findsOneWidget,
            reason:
                'Observe override only swaps the body (see SPEC/ui/'
                'technology-panel.md § States and variants); the dark '
                'CtTopBar must still paint so the AC for the chrome '
                'is exercised at 320 dp under both variants.',
          );

          final observePanelFinder = find.byType(ObserveModeNotDefinedPanel);
          expect(observePanelFinder, findsOneWidget);
          final ObserveModeNotDefinedPanel observePanel = tester
              .widget<ObserveModeNotDefinedPanel>(observePanelFinder);
          // TechnologyScreen.bodyBuilder hard-codes the title literal
          // `Technology` for the observe sentinel (see screen source);
          // SPEC/ui/technology-panel.md § States and variants pins
          // that literal.
          // ignore: avoid_hardcoded_strings_in_widgets
          expect(observePanel.title, 'Technology');

          expect(
            find.byType(TechnologyPanel),
            findsNothing,
            reason:
                'Global-observe path MUST NOT mount the live '
                'TechnologyPanel — SPEC/ui/technology-panel.md § States '
                'and variants reserves the observe sentinel for that '
                'branch.',
          );
        },
      );

      testWidgets(
        'Negative control: TechnologyScreen global-observe @ 1024×768 '
        'also pumps without exception (regression sentinel for the '
        'overflow contract under the observe variant)',
        (WidgetTester tester) async {
          await _pumpTechnologyScreenAtSize(
            tester,
            size: _kWideRegressionViewport,
            game: game,
            player: humanPlayer,
            globalObserve: true,
          );

          expect(tester.takeException(), isNull);
          expect(find.byKey(TechnologyScreen.topBarKey), findsOneWidget);
          expect(find.byType(ObserveModeNotDefinedPanel), findsOneWidget);
        },
      );
    },
  );
}
