// Visual goldens for Production Labour Controls cost/upkeep gists (#4432).
// SPEC/ui/production-panel.md § Labour Controls.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/production/production_labour_section.dart';

import 'golden_capture_harness.dart';
import 'production_labour_section_test_support.dart';
import 'production_labour_test_fixtures.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  testWidgets('golden: labour cost gist unlocked apprentice (#4432)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey('production_labour_cost_gist_golden');
    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(520, 360),
      includeLocalizations: true,
      child: SizedBox(
        width: 500,
        child: ProductionLabourSection(
          player: productionLabourSectionGpWithPool(
            peasants: 2,
            treasury: 500,
            stockpile: {
              CommodityCatalog.fabric.id: 4,
              CommodityCatalog.paper.id: 4,
            },
            techUnlocked: productionLabourApprenticeTech,
          ),
          currentOrders: const Orders(),
          canEdit: true,
          callbacks: ProductionLabourSectionCapture().asCallbacks(),
        ),
      ),
    );
    await pumpSettleCapped(tester);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/production_labour_cost_gist.png'),
    );
  });

  testWidgets('golden: labour cost gist 320 dp wrap (#4432)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey('production_labour_cost_gist_320_golden');
    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(320, 720),
      includeLocalizations: true,
      child: SizedBox(
        width: 300,
        child: ProductionLabourSection(
          player: productionLabourSectionGpWithPool(
            peasants: 2,
            treasury: 500,
            stockpile: {
              CommodityCatalog.fabric.id: 4,
              CommodityCatalog.paper.id: 4,
            },
            techUnlocked: productionLabourApprenticeTech,
          ),
          currentOrders: const Orders(),
          canEdit: true,
          callbacks: ProductionLabourSectionCapture().asCallbacks(),
        ),
      ),
    );
    await pumpSettleCapped(tester);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/production_labour_cost_gist_320dp.png'),
    );
  });
}
