// Pin the 320 dp minimum-viewport contract for the in-game panels covered by
// SPEC/ui/mobile-adaptation.md § 7 (Minimum-viewport pin) — extending the
// existing `mobile_320dp_min_viewport_test.dart` screen-level pins
// (CtMainMenu / CtGameSetup) to ProductionPanel, the additional surface
// called out in #2870 § Acceptance criteria ("no horizontal overflow at
// 320 dp on every covered screen"). Refs #2870 S10.
//
// These widget tests render `ProductionPanel` at exactly
// `kMinViewportWidth × 640` (320 × 640 dp) and assert:
//
//  * `WidgetTester.takeException()` is `null` so no `RenderFlex` overflow
//    exception (which Flutter surfaces via `FlutterError.onError`) escapes
//    the framework — the contract the existing screen-level pin file
//    relies on for CtMainMenu / CtGameSetup.
//  * Both the `Available` and `Allocation` section labels still render at
//    the minimum viewport so the panel's `_ProductionPanelNarrowLayout`
//    path (`MediaQuery.sizeOf(context).width < kNarrowBreakpoint` → 600 dp
//    threshold) has executed end-to-end without dropping content.
//  * A wide negative control at 1024 × 768 dp pumps without exception
//    against the same fixture so a regression in the overflow contract
//    upstream of the panel itself would be caught.
//
// DiplomacyPanel is intentionally **not** pinned at 320 dp here: an
// exploratory pass during this work found the existing narrow Column body
// still overflows the available width by ~162 dp at 320 dp (the
// faction-row info column does not wrap a long faction name + treaty
// chips inside `kMinViewportWidth`). That regression is captured in a
// dedicated follow-up note on #2870; once the diplomacy panel narrow
// body lays out cleanly at 320 dp a sibling test file (or this one) can
// add the corresponding pin.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// Refs #2870 S10.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/production_panel.dart';

import 'production_panel_test_fixtures.dart';

/// Minimum supported viewport dimensions for SPEC/ui/mobile-adaptation.md
/// § 7. Width matches [kMinViewportWidth]; height (640 dp) mirrors the
/// existing screen-level pin file.
const Size _kMinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel — comfortably above every per-screen breakpoint
/// so the same panel renders its wide layout. If a future refactor flips
/// the overflow contract upstream, the contrast with the 320 dp positive
/// pins keeps the regression signal honest. Mirrors the same pattern in
/// `mobile_320dp_min_viewport_test.dart`.
const Size _kWideRegressionViewport = Size(1024, 768);

/// Pumps [child] at [size] under the running editorial-monocle theme.
/// Sets the surface size (so the binding's render flex math sees the
/// minimum viewport) and overrides MediaQuery so widget code that reads
/// `MediaQuery.sizeOf(context).width` resolves to the same value — the
/// pattern used by `mobile_320dp_min_viewport_test.dart` and
/// `victory_overlay_narrow_test.dart`.
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

Widget _buildProductionPanel(Player player) {
  return ProductionPanel(
    game: productionPanelTestGameFor(player),
    player: player,
    desiredOutputByRecipe: const <String, int>{},
    netDeltasByCommodity: const <String, int>{},
    onDesiredOutputChanged: (_) {},
  );
}

void main() {
  suppressLogsForTests();

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — ProductionPanel @ 320 dp '
    '(Refs #2870 S10)',
    () {
      late Player fullPlayer;
      late Player partialPlayer;

      setUpAll(() {
        fullPlayer = productionPanelTestFullPlayer();
        partialPlayer = productionPanelTestPartialPlayer();
      });

      testWidgets(
        'AC (positive) ProductionPanel (full player) @ 320×640: no '
        'RenderFlex overflow exception, Available + Allocation labels both '
        'render',
        (WidgetTester tester) async {
          await _pumpAtSize(
            tester,
            _buildProductionPanel(fullPlayer),
            size: _kMinViewport,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: ProductionPanel must not '
                'emit a RenderFlex overflow exception at kMinViewportWidth '
                '(320 dp). The wide layout (Padding + Row with Expanded '
                'flex 1 + Expanded flex 2) would overflow at 320 dp; the '
                'narrow `_ProductionPanelNarrowLayout` (SingleChildScrollView '
                '> Column) is selected at < kNarrowBreakpoint (600 dp) and '
                'must lay out without overflowing.',
          );
          expect(find.text('Available'), findsOneWidget);
          expect(find.text('Allocation'), findsOneWidget);
        },
      );

      testWidgets(
        'AC (positive) ProductionPanel (partial player) @ 320×640: no '
        'exception (regression guard for the partial-stockpile path the '
        'existing production_panel_test exercises at wider widths)',
        (WidgetTester tester) async {
          await _pumpAtSize(
            tester,
            _buildProductionPanel(partialPlayer),
            size: _kMinViewport,
          );

          expect(tester.takeException(), isNull);
          expect(find.text('Available'), findsOneWidget);
          expect(find.text('Allocation'), findsOneWidget);
        },
      );

      testWidgets(
        'Negative control: ProductionPanel (full player) @ 1024×768 also '
        'pumps without exception (regression sentinel for the overflow '
        'contract — keeps the 320 dp positive pins meaningful)',
        (WidgetTester tester) async {
          await _pumpAtSize(
            tester,
            _buildProductionPanel(fullPlayer),
            size: _kWideRegressionViewport,
          );

          expect(tester.takeException(), isNull);
          expect(find.text('Available'), findsOneWidget);
          expect(find.text('Allocation'), findsOneWidget);
        },
      );
    },
  );
}
