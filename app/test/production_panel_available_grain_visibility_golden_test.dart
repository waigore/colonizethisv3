// Golden: Production Available Grain quantity 0 visibility (GAME20001 / Refs #3999).
// Grid alignment golden: production_panel_available_alignment_golden_test.dart.

import 'package:colonizethis_app/features/game/widgets/production/production_panel.dart';
import 'package:colonizethis_app/widgets/ct_resource_cell.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'production_panel_test_support.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'golden: Production Available shows Grain quantity 0 with delta '
    'at wide layout (Refs #3999)',
    (WidgetTester tester) async {
      const Key boundaryKey = ValueKey<String>(
        'production_available_grain_visibility_golden',
      );
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
