// Pin the 320 dp minimum-viewport contract for the in-game `DiplomacyScreen`
// (GAME30001) full-screen feature surface — extending the existing screen-,
// panel-, dialog-, and unit-panel-level pins
// (`mobile_320dp_min_viewport_test.dart`,
// `panels_320dp_min_viewport_test.dart`,
// `dialogs_320dp_min_viewport_test.dart`,
// `unit_panels_320dp_min_viewport_test.dart`,
// `trade_screen_320dp_min_viewport_test.dart`,
// `diplomacy_detail_screen_320dp_min_viewport_test.dart`) to the in-game
// diplomacy route opened from the empire shell.
//
// `DiplomacyScreen` mounts `CtGameFeatureScreenShell` with the dark
// editorial-monocle `CtTopBar` (back chevron + literal `Map` label + 18 ×
// 18 px diplomacy icon + literal title `Diplomacy`, 36 dp height) above
// an observe-mode-aware body. At `kMinViewportWidth` (320 dp) the
// available width collapses to 320 dp; the chrome and the `DiplomacyPanel`
// body must still lay out without `RenderFlex` overflow per the SPEC
// § Acceptance criteria (mobile-adaptation.md § 7) and the screen spec
// (`SPEC/ui/diplomacy-panel.md` § Top bar, § Layout / wireframe, and
// § States and variants).
//
// Each test asserts:
//
//  * `WidgetTester.takeException()` is `null` so no `RenderFlex` overflow
//    exception (which Flutter surfaces via `FlutterError.onError`) escapes
//    the framework — the contract every other `*_320dp_min_viewport_test.dart`
//    file relies on.
//  * The dark `DiplomacyScreen.topBarKey` resolves to a `CtTopBar` whose
//    literal title `Diplomacy` and back label `Map` both render so the
//    layout actually exercises the diplomacy chrome at 320 dp rather than
//    no-op'ing on an off-screen widget.
//  * For the default (non-observe) path: the `DiplomacyPanel` body mounts
//    and its `Great Powers` faction-section heading is visible.
//  * For the global-observe path: `ObserveModeNotDefinedPanel` is mounted
//    with the literal `Diplomacy` title and the `DiplomacyPanel` body is
//    absent.
//  * A wide negative control at 1024 × 768 dp pumps without exception
//    against the same fixture so a regression in the overflow contract
//    upstream of `DiplomacyScreen` itself would still surface.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// SPEC: `SPEC/ui/diplomacy-panel.md` § Top bar, § Layout / wireframe,
// and § States and variants.
// Refs #2870 S10 (no horizontal overflow at 320 dp on every covered
// screen).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/flame/region_map_component.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/screens/diplomacy_screen.dart';
import 'package:colonizethis_app/features/game/shell_player_context.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';
import 'package:colonizethis_app/features/game/widgets/observe_mode_not_defined_panel.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
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
/// breakpoint so the same screen renders its default chrome. Mirrors the
/// contract used by `mobile_320dp_min_viewport_test.dart`,
/// `panels_320dp_min_viewport_test.dart`,
/// `dialogs_320dp_min_viewport_test.dart`,
/// `unit_panels_320dp_min_viewport_test.dart`, and
/// `trade_screen_320dp_min_viewport_test.dart`.
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
    // true so `DiplomacyScreen.bodyBuilder` short-circuits to the
    // `ObserveModeNotDefinedPanel` sentinel per
    // SPEC/ui/observe-mode.md and SPEC/ui/diplomacy-panel.md
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

/// Pumps the [DiplomacyScreen] at [size] under the running editorial-
/// monocle theme. Sets the surface size (so the binding's render-flex
/// math sees the minimum viewport) and overrides MediaQuery so widget
/// code that reads `MediaQuery.sizeOf(context).width` resolves to the
/// same value — the pattern already used by every other
/// `*_320dp_min_viewport_test.dart` file. Overrides `currentGameProvider`
/// (and optionally `shellPlayerContextProvider` for the global-observe
/// branch) so the shell renders without touching Hive / GameService.
Future<void> _pumpDiplomacyScreenAtSize(
  WidgetTester tester, {
  required Size size,
  required Game game,
  required String humanPlayerId,
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
          child: DiplomacyScreen(game: game, humanPlayerId: humanPlayerId),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  suppressLogsForTests();

  late Game game;
  late String humanPlayerId;

  setUpAll(() {
    final result = getDebugInitGameResult();
    game = result.game;
    humanPlayerId = game.players
        .firstWhere(
          (p) => p.isHuman,
          orElse: () => game.players.first,
        )
        .id;
  });

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — DiplomacyScreen (default) @ '
    '320 dp (Refs #2870 S10)',
    () {
      testWidgets(
        'AC (positive) DiplomacyScreen default @ 320×640: no RenderFlex '
        'overflow exception, dark CtTopBar (title `Diplomacy`, back '
        'label `Map`) + DiplomacyPanel body (`Great Powers` heading) '
        'both render',
        (WidgetTester tester) async {
          await _pumpDiplomacyScreenAtSize(
            tester,
            size: _kMinViewport,
            game: game,
            humanPlayerId: humanPlayerId,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: DiplomacyScreen must '
                'not emit a RenderFlex overflow exception at '
                'kMinViewportWidth (320 dp). The dark CtTopBar (36 dp '
                'tall — back chevron + `Map` label + 18 × 18 px '
                'diplomacy icon + `Diplomacy` title) above the '
                'DiplomacyPanel body must lay out within the 320 dp '
                'column per SPEC/ui/diplomacy-panel.md § Top bar and '
                '§ Layout / wireframe.',
          );

          final topBarFinder = find.byKey(DiplomacyScreen.topBarKey);
          expect(topBarFinder, findsOneWidget);
          final CtTopBar topBar = tester.widget<CtTopBar>(topBarFinder);
          expect(topBar.title, DiplomacyScreen.topBarTitle);
          expect(topBar.backButtonLabel, DiplomacyScreen.topBarBackLabel);

          expect(
            find.descendant(
              of: topBarFinder,
              matching: find.byType(CtBackButton),
            ),
            findsOneWidget,
            reason:
                'The CtTopBar back chevron must remain reachable at '
                '320 dp so the user can navigate back to the map '
                '(SPEC/ui/diplomacy-panel.md § Top bar — back affordance '
                'reads "← Map").',
          );

          expect(
            find.byType(DiplomacyPanel),
            findsOneWidget,
            reason:
                'Default (non-observe) path must mount the '
                '`DiplomacyPanel` body at 320 dp. '
                'SPEC/ui/diplomacy-panel.md § Layout / wireframe.',
          );
          // The DiplomacyPanel renders a `Great Powers` faction-section
          // heading when at least one GP exists in the game (the
          // debug-init fixture seeds six GPs). Pinning the heading
          // proves the panel actually laid out a non-empty body inside
          // the 320 dp column rather than rendering a placeholder.
          expect(
            find.text('Great Powers'),
            findsOneWidget,
            reason:
                'Default path must render the `Great Powers` faction-'
                'section heading inside the DiplomacyPanel body at '
                '320 dp (SPEC/ui/diplomacy-panel.md § Layout / '
                'wireframe — Faction sections).',
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
        'Negative control: DiplomacyScreen default @ 1024×768 also '
        'pumps without exception (regression sentinel for the overflow '
        'contract — keeps the 320 dp positive pin meaningful)',
        (WidgetTester tester) async {
          await _pumpDiplomacyScreenAtSize(
            tester,
            size: _kWideRegressionViewport,
            game: game,
            humanPlayerId: humanPlayerId,
          );

          expect(tester.takeException(), isNull);
          expect(find.byKey(DiplomacyScreen.topBarKey), findsOneWidget);
          expect(find.byType(DiplomacyPanel), findsOneWidget);
          expect(find.text('Great Powers'), findsOneWidget);
        },
      );
    },
  );

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — DiplomacyScreen (global '
    'observe) @ 320 dp (Refs #2870 S10)',
    () {
      testWidgets(
        'AC (positive) DiplomacyScreen global-observe @ 320×640: no '
        'RenderFlex overflow exception, dark CtTopBar still paints, '
        'ObserveModeNotDefinedPanel sentinel renders, DiplomacyPanel '
        'body is absent',
        (WidgetTester tester) async {
          await _pumpDiplomacyScreenAtSize(
            tester,
            size: _kMinViewport,
            game: game,
            humanPlayerId: humanPlayerId,
            globalObserve: true,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: DiplomacyScreen '
                'global-observe body must not emit a RenderFlex '
                'overflow exception at kMinViewportWidth (320 dp). '
                'The dark CtTopBar plus the '
                "`ObserveModeNotDefinedPanel(title: 'Diplomacy')` "
                'sentinel must lay out within the 320 dp column.',
          );

          expect(
            find.byKey(DiplomacyScreen.topBarKey),
            findsOneWidget,
            reason:
                'Observe override only swaps the body (see SPEC/ui/'
                'diplomacy-panel.md § States and variants); the dark '
                'CtTopBar must still paint so the AC for the chrome is '
                'exercised at 320 dp under both variants.',
          );

          final observePanelFinder = find.byType(ObserveModeNotDefinedPanel);
          expect(observePanelFinder, findsOneWidget);
          final ObserveModeNotDefinedPanel observePanel = tester
              .widget<ObserveModeNotDefinedPanel>(observePanelFinder);
          // SPEC/ui/diplomacy-panel.md § States and variants requires
          // the literal `Diplomacy` title under the observe sentinel.
          // ignore: avoid_hardcoded_strings_in_widgets
          expect(observePanel.title, 'Diplomacy');

          expect(
            find.byType(DiplomacyPanel),
            findsNothing,
            reason:
                'Global-observe path MUST NOT mount the DiplomacyPanel '
                'body — SPEC/ui/diplomacy-panel.md § States and '
                'variants reserves the observe sentinel for that '
                'branch.',
          );
        },
      );

      testWidgets(
        'Negative control: DiplomacyScreen global-observe @ 1024×768 '
        'also pumps without exception (regression sentinel for the '
        'overflow contract under the observe variant)',
        (WidgetTester tester) async {
          await _pumpDiplomacyScreenAtSize(
            tester,
            size: _kWideRegressionViewport,
            game: game,
            humanPlayerId: humanPlayerId,
            globalObserve: true,
          );

          expect(tester.takeException(), isNull);
          expect(find.byKey(DiplomacyScreen.topBarKey), findsOneWidget);
          expect(find.byType(ObserveModeNotDefinedPanel), findsOneWidget);
          expect(find.byType(DiplomacyPanel), findsNothing);
        },
      );
    },
  );
}
