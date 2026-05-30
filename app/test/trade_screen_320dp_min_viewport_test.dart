// Pin the 320 dp minimum-viewport contract for the World Market
// `TradeScreen` (GAME60001) full-screen feature surface — extending the
// existing screen-, panel-, dialog-, and unit-panel-level pins
// (`mobile_320dp_min_viewport_test.dart`, `panels_320dp_min_viewport_test.dart`,
// `dialogs_320dp_min_viewport_test.dart`,
// `unit_panels_320dp_min_viewport_test.dart`) to the in-game trade route.
//
// `TradeScreen` mounts `CtGameFeatureScreenShell` with the dark
// editorial-monocle `CtTopBar` (back affordance + 18 × 18 pixel-art trade
// icon + literal title `Trade`, 36 dp height) above an
// observe-mode-aware body. At `kMinViewportWidth` (320 dp) the available
// width collapses to 320 dp; the chrome and body must still lay out
// without `RenderFlex` overflow. The current placeholder body
// (`#2993` E1+E2+E3 scaffold) is exercised under the non-observe path;
// the `ObserveModeNotDefinedPanel` sentinel is exercised under global
// observe. Both paths satisfy the parent `mobile-adaptation.md` § 7 AC.
//
// Each test asserts:
//
//  * `WidgetTester.takeException()` is `null` so no `RenderFlex` overflow
//    exception (which Flutter surfaces via `FlutterError.onError`) escapes
//    the framework — the contract every other `*_320dp_min_viewport_test.dart`
//    file relies on.
//  * The dark `tradeScreenTopBar` key resolves to a `CtTopBar` whose
//    literal title `Trade` and back label `Map` both render end-to-end so
//    the layout actually exercises the trade chrome at 320 dp rather than
//    no-op'ing on an off-screen widget.
//  * For the default (non-observe) path: the
//    `tradeScreenScaffoldPlaceholder` key resolves to the placeholder
//    body widget.
//  * For the global-observe path: `ObserveModeNotDefinedPanel` is mounted
//    with the localized `Trade` title and the placeholder body is absent.
//  * A wide negative control at 1024 × 768 dp pumps without exception
//    against the same fixture so a regression in the overflow contract
//    upstream of `TradeScreen` itself would be caught.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// SPEC: `SPEC/ui/trade-screen.md` § Layout / wireframe and § Acceptance
// criteria.
// Refs #2870 S10 (no horizontal overflow at 320 dp on every covered
// screen) and #2993 (Trade screen scaffold slice that this pin extends
// coverage to).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/flame/region_map_component.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/screens/trade_screen.dart';
import 'package:colonizethis_app/features/game/shell_player_context.dart';
import 'package:colonizethis_app/features/game/widgets/observe_mode_not_defined_panel.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimum supported viewport dimensions for SPEC/ui/mobile-adaptation.md
/// § 7. Width matches [kMinViewportWidth]; height (640 dp) mirrors the
/// existing screen-, panel-, and dialog-level pin files.
const Size _kMinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel — comfortably above every per-screen
/// breakpoint so the same screen renders its default chrome. Mirrors
/// the contract used by `mobile_320dp_min_viewport_test.dart`,
/// `panels_320dp_min_viewport_test.dart`,
/// `dialogs_320dp_min_viewport_test.dart`, and
/// `unit_panels_320dp_min_viewport_test.dart`.
const Size _kWideRegressionViewport = Size(1024, 768);

/// Builds a [ShellPlayerContext] mirroring the global-observe branch
/// surfaced by `shellPlayerContextProvider`. Mirrors the helper used by
/// `trade_screen_scaffold_test.dart` so the observe pin exercises the
/// same path the in-app observe session takes.
ShellPlayerContext _globalObserveShellContext() {
  return const ShellPlayerContext(
    effectiveHumanPlayerId: null,
    viewingPlayerId: null,
    mapVisibilityMode: CtMapVisibilityMode.full,
    playerView: null,
    omniscientDetail: true,
    // `showPlayerChrome: false` flips `shellPanelsNotDefined(ref)` to
    // true so `TradeScreen.bodyBuilder` short-circuits to the
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

/// Pumps the [TradeScreen] at [size] under the running editorial-monocle
/// theme. Sets the surface size (so the binding's render flex math sees
/// the minimum viewport) and overrides MediaQuery so widget code that
/// reads `MediaQuery.sizeOf(context).width` resolves to the same value
/// — the pattern already used by every other `*_320dp_min_viewport_test.dart`
/// file. Overrides `currentGameProvider` (and optionally
/// `shellPlayerContextProvider` for the global-observe branch) so the
/// shell renders without touching Hive / GameService.
Future<void> _pumpTradeScreenAtSize(
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
          child: TradeScreen(game: game, player: player),
        ),
      ),
    ),
  );
  // Single pump is enough: TradeScreen's chrome paints synchronously
  // and the placeholder body is a single static `CtPanel`. Mirrors the
  // `settle: false` branch used by the dialog 320 dp pin file when a
  // dialog hosts an indefinite ticker (here we have no ticker; we
  // still avoid `pumpAndSettle` because `CtGameFeatureScreenShell`'s
  // bus listener attaches per the live `currentGameProvider` and we
  // want the 320 dp overflow assertion to evaluate on the first frame).
  await tester.pump();
}

void main() {
  suppressLogsForTests();

  late Game game;
  late Player humanPlayer;

  setUpAll(() {
    final result = getDebugInitGameResult();
    game = result.game;
    humanPlayer = game.players.firstWhere(
      (p) => p.isHuman,
      orElse: () => game.players.first,
    );
  });

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — TradeScreen (default) @ 320 dp '
    '(Refs #2870 S10, #2993)',
    () {
      testWidgets(
        'AC (positive) TradeScreen default @ 320×640: no RenderFlex '
        'overflow exception, dark CtTopBar (title `Trade`, back label '
        '`Map`) + scaffold placeholder body both render',
        (WidgetTester tester) async {
          await _pumpTradeScreenAtSize(
            tester,
            size: _kMinViewport,
            game: game,
            player: humanPlayer,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: TradeScreen must not '
                'emit a RenderFlex overflow exception at '
                'kMinViewportWidth (320 dp). The dark CtTopBar '
                '(36 dp tall — back chevron + `Map` label + 18 × 18 px '
                'trade icon + `Trade` title) above the scaffold '
                'placeholder body (`CtPanel` with 24 dp padding hosting '
                'the `World Market` title + muted explanatory copy) '
                'must lay out within the 320 dp column.',
          );

          final topBarFinder = find.byKey(TradeScreen.topBarKey);
          expect(topBarFinder, findsOneWidget);
          final CtTopBar topBar = tester.widget<CtTopBar>(topBarFinder);
          expect(topBar.title, TradeScreen.topBarTitle);
          expect(topBar.backButtonLabel, TradeScreen.topBarBackLabel);

          expect(
            find.byKey(TradeScreen.placeholderBodyKey),
            findsOneWidget,
            reason:
                'Default (non-observe) path must mount the scaffold '
                'placeholder body keyed `tradeScreenScaffoldPlaceholder` '
                'at 320 dp. SPEC/ui/trade-screen.md § Body (current '
                'scaffold slice).',
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
        'Negative control: TradeScreen default @ 1024×768 also pumps '
        'without exception (regression sentinel for the overflow '
        'contract — keeps the 320 dp positive pin meaningful)',
        (WidgetTester tester) async {
          await _pumpTradeScreenAtSize(
            tester,
            size: _kWideRegressionViewport,
            game: game,
            player: humanPlayer,
          );

          expect(tester.takeException(), isNull);
          expect(find.byKey(TradeScreen.topBarKey), findsOneWidget);
          expect(find.byKey(TradeScreen.placeholderBodyKey), findsOneWidget);
        },
      );
    },
  );

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — TradeScreen (global observe) @ '
    '320 dp (Refs #2870 S10, #2993)',
    () {
      testWidgets(
        'AC (positive) TradeScreen global-observe @ 320×640: no '
        'RenderFlex overflow exception, dark CtTopBar still paints, '
        'ObserveModeNotDefinedPanel sentinel renders, scaffold '
        'placeholder body is absent',
        (WidgetTester tester) async {
          await _pumpTradeScreenAtSize(
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
                'SPEC/ui/mobile-adaptation.md § 7: TradeScreen global-'
                'observe body must not emit a RenderFlex overflow '
                'exception at kMinViewportWidth (320 dp). The dark '
                'CtTopBar plus the `ObserveModeNotDefinedPanel(title: '
                "'Trade')` sentinel must lay out within the 320 dp "
                'column.',
          );

          expect(
            find.byKey(TradeScreen.topBarKey),
            findsOneWidget,
            reason:
                'Observe override only swaps the body (see SPEC/ui/'
                'trade-screen.md § States and variants); the dark '
                'CtTopBar must still paint so the AC for the chrome '
                'is exercised at 320 dp under both variants.',
          );

          final observePanelFinder = find.byType(ObserveModeNotDefinedPanel);
          expect(observePanelFinder, findsOneWidget);
          final ObserveModeNotDefinedPanel observePanel = tester
              .widget<ObserveModeNotDefinedPanel>(observePanelFinder);
          // SPEC/ui/trade-screen.md § States and variants requires the
          // literal localized `Trade` title under the observe sentinel.
          // ignore: avoid_hardcoded_strings_in_widgets
          expect(observePanel.title, 'Trade');

          expect(
            find.byKey(TradeScreen.placeholderBodyKey),
            findsNothing,
            reason:
                'Global-observe path MUST NOT mount the scaffold '
                'placeholder body — SPEC/ui/trade-screen.md § States '
                'and variants reserves the observe sentinel for that '
                'branch.',
          );
        },
      );

      testWidgets(
        'Negative control: TradeScreen global-observe @ 1024×768 also '
        'pumps without exception (regression sentinel for the overflow '
        'contract under the observe variant)',
        (WidgetTester tester) async {
          await _pumpTradeScreenAtSize(
            tester,
            size: _kWideRegressionViewport,
            game: game,
            player: humanPlayer,
            globalObserve: true,
          );

          expect(tester.takeException(), isNull);
          expect(find.byKey(TradeScreen.topBarKey), findsOneWidget);
          expect(find.byType(ObserveModeNotDefinedPanel), findsOneWidget);
        },
      );
    },
  );
}
