import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';
import 'economy_stockpile_preview_test_support.dart';

void runPendingWorkTargetSkipScenarios() {
  for (final t in kMaterialBackedWorkTargets) {
    expectEconomyPreviewPendingBuildCostsEmpty(
      game: TestFixtures.singlePlayerWorkPreviewGame(
        playerStockpile: validWorkPreviewStockpile(),
        units: [],
        tileState: const TileMapState().setImprovement(
          kEconomyPreviewWorkTileKey,
          0,
        ),
      ),
      orders: economyPreviewSingleWorkOrder(
        unitId: 'missing',
        target: t.target,
      ),
      reason: 'missing unit target=${t.target}',
    );

    expectEconomyPreviewPendingBuildCostsEmpty(
      game: economyPreviewWorkUnitGame(
        unitId: 'u1',
        unitType: t.unitType,
        status: UnitStatus.working,
        currentWork: const CurrentWork(
          workTarget: kWorkTargetBuildImprovement,
          tileKey: kEconomyPreviewWorkTileKey,
          totalTurns: 1,
          remainingTurns: 1,
        ),
      ),
      orders: economyPreviewSingleWorkOrder(unitId: 'u1', target: t.target),
      reason: 'busy unit target=${t.target}',
    );

    expectEconomyPreviewPendingBuildCostsEmpty(
      game: economyPreviewWorkUnitGame(
        unitId: 'u1',
        unitType: 'peasant_levies',
      ),
      orders: economyPreviewSingleWorkOrder(unitId: 'u1', target: t.target),
      reason: 'disallowed unit target=${t.target}',
    );

    expectEconomyPreviewPendingBuildCostsEmpty(
      game: economyPreviewWorkUnitGame(unitId: 'u1', unitType: t.unitType),
      orders: economyPreviewSingleWorkOrder(
        unitId: 'u1',
        target: t.target,
        targetTileKey: '',
      ),
      reason: 'invalid target key target=${t.target}',
    );

    final insufficientStockpile = t.cost.entries.fold<Stockpile>(
      const Stockpile(),
      (acc, e) {
        final amount = e.key == t.cost.keys.first ? e.value - 1 : e.value;
        return acc.applyDelta(e.key, amount);
      },
    );
    final insufficientGame = economyPreviewWorkUnitGame(
      unitId: 'u1',
      unitType: t.unitType,
      playerStockpile: insufficientStockpile,
    );
    final insufficientOrders = economyPreviewSingleWorkOrder(
      unitId: 'u1',
      target: t.target,
    );
    expectEconomyPreviewPendingBuildCostsEmpty(
      game: insufficientGame,
      orders: insufficientOrders,
      reason: 'insufficient stockpile target=${t.target}',
    );
    expectPhaseDeltasSumToNet(
      game: insufficientGame,
      playerId: 'p1',
      currentOrders: insufficientOrders,
    );
  }
}
