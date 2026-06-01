// Pin the 320 dp minimum-viewport contract for the
// `ProductionCommodityBreakdownDialog` (PROD20001) read-only commodity
// breakdown modal opened from `ProductionScreen` — extending the existing
// screen-, panel-, dialog-, and unit-panel-level pins
// (`mobile_320dp_min_viewport_test.dart`,
// `panels_320dp_min_viewport_test.dart`,
// `dialogs_320dp_min_viewport_test.dart`,
// `unit_panels_320dp_min_viewport_test.dart`,
// `trade_screen_320dp_min_viewport_test.dart`,
// `technology_screen_320dp_min_viewport_test.dart`,
// `diplomacy_detail_screen_320dp_min_viewport_test.dart`,
// `quick_battle_screen_320dp_min_viewport_test.dart`) to the in-game
// production-panel breakdown dialog.
//
// `ProductionCommodityBreakdownDialog`
// (`app/lib/features/game/widgets/production_commodity_breakdown_dialog.dart`)
// mounts its chrome via [CtDialogShell] with `maxWidth: 720` and
// `maxHeight: 560`. At `kMinViewportWidth` (320 dp) the outer
// `Dialog.insetPadding: 16` dominates the configured `maxWidth`, so the
// available content area collapses to ~288 dp. The body wraps the
// per-commodity `DataTable` (1 commodity column + one per
// `EconomyPreviewStockpilePhase` + a trailing total column) inside a
// horizontally-scrollable `Scrollbar` / `SingleChildScrollView` per
// `SPEC/ui/production-commodity-breakdown-dialog.md` § Layout / wireframe
// (Wide-table state). At narrow widths that horizontal scroll affordance
// is the contract that keeps the dialog inside the ~288 dp content
// column without `RenderFlex` overflow, so the title, the wide table
// inside its scroll viewport, and the trailing right-aligned `Close`
// `CtNinePatchButton` must all lay out without overflow.
//
// Each positive test asserts:
//
//  * `WidgetTester.takeException()` is `null` so no `RenderFlex` overflow
//    exception (which Flutter surfaces via `FlutterError.onError`)
//    escapes the framework — the contract every other
//    `*_320dp_min_viewport_test.dart` file relies on.
//  * The localized `Commodity breakdown` title and the trailing `Close`
//    `CtNinePatchButton` both render so the dialog chrome is actually
//    exercised at the 320 dp viewport.
//  * Exactly one `DataTable` is mounted (the body shape from the screen
//    spec is preserved) and its column count equals
//    `1 + EconomyPreviewStockpilePhase.values.length + 1` — the wide
//    table that motivates the horizontal `Scrollbar` lives inside the
//    `SingleChildScrollView`, not collapsed away at narrow widths.
//  * A horizontal-axis `Scrollbar` + `SingleChildScrollView` is present
//    so the wide table is reachable at narrow widths instead of being
//    clipped (the SPEC's "Wide table" state).
//
// The wide negative control at 1024 × 768 dp pumps the same fixture so
// a regression in the host overflow contract upstream of
// `ProductionCommodityBreakdownDialog` itself would still surface.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// SPEC: `SPEC/ui/production-commodity-breakdown-dialog.md` § Layout /
// wireframe and § Acceptance Criteria (320 dp positive + wide regression
// pins).
// Refs #2870 S10 (no horizontal overflow at 320 dp on every covered
// screen).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/production_commodity_breakdown_dialog.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimum supported viewport dimensions for SPEC/ui/mobile-adaptation.md
/// § 7. Width matches [kMinViewportWidth]; height (640 dp) mirrors the
/// existing screen-, panel-, dialog-, and unit-panel-level pin files.
const Size _kMinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel — comfortably above every per-screen
/// breakpoint so the same dialog renders its default chrome. Mirrors
/// the contract used by every other `*_320dp_min_viewport_test.dart`
/// file in this directory.
const Size _kWideRegressionViewport = Size(1024, 768);

/// Pumps the [ProductionCommodityBreakdownDialog] at [size] under the
/// running editorial-monocle theme. Sets the surface size (so the
/// binding's render-flex math sees the minimum viewport) and overrides
/// MediaQuery so widget code that reads `MediaQuery.sizeOf(context).width`
/// resolves to the same value — the pattern already used by every other
/// `*_320dp_min_viewport_test.dart` file.
///
/// Wraps the dialog behind a launcher button (mirroring the helper used
/// by `production_commodity_breakdown_dialog_spec_test.dart`) so the
/// chrome under test is the dialog's own [CtDialogShell] layout at the
/// narrow viewport, not the `showDialog` route plumbing (already covered
/// by the spec test). The launcher tap drives the standard `showDialog`
/// path with the canonical `EditorialMonoclePalette.dialogScrim` barrier
/// per SPEC § Modal barrier.
Future<void> _pumpDialogAtSize(
  WidgetTester tester, {
  required Size size,
}) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(size);

  final result = getDebugInitGameResult();
  final game = result.game;
  final humanPlayerId = game.players.firstWhere((p) => p.isHuman).id;
  final player = game.playerById(humanPlayerId) ?? game.players.first;

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppThemes.editorialMonocle,
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    barrierColor: EditorialMonoclePalette.dialogScrim,
                    builder: (_) => ProductionCommodityBreakdownDialog(
                      game: game,
                      player: player,
                      topology: result.combinedTopology,
                      tileMapByRegion: result.tileMapByRegion,
                      currentOrders: const Orders(),
                    ),
                  );
                },
                // ignore: avoid_hardcoded_strings_in_widgets
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  suppressLogsForTests();

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — ProductionCommodityBreakdownDialog '
    '@ 320 dp (Refs #2870 S8/S10)',
    () {
      testWidgets(
        'AC (positive) ProductionCommodityBreakdownDialog @ 320×640: no '
        'RenderFlex overflow exception, title + Close action render',
        (WidgetTester tester) async {
          await _pumpDialogAtSize(tester, size: _kMinViewport);

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: '
                'ProductionCommodityBreakdownDialog MUST NOT emit a '
                'RenderFlex overflow exception at kMinViewportWidth '
                '(320 dp). The CtDialogShell content column at 320 dp '
                'collapses to ~288 dp — the title row, the '
                'horizontally-scrollable DataTable body, and the '
                'trailing right-aligned Close action must lay out '
                'inside that column without horizontal overflow per '
                'SPEC/ui/production-commodity-breakdown-dialog.md '
                '§ Layout / wireframe.',
          );

          // Localized PROD20001 title from `production_breakdown_title`.
          expect(find.text('Commodity breakdown'), findsOneWidget);

          // Trailing right-aligned Close action — the only interactive
          // affordance on the read-only dialog. The SPEC layout pins it
          // as a `CtNinePatchButton` so the localized `common_close`
          // label must render through `CtNinePatchButton` at the
          // minimum viewport too.
          expect(
            find.widgetWithText(CtNinePatchButton, 'Close'),
            findsOneWidget,
            reason:
                'Trailing Close action MUST render as a CtNinePatchButton '
                'descendant at 320 dp so the dialog remains dismissable '
                'inside the ~288 dp CtDialogShell content column.',
          );
        },
      );

      testWidgets(
        'AC (positive) ProductionCommodityBreakdownDialog @ 320×640: '
        'exactly one DataTable renders with '
        '1 + EconomyPreviewStockpilePhase.values.length + 1 columns and '
        'is wrapped in a horizontal Scrollbar + SingleChildScrollView '
        '(the Wide-table state from SPEC § States and variants)',
        (WidgetTester tester) async {
          await _pumpDialogAtSize(tester, size: _kMinViewport);

          expect(tester.takeException(), isNull);

          // The wide DataTable body shape from
          // SPEC/ui/production-commodity-breakdown-dialog.md
          // § Widget contract MUST survive the narrow viewport — the
          // SPEC's horizontal-scroll contract relies on the full
          // column set being present so the Scrollbar / scroll
          // viewport actually has overflow content to scroll.
          expect(find.byType(DataTable), findsOneWidget);
          final DataTable table = tester.widget<DataTable>(
            find.byType(DataTable),
          );
          final int expectedColumns =
              1 + EconomyPreviewStockpilePhase.values.length + 1;
          expect(
            table.columns.length,
            expectedColumns,
            reason:
                'SPEC/ui/production-commodity-breakdown-dialog.md '
                '§ Acceptance Criteria: the DataTable column count MUST '
                'remain `1 + EconomyPreviewStockpilePhase.values.length '
                '+ 1` (commodity + per-phase + total) even at the 320 dp '
                'minimum viewport. A regression that dropped phase '
                'columns under narrow widths would silently break the '
                'preview contract.',
          );

          // The horizontal-axis Scrollbar + SingleChildScrollView pair
          // is the SPEC's Wide-table state escape hatch. At 320 dp the
          // table is wider than the ~288 dp content column, so this
          // affordance MUST be present and actually horizontal.
          final Finder horizontalScrollView = find.byWidgetPredicate(
            (Widget w) =>
                w is SingleChildScrollView &&
                w.scrollDirection == Axis.horizontal,
          );
          expect(
            horizontalScrollView,
            findsOneWidget,
            reason:
                'SPEC § Layout / wireframe: the DataTable MUST live '
                'inside a horizontal SingleChildScrollView at narrow '
                'widths so the wide table stays reachable without '
                'horizontal RenderFlex overflow.',
          );
          expect(
            find.byType(Scrollbar),
            findsWidgets,
            reason:
                'SPEC § Layout / wireframe: the Scrollbar wrapping the '
                'horizontal scroll viewport MUST mount at 320 dp so the '
                'scroll affordance is visible to the user (per the '
                'dialog state\'s `thumbVisibility: true`).',
          );
        },
      );

      testWidgets(
        'AC (positive) ProductionCommodityBreakdownDialog @ 320×640: at '
        'least one section header (Food / Raw materials / Manufactured) '
        'renders so the body sections from SPEC § Layout / wireframe '
        'still mount at the minimum viewport',
        (WidgetTester tester) async {
          await _pumpDialogAtSize(tester, size: _kMinViewport);

          expect(tester.takeException(), isNull);

          // The dialog renders three sections in fixed order — Food,
          // Raw materials, Manufactured. Section headers use small-caps
          // styling so the rendered Text data is the upper-cased label.
          // The `getDebugInitGameResult()` fixture has non-trivial
          // production setups, so at least one section header MUST
          // render at 320 dp. Asserting on the localized labels
          // (upper-cased by `_sectionHeaderCell`) keeps the AC robust
          // to ruleset commodity rebalances.
          expect(
            find.byWidgetPredicate(
              (Widget w) =>
                  w is Text &&
                  w.data != null &&
                  (w.data == 'FOOD' ||
                      w.data == 'RAW MATERIALS' ||
                      w.data == 'MANUFACTURED'),
            ),
            findsWidgets,
            reason:
                'SPEC § Layout / wireframe: at least one of the three '
                'section headers (Food / Raw materials / Manufactured) '
                'MUST mount inside the DataTable body at the 320 dp '
                'minimum viewport.',
          );
        },
      );
    },
  );

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — ProductionCommodityBreakdownDialog '
    'wide regression sentinel (Refs #2870 S8/S10)',
    () {
      testWidgets(
        'Negative control: ProductionCommodityBreakdownDialog @ '
        '1024×768 also pumps without exception (regression sentinel '
        'for the overflow contract — keeps the 320 dp positive pins '
        'meaningful)',
        (WidgetTester tester) async {
          await _pumpDialogAtSize(
            tester,
            size: _kWideRegressionViewport,
          );

          expect(tester.takeException(), isNull);
          expect(find.text('Commodity breakdown'), findsOneWidget);
          expect(
            find.widgetWithText(CtNinePatchButton, 'Close'),
            findsOneWidget,
          );
        },
      );
    },
  );
}
