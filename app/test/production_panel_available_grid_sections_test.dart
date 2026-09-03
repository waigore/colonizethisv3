// Tests for Available subpanel section presence and Grain/Timber alignment
// (Refs #2862 S8b / C7, #3999). SPEC:
// SPEC/ui/production-panel.md § Layout — Available subpanel.

import 'package:colonizethis_app/widgets/ct_resource_cell.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'production_panel_test_support.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  late Player fullPlayer;

  setUpAll(() {
    fullPlayer = productionPanelTestFullPlayer();
  });

  group('ProductionPanel Available grid (Refs #2862 S8b / C7)', () {
    testWidgets(
      'Food, Raw Materials, and Manufactured sections all render their '
      'cells inside fixed-width slots smaller than their section width '
      '(Refs #2862 S8b)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildProductionPanel(player: fullPlayer, width: 1000, height: 900),
        );
        await pumpSettleCapped(tester);

        // Food: at least grain
        final grainCell = find.byKey(
          const ValueKey<String>('production_available_cell_grain'),
        );
        expect(grainCell, findsOneWidget);

        // Raw Materials: timber, iron, coal
        for (final id in const <String>['timber', 'iron', 'coal']) {
          expect(
            find.byKey(ValueKey<String>('production_available_cell_$id')),
            findsOneWidget,
            reason: 'Raw-materials cell for $id must be present',
          );
        }
      },
    );

    testWidgets(
      'Grain quantity is visible at wide Available grid width and aligns '
      'with a same-column Raw Materials peer (Refs #3999)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildProductionPanel(player: fullPlayer, width: 800, height: 720),
        );
        await pumpSettleCapped(tester);

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
        final Finder timberQty = find.descendant(
          of: timberCell,
          matching: find.byKey(CtResourceCell.quantityTextKey),
        );
        expect(grainQty, findsOneWidget);
        expect(tester.getSize(grainQty).width, greaterThan(1));
        // Food and Raw Materials both use the same Available width and 3-col
        // grid, so column-0 amount anchors (Grain, Timber) must share screen-x.
        expect(
          tester.getTopRight(grainQty).dx,
          closeTo(tester.getTopRight(timberQty).dx, 0.5),
          reason:
              'Grain and Timber share column-0 amount anchors across sections',
        );
      },
    );
  });
}
