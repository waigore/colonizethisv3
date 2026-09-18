// Goldens for labour-limited Allocation affordance → Labour Controls.
// SPEC/ui/production-panel.md § Affordance labour-limited goldens (Refs #4780).

import 'package:colonizethis_app/features/game/widgets/production/production_labour_controls_highlight.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_labour_helpers.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_panel.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'production_panel_test_support.dart';
import 'widget_test_pumps.dart';

ProductionLabourCallbacks _noopLabourCallbacks() => ProductionLabourCallbacks(
  onAppendRecruitOrder: (_) {},
  onPopLastRecruitOrder: (_) {},
  onDisband: (_) {},
);

Player _labourLimitedPlayer() {
  final base = productionPanelTestFullPlayer();
  return base.copyWith(workerPool: const WorkerPool(peasants: 2));
}

Future<void> _pumpAndTapLabourFocusGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Size physicalSize,
  required bool canEditLabour,
}) async {
  final player = _labourLimitedPlayer();
  final game = productionPanelTestGameFor(player);
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: physicalSize,
    includeLocalizations: true,
    child: ProductionPanel(
      game: game,
      player: player,
      desiredOutputByRecipe: const {},
      netDeltasByCommodity: const {},
      labourReadiness: labourReadinessForPlayer(player),
      forcesFeeding: forcesFeedingForPlayer(player),
      onDesiredOutputChanged: (_) {},
      currentOrders: const Orders(),
      labourCallbacks: _noopLabourCallbacks(),
      canEditLabour: canEditLabour,
    ),
  );
  await pumpSettleCapped(tester);
  final affordance = find.byKey(
    const ValueKey<String>('production_affordance_lumber_from_timber'),
  );
  expect(affordance, findsOneWidget);
  await tester.ensureVisible(affordance);
  await tester.tap(affordance);
  await pumpSyncFrames(tester);
  expect(
    find.byKey(ProductionLabourControlsHighlight.highlightKey),
    findsOneWidget,
  );
}

void main() {
  suppressLogsForTests();

  testWidgets('golden: labour-limited tap wide (#4780)', (tester) async {
    const boundaryKey = ValueKey('production_labour_focus_wide_golden');
    await _pumpAndTapLabourFocusGolden(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(800, 500),
      canEditLabour: true,
    );
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/production_labour_focus_wide.png'),
    );
  });

  testWidgets('golden: labour-limited tap 320 dp (#4780)', (tester) async {
    const boundaryKey = ValueKey('production_labour_focus_320_golden');
    await _pumpAndTapLabourFocusGolden(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(320, 640),
      canEditLabour: true,
    );
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/production_labour_focus_320dp.png'),
    );
  });

  testWidgets('golden: labour-limited tap observe (#4780)', (tester) async {
    const boundaryKey = ValueKey('production_labour_focus_observe_golden');
    await _pumpAndTapLabourFocusGolden(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(800, 500),
      canEditLabour: false,
    );
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/production_labour_focus_observe.png'),
    );
  });
}
