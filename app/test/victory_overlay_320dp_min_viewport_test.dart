// Pin the 320 dp minimum-viewport contract for [VictoryOverlay]
// (OVL20001) — sibling to the existing layout-only narrow pin
// (`victory_overlay_narrow_test.dart`, which already pins the
// `Wrap` -> `Column` action-row flip and the `28` -> `24` dp
// laurel font-size flip at viewport width `< kNarrowBreakpoint`)
// and to the other per-overlay / per-dialog narrow pins under
// `app/test/*_320dp_min_viewport_test.dart`.
//
// `VictoryOverlay` is the full-screen `--dialog-scrim` wash with a
// centered `VictoryPanel` brass surface raised by `GameScreen`
// when `game.victory != null` (see [SPEC/ui/victory-overlay.md]
// and [SPEC/game/victory.md] § Victory Screen). The panel contains
// a laurel decoration row, the localized victory-type title, a
// `CtBrassDivider`, the winner sentence, and two
// `CtNinePatchButton` actions stacked vertically at narrow widths.
// At `kMinViewportWidth` (320 dp) the outer 24 dp scrim padding +
// the panel's own 24 dp outer padding + 28 dp inner horizontal
// padding around the column collapses the usable content width to
// roughly the same `~244` dp budget the narrow `Column` of two
// stretched `CtNinePatchButton`s must share with the laurel,
// title, divider, and body — so the existing narrow-layout
// behaviour exercised by `victory_overlay_narrow_test.dart` must
// stay overflow-free under the canonical 320 dp
// `setSurfaceSize` + `MediaQuery` contract used by the other
// `*_320dp_min_viewport_test.dart` files.
//
// Two positive cases plus a wide regression sentinel cover the
// canonical happy path:
//
//  * `VictoryOverlay` mounted inside a `Stack` (mirroring the
//    real `GameScreen` host plumbing) at `kMinViewportWidth × 640`.
//    Pins the upper-cased `MILITARY VICTORY` title, the winner
//    sentence (`wins on turn 7`), and both `CtNinePatchButton`
//    instances (Return to main menu + View final state). Also
//    pins the `CtBrassDivider` instance count from the SPEC's
//    "title row -> divider -> body" wireframe.
//  * `VictoryPanel` mounted directly (no scrim) at the same
//    viewport so the panel-only overflow contract still pins
//    independently of the outer `Positioned.fill` scrim Container.
//  * Negative control at 1024 × 768 dp pumps the overlay against
//    the same fixture without exception so a regression in the
//    host overflow contract upstream of `VictoryOverlay` itself
//    would be caught.
//
// The pins assert:
//
//  * `WidgetTester.takeException()` is `null` so no `RenderFlex`
//    overflow exception escapes the framework — the contract the
//    other `*_320dp_min_viewport_test.dart` files rely on.
//  * Localized title + winner sentence + both `CtNinePatchButton`
//    labels render end-to-end so the panel body actually
//    exercises the narrow `Column` action layout (from
//    [SPEC/ui/victory-overlay.md] § Narrow viewport) at 320 dp
//    rather than no-op'ing.
//  * Exactly two `CtNinePatchButton` instances mount (matches the
//    base SPEC AC) and exactly one `CtBrassDivider` mounts (per
//    SPEC § Layout / wireframe).
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// SPEC: `SPEC/ui/victory-overlay.md` § Narrow viewport + § Layout / wireframe.
// Refs #2870 S8 (overlays scale at narrow widths) + S10 (no horizontal
// overflow at 320 dp on every covered surface).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/flame/victory_overlay.dart';
import 'package:colonizethis_app/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/panel_test_fixtures.dart';

/// Minimum supported viewport dimensions for `SPEC/ui/mobile-adaptation.md`
/// § 7. Width matches [kMinViewportWidth]; height (640 dp) mirrors the
/// existing screen-, panel-, and dialog-level pin files.
const Size _kMinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel — comfortably above every per-screen
/// breakpoint so the same overlay renders its default `Wrap` action
/// layout. Mirrors the contract used by
/// `grant_or_subsidy_dialog_320dp_min_viewport_test.dart`.
const Size _kWideRegressionViewport = Size(1024, 768);

/// Pumps [child] at [size] under the running editorial-monocle theme.
///
/// Mirrors `_pumpDialogAtSize` in
/// `grant_or_subsidy_dialog_320dp_min_viewport_test.dart` and the
/// `_pumpAtSize` helper in `mobile_320dp_min_viewport_test.dart`:
/// sets the surface size (so the binding's render-flex math sees the
/// minimum viewport) and overrides `MediaQuery` so widget code that
/// reads `MediaQuery.sizeOf(context).width` resolves to the same
/// value. `VictoryPanel.build` switches its narrow / wide layouts off
/// the `MediaQuery.sizeOf(context).width < kNarrowBreakpoint` predicate
/// so both writes must agree.
Future<void> _pumpAtSize(
  WidgetTester tester,
  Widget child, {
  required Size size,
}) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppThemes.editorialMonocle,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  suppressLogsForTests();

  late ct_models.Game game;
  late String winnerPlayerId;
  late ct_models.AppEventBus victoryTestBus;

  setUp(() {
    ct_models.AppEventBus.reset();
    victoryTestBus = ct_models.AppEventBus.create();
    game = buildVictoryPanelTestGame();
    winnerPlayerId = game.players.first.id;
  });

  tearDown(() {
    ct_models.AppEventBus.reset();
  });

  ct_models.VictoryState buildVictory({int turnNumber = 7}) {
    return ct_models.VictoryState(
      winnerPlayerId: winnerPlayerId,
      type: ct_models.VictoryType.military,
      turnNumber: turnNumber,
    );
  }

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — VictoryOverlay (OVL20001) '
    '@ 320 dp (Refs #2870 S8/S10)',
    () {
      testWidgets(
        'AC (positive) VictoryOverlay (military victory, turn 7) @ 320×640: '
        'no RenderFlex overflow exception, MILITARY VICTORY title + winner '
        'sentence + both CtNinePatchButton labels render — the scrim + '
        'centered VictoryPanel narrow column (laurel row, title, '
        'CtBrassDivider, body, stacked Column of two CtNinePatchButtons) '
        'must wrap within the ~244 dp content budget left after the '
        'panel\'s 24 dp outer padding and 28 dp inner horizontal padding '
        'collapse the 320 dp viewport.',
        (WidgetTester tester) async {
          await _pumpAtSize(
            tester,
            Stack(
              children: <Widget>[
                VictoryOverlay(
                  game: game,
                  victory: buildVictory(),
                  bus: victoryTestBus,
                ),
              ],
            ),
            size: _kMinViewport,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: VictoryOverlay must not '
                'emit a RenderFlex overflow exception at kMinViewportWidth '
                '(320 dp). The scrim + centered VictoryPanel narrow column '
                '(laurel row, title, CtBrassDivider, body, stacked '
                'Column of two CtNinePatchButtons per '
                'SPEC/ui/victory-overlay.md § Narrow viewport) must wrap '
                'within the panel\'s narrow content column.',
          );
          // Title + winner sentence render end-to-end at the narrow viewport.
          expect(find.text('MILITARY VICTORY'), findsOneWidget);
          expect(find.textContaining('wins on turn 7'), findsOneWidget);
          // Both action labels render — Return to main menu (primary)
          // and View final state (secondary) — proving the stacked
          // Column action layout from
          // SPEC/ui/victory-overlay.md § Narrow viewport fits within
          // the narrow column without dropping content.
          expect(find.text('Return to main menu'), findsOneWidget);
          expect(find.text('View final state'), findsOneWidget);
          // Base SPEC AC: VictoryPanel mounts exactly two
          // CtNinePatchButton instances and exactly one CtBrassDivider.
          // Pinning these here keeps the 320 dp positive pin honest
          // against a future refactor that silently drops the divider
          // or one of the actions when collapsing the panel chrome.
          expect(find.byType(CtNinePatchButton), findsNWidgets(2));
          expect(find.byType(CtBrassDivider), findsOneWidget);
        },
      );

      testWidgets(
        'AC (positive) VictoryPanel (no scrim) @ 320×640: no RenderFlex '
        'overflow exception, same labels render — pins the panel-only '
        'overflow contract independently of the outer Positioned.fill '
        'scrim Container so a regression that affects only the panel '
        'wireframe (laurel / title / divider / body / actions column) '
        'surfaces without needing the overlay scrim plumbing.',
        (WidgetTester tester) async {
          await _pumpAtSize(
            tester,
            Center(
              child: VictoryPanel(
                game: game,
                victory: buildVictory(turnNumber: 12),
                bus: victoryTestBus,
              ),
            ),
            size: _kMinViewport,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: VictoryPanel must not '
                'emit a RenderFlex overflow exception at kMinViewportWidth '
                '(320 dp) when mounted directly (no scrim wash). The '
                'narrow column wireframe from '
                'SPEC/ui/victory-overlay.md § Layout / wireframe — laurel '
                'row, upper-cased title, CtBrassDivider, body sentence, '
                'stacked Column of two CtNinePatchButtons — must fit '
                'within the panel\'s narrow content column.',
          );
          expect(find.text('MILITARY VICTORY'), findsOneWidget);
          expect(find.textContaining('wins on turn 12'), findsOneWidget);
          expect(find.text('Return to main menu'), findsOneWidget);
          expect(find.text('View final state'), findsOneWidget);
          expect(find.byType(CtNinePatchButton), findsNWidgets(2));
          expect(find.byType(CtBrassDivider), findsOneWidget);
        },
      );

      testWidgets(
        'Negative control: VictoryOverlay (military victory, turn 7) '
        '@ 1024×768 also pumps without exception (regression sentinel '
        'for the overflow contract — keeps the 320 dp positive pins '
        'meaningful by flipping the layout to the default Wrap action '
        'row and headlineSmall title slot per '
        'SPEC/ui/victory-overlay.md § Narrow viewport).',
        (WidgetTester tester) async {
          await _pumpAtSize(
            tester,
            Stack(
              children: <Widget>[
                VictoryOverlay(
                  game: game,
                  victory: buildVictory(),
                  bus: victoryTestBus,
                ),
              ],
            ),
            size: _kWideRegressionViewport,
          );

          expect(tester.takeException(), isNull);
          expect(find.text('MILITARY VICTORY'), findsOneWidget);
          expect(find.textContaining('wins on turn 7'), findsOneWidget);
          expect(find.text('Return to main menu'), findsOneWidget);
          expect(find.text('View final state'), findsOneWidget);
          expect(find.byType(CtNinePatchButton), findsNWidgets(2));
        },
      );
    },
  );
}
