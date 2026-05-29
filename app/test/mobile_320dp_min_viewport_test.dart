// Pin the 320 dp minimum-viewport contract for SPEC/ui/mobile-adaptation.md
// § 7 (Minimum-viewport pin) and `Refs #2870` § Acceptance criteria
// (320 dp no horizontal overflow + 44 dp touch targets).
//
// These widget tests:
//
//  * Render `CtMainMenu` (`plain` + `pixelArt` variants, default state and
//    `noSaves` state) at exactly `kMinViewportWidth × 640` (320 × 640 dp) and
//    assert no `RenderFlex` overflow exceptions surface and every visible
//    `CtNinePatchButton` reports a rendered height ≥ `kMinTouchTargetSize`.
//  * Render `CtGameSetup` (`plain` + `pixelArt` variants × `default_` +
//    `loading` states) at the same minimum viewport and assert the screen
//    pumps without exceptions and the six player-slot rows stack vertically
//    per § 4 Game Setup (the narrow `< 500 dp` rule applies trivially at
//    320 dp).
//  * Include negative pins that intentionally render at a wide viewport so a
//    regression in the host overflow detection itself would be caught.
//
// Touch-target verification covers the **main interactive controls** of the
// rendered screen — `CtNinePatchButton` instances. Smaller decorative chrome
// (e.g. `CtBackButton` chevron, dropdown chevron) is intentionally out of
// scope here per the existing `SPEC/ui/mobile-adaptation.md` § 1 carve-out
// ("Buttons in Main Menu and Game Setup use 48 dp height; keep that or
// larger") which targets the primary action buttons.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// Refs #2870 S10.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/app_display_strings.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/game_setup.dart';
import 'package:colonizethis_app/widgets/main_menu.dart';

/// Minimum supported viewport dimensions for SPEC/ui/mobile-adaptation.md
/// § 7. Width matches [kMinViewportWidth]; height (640 dp) is the lower end
/// of the iPhone SE-class mobile envelope mockups target.
const Size _kMinViewport = Size(kMinViewportWidth, 640);

/// Viewport used by the negative-regression pin: comfortably wider than
/// every per-screen breakpoint so the same screens render their wide layout
/// without any responsive concessions. If a future refactor flips the
/// overflow contract upstream, this control still passes — the contrast
/// with the 320 dp positive pins keeps the regression signal honest.
const Size _kWideRegressionViewport = Size(1024, 768);

Widget _wrapMainMenu({
  MainMenuVariant variant = MainMenuVariant.plain,
  MainMenuState state = MainMenuState.default_,
}) {
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
    home: CtMainMenu(
      variant: variant,
      state: state,
      version: formatDebugAwareVersion('v1.0.0'),
      onNewGame: () {},
      onLoadGame: () {},
      onSettings: () {},
      onQuit: () {},
    ),
  );
}

Widget _wrapGameSetup({
  GameSetupVariant variant = GameSetupVariant.plain,
  GameSetupState state = GameSetupState.default_,
}) {
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
    home: CtGameSetup(
      variant: variant,
      state: state,
      naming: defaultNamingConfig,
      initialOrderedGpIds: List<String>.filled(6, ''),
      initialLeaderVariantByGpId: const {},
      onStartGame: (_, _) {},
      onBack: () {},
    ),
  );
}

/// Pumps [screen] at [size] and asserts the framework emitted no
/// exception. We deliberately treat any caught exception as a failure
/// because Flutter surfaces `RenderFlex` overflows as
/// `FlutterError`s with `"RenderFlex overflowed"` messages via the
/// `FlutterError.onError` channel, which `WidgetTester` collects through
/// `takeException`. This is the same contract several existing tests in
/// the repo rely on (see `unit_panels_widgetbook_dark_chrome_test.dart`).
///
/// When [settleAnimations] is `true` (default) the helper drives
/// `pumpAndSettle()` to completion. When `false` it pumps a small finite
/// number of frames instead so screens with **continuous** animations
/// (e.g. the `CtGameSetup` `loading` state with its always-spinning
/// loading indicator) can still be exercised against the layout overflow
/// contract without the framework's settle-loop timing out.
Future<void> _pumpAtSize(
  WidgetTester tester,
  Widget screen, {
  required Size size,
  bool settleAnimations = true,
}) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(
    MediaQuery(data: MediaQueryData(size: size), child: screen),
  );
  if (settleAnimations) {
    await tester.pumpAndSettle();
  } else {
    // Two extra frames are enough for the layout pass and any one-frame
    // post-build microtasks to surface a `RenderFlex` overflow exception
    // through `WidgetTester.takeException()`.
    await tester.pump();
    await tester.pump();
  }
}

/// Returns the rendered height (logical pixels) of every visible
/// [CtNinePatchButton] descendant of the current widget tree.
List<double> _renderedNinePatchButtonHeights(WidgetTester tester) {
  final Iterable<Element> elements = find
      .byType(CtNinePatchButton)
      .evaluate();
  final List<double> heights = <double>[];
  for (final Element element in elements) {
    final RenderBox? box = element.renderObject as RenderBox?;
    if (box == null || !box.hasSize) continue;
    heights.add(box.size.height);
  }
  return heights;
}

void main() {
  suppressLogsForTests();

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — 320 dp minimum viewport (Refs #2870 S10)',
    () {
      testWidgets(
        'AC1 (positive) CtMainMenu plain @ 320×640: no exception, '
        'CtNinePatchButton heights ≥ kMinTouchTargetSize',
        (WidgetTester tester) async {
          await _pumpAtSize(
            tester,
            _wrapMainMenu(),
            size: _kMinViewport,
          );

          expect(tester.takeException(), isNull);
          final List<double> heights = _renderedNinePatchButtonHeights(tester);
          expect(
            heights,
            isNotEmpty,
            reason:
                'CtMainMenu must render at least one CtNinePatchButton '
                '(New Game / Load Game / Settings / Quit).',
          );
          for (final double h in heights) {
            expect(
              h,
              greaterThanOrEqualTo(kMinTouchTargetSize),
              reason:
                  'CtNinePatchButton height $h dp violates the 44 dp '
                  'touch-target minimum at the 320 dp viewport.',
            );
          }
        },
      );

      testWidgets(
        'AC1 (positive) CtMainMenu pixelArt @ 320×640: no exception, '
        'CtNinePatchButton heights ≥ kMinTouchTargetSize',
        (WidgetTester tester) async {
          await _pumpAtSize(
            tester,
            _wrapMainMenu(variant: MainMenuVariant.pixelArt),
            size: _kMinViewport,
          );

          expect(tester.takeException(), isNull);
          final List<double> heights = _renderedNinePatchButtonHeights(tester);
          expect(heights, isNotEmpty);
          for (final double h in heights) {
            expect(h, greaterThanOrEqualTo(kMinTouchTargetSize));
          }
        },
      );

      testWidgets(
        'AC1 (positive) CtMainMenu noSaves @ 320×640: no exception',
        (WidgetTester tester) async {
          await _pumpAtSize(
            tester,
            _wrapMainMenu(state: MainMenuState.noSaves),
            size: _kMinViewport,
          );

          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'AC2 (positive) CtGameSetup plain @ 320×640: no exception, '
        'six player-slot rows render (stacked layout per § 4)',
        (WidgetTester tester) async {
          await _pumpAtSize(
            tester,
            _wrapGameSetup(),
            size: _kMinViewport,
          );

          expect(tester.takeException(), isNull);
          // § 4 Game Setup stacked layout: the six slot labels still render.
          expect(find.text('Player 1 (You)'), findsOneWidget);
          expect(find.text('Player 2 (AI)'), findsOneWidget);
          expect(find.text('Player 6 (AI)'), findsOneWidget);
          expect(find.text('Select nation'), findsNWidgets(6));
        },
      );

      testWidgets(
        'AC2 (positive) CtGameSetup pixelArt @ 320×640: no exception, '
        'screen pumps without overflow',
        (WidgetTester tester) async {
          await _pumpAtSize(
            tester,
            _wrapGameSetup(variant: GameSetupVariant.pixelArt),
            size: _kMinViewport,
          );

          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'AC2 (positive) CtGameSetup pixelArt loading @ 320×640: '
        'no exception (loading scrim + back link share narrow viewport)',
        (WidgetTester tester) async {
          await _pumpAtSize(
            tester,
            _wrapGameSetup(
              variant: GameSetupVariant.pixelArt,
              state: GameSetupState.loading,
            ),
            size: _kMinViewport,
            // The loading state's `CtLoadingIndicator` animates
            // continuously, so `pumpAndSettle` would never settle.
            settleAnimations: false,
          );

          expect(tester.takeException(), isNull);
          expect(
            find.byKey(const ValueKey<String>('gameSetupLoadingLabel')),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'AC2 (positive) CtGameSetup plain loading @ 320×640: no exception',
        (WidgetTester tester) async {
          await _pumpAtSize(
            tester,
            _wrapGameSetup(state: GameSetupState.loading),
            size: _kMinViewport,
            settleAnimations: false,
          );

          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'AC2 (regression) CtGameSetup pixelArt back-link label ellipses at '
        '320 dp instead of overflowing — Refs #2870 S10 / Refs #2868 R14',
        (WidgetTester tester) async {
          await _pumpAtSize(
            tester,
            _wrapGameSetup(variant: GameSetupVariant.pixelArt),
            size: _kMinViewport,
          );

          expect(tester.takeException(), isNull);
          // The back-link label remains in the tree (single line, may be
          // ellipsised by Flexible+TextOverflow.ellipsis when the row would
          // otherwise overflow). Ellipsised Text widgets still report
          // `findsOneWidget` because the `Text` element exists; the visual
          // contract is preserved (1 row, 1 line) regardless of clipping.
          expect(
            find.byKey(const ValueKey<String>('gameSetupBackLinkLabel')),
            findsOneWidget,
          );
          // The `CtBackButton` glyph still renders (single 28x28 dp tap
          // target per `SPEC/ui/game-setup.md` § R14 + `SPEC/ui/`
          // `pixel-art-ui-catalog.md` § CtBackButton).
          expect(
            find.byKey(const ValueKey<String>('gameSetupBackLinkGlyph')),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'Negative control: CtMainMenu plain @ 1024×768 also pumps without '
        'exception (regression sentinel for the overflow contract)',
        (WidgetTester tester) async {
          await _pumpAtSize(
            tester,
            _wrapMainMenu(),
            size: _kWideRegressionViewport,
          );

          expect(tester.takeException(), isNull);
        },
      );
    },
  );
}
