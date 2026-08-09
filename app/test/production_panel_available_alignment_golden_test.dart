// Visual goldens for Production Available panel-wide amount alignment and
// quantity visibility (GAME20001 / Refs #3999).
//
// Structural geometry is pinned by `ct_resource_cell_test.dart` and
// `production_panel_available_grid_test.dart`. This suite adds
// `matchesGoldenFile` proof for mixed-length labels, zero quantities, signed
// deltas, and Grain visibility at representative Available grid widths.
// SPEC: SPEC/ui/production-panel.md § Acceptance Criteria (Refs #3999).

import 'package:colonizethis_app/features/game/widgets/production/production_available_grid.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_panel.dart';
import 'package:colonizethis_app/widgets/ct_resource_cell.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:colonizethis_app_fixtures/demo/production_panel_demo_data.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'production_panel_test_support.dart';
import 'golden_capture_harness.dart';
import 'widget_test_pumps.dart';

Widget _tinyIcon(BuildContext context) => const SizedBox(
      key: Key('available_alignment_golden_icon'),
      width: 20,
      height: 20,
    );

double _quantityRight(WidgetTester tester, Finder cellFinder) {
  final Finder qty = find.descendant(
    of: cellFinder,
    matching: find.byKey(CtResourceCell.quantityTextKey),
  );
  expect(qty, findsOneWidget);
  return tester.getTopRight(qty).dx;
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'golden: Available mixed labels + deltas align amounts at grid width '
    '(Refs #3999)',
    (WidgetTester tester) async {
      // Representative Available 3-column slot (~800 dp wide Production).
      const double cellWidth = 120;
      // 3 columns × 120 + 2 × 6 spacing.
      const double gridWidth =
          cellWidth * 3 + AvailableCellGrid.columnSpacing * 2;
      const Key boundaryKey = ValueKey<String>(
        'production_available_alignment_grid_golden',
      );
      const Key tinKey = ValueKey<String>('align_tin');
      const Key sugarKey = ValueKey<String>('align_sugar');
      const Key refinedKey = ValueKey<String>('align_refined');
      const Key grainKey = ValueKey<String>('align_grain');
      const Key meatKey = ValueKey<String>('align_meat');
      const Key woolKey = ValueKey<String>('align_wool');

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(420, 360),
        center: false,
        child: Padding(
          padding: const EdgeInsets.all(CtSpacing.m),
          child: SizedBox(
            width: gridWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Same column width, stacked — label-length invariant.
                SizedBox(
                  width: cellWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      CtResourceCell(
                        key: tinKey,
                        iconBuilder: _tinyIcon,
                        name: 'Tin',
                        quantity: 4,
                      ),
                      CtResourceCell(
                        key: sugarKey,
                        iconBuilder: _tinyIcon,
                        name: 'Sugar Cane',
                        quantity: 4,
                      ),
                      CtResourceCell(
                        key: refinedKey,
                        iconBuilder: _tinyIcon,
                        name: 'Refined Sugar',
                        quantity: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: CtSpacing.m),
                // Available-style 3-column grid with zero qty + deltas.
                AvailableCellGrid(
                  columnCount: kProductionAvailableCommodityGridColumns,
                  cells: <Widget>[
                    CtResourceCell(
                      key: grainKey,
                      iconBuilder: _tinyIcon,
                      name: 'Grain',
                      quantity: 0,
                      delta: -16,
                    ),
                    CtResourceCell(
                      key: meatKey,
                      iconBuilder: _tinyIcon,
                      name: 'Meat',
                      quantity: 0,
                    ),
                    CtResourceCell(
                      key: woolKey,
                      iconBuilder: _tinyIcon,
                      name: 'Wool',
                      quantity: 0,
                      delta: 12,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await pumpSettleCapped(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('0'), findsNWidgets(3));
      expect(find.text('-16'), findsOneWidget);
      expect(find.text('+12'), findsOneWidget);
      expect(find.text('4'), findsNWidgets(3));

      final double tinX = _quantityRight(tester, find.byKey(tinKey));
      final double sugarX = _quantityRight(tester, find.byKey(sugarKey));
      final double refinedX = _quantityRight(tester, find.byKey(refinedKey));
      expect(tinX, closeTo(sugarX, 0.5));
      expect(sugarX, closeTo(refinedX, 0.5));

      final Finder grainQty = find.descendant(
        of: find.byKey(grainKey),
        matching: find.byKey(CtResourceCell.quantityTextKey),
      );
      expect(tester.getSize(grainQty).width, greaterThan(1));
      // Meat (null delta) and Wool (+12) share quantity 0; Wool is col 2 —
      // delta must not hide quantity on Grain (col 0).
      expect(
        find.descendant(of: find.byKey(meatKey), matching: find.text('0')),
        findsOneWidget,
      );

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/production_available_amount_alignment_grid.png',
        ),
      );
    },
  );

  testWidgets(
    'golden: Production Available shows Grain quantity 0 with delta '
    'at wide layout (Refs #3999)',
    (WidgetTester tester) async {
      const Key boundaryKey = ValueKey<String>(
        'production_available_grain_visibility_golden',
      );
      // Grain has a signed delta; Timber does not. Visibility + inset parity
      // are asserted below (quantity anchors need not match across delta shapes).
      final Player player = Player(
        id: 'test_gp_grain_zero',
        displayName: 'Grain zero',
        isHuman: true,
        stockpile: Stockpile(
          quantities: <String, int>{
            CommodityCatalog.grain.id: 0,
            CommodityCatalog.meat.id: 0,
            CommodityCatalog.timber.id: 0,
            CommodityCatalog.iron.id: 100,
            CommodityCatalog.wool.id: 4,
            CommodityCatalog.tin.id: 4,
            CommodityCatalog.sugarCane.id: 4,
            CommodityCatalog.refinedSugar.id: 4,
            CommodityCatalog.coal.id: 60,
            CommodityCatalog.cotton.id: 80,
            CommodityCatalog.lumber.id: 50,
            CommodityCatalog.castIron.id: 50,
            CommodityCatalog.fabric.id: 50,
          },
        ),
        workerPool: productionPanelTestFullWorkerPool,
      );
      final Game game = productionPanelTestGameFor(player);

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(800, 720),
        center: false,
        includeLocalizations: true,
        child: SizedBox(
          width: 800,
          height: 720,
          child: ProductionPanel(
            game: game,
            player: player,
            desiredOutputByRecipe: const <String, int>{},
            netDeltasByCommodity: <String, int>{
              CommodityCatalog.grain.id: -16,
              CommodityCatalog.meat.id: 12,
            },
            labourReadiness: labourReadinessForPlayer(player),
            forcesFeeding: forcesFeedingForPlayer(player),
            onDesiredOutputChanged: (_) {},
          ),
        ),
      );
      await pumpSettleCapped(tester);

      expect(tester.takeException(), isNull);

      final Finder grainCell = find.byKey(
        const ValueKey<String>('production_available_cell_grain'),
      );
      final Finder timberCell = find.byKey(
        const ValueKey<String>('production_available_cell_timber'),
      );
      expect(grainCell, findsOneWidget);
      expect(timberCell, findsOneWidget);

      final Finder grainQty = find.descendant(
        of: grainCell,
        matching: find.byKey(CtResourceCell.quantityTextKey),
      );
      expect(grainQty, findsOneWidget);
      expect(tester.getSize(grainQty).width, greaterThan(1));
      expect(
        find.descendant(of: grainCell, matching: find.text('0')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: grainCell, matching: find.text('-16')),
        findsOneWidget,
      );
      // Inset parity: painted trailing (delta) right inset ≈ leading icon inset.
      final Rect grainBox = tester.getRect(grainCell);
      final double grainIconLeft = tester
          .getTopLeft(
            find.descendant(
              of: grainCell,
              matching: find.byType(ResourceIcon),
            ),
          )
          .dx;
      final double grainDeltaRight = tester
          .getTopRight(
            find.descendant(
              of: grainCell,
              matching: find.byKey(CtResourceCell.deltaTextKey),
            ),
          )
          .dx;
      expect(
        grainIconLeft - grainBox.left,
        closeTo(grainBox.right - grainDeltaRight, 1.0),
      );
      // Timber (null delta, same qty 0) stays visible; quantity right edges are
      // not required to match Grain once a delta is present (inset-parity
      // follow-up on #3999).
      expect(
        find.descendant(
          of: timberCell,
          matching: find.byKey(CtResourceCell.quantityTextKey),
        ),
        findsOneWidget,
      );

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/production_panel_available_grain_visibility.png',
        ),
      );
    },
  );
}
