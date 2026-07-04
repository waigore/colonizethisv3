import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';

const kEconomyPreviewWorkTileKey = 'oldWorld|ow|p1|0|0';

typedef MaterialBackedWorkTarget = ({
  String target,
  String unitType,
  Map<String, int> cost,
});

/// Work targets exercised by pending-build-cost preview tests.
final kMaterialBackedWorkTargets = <MaterialBackedWorkTarget>[
  (
    target: kWorkTargetBuildImprovement,
    unitType: kUnitTypeBuilder,
    cost: {
      CommodityCatalog.lumber.id: 1,
      CommodityCatalog.castIron.id: 1,
    },
  ),
  (
    target: kWorkTargetUpgradeTown,
    unitType: kUnitTypeBuilder,
    cost: {
      CommodityCatalog.lumber.id: 1,
      CommodityCatalog.castIron.id: 1,
    },
  ),
  (
    target: kWorkTargetBuildRoad,
    unitType: kUnitTypeEngineer,
    cost: {
      CommodityCatalog.lumber.id: 1,
      CommodityCatalog.castIron.id: 1,
    },
  ),
  (
    target: kWorkTargetBuildPort,
    unitType: kUnitTypeEngineer,
    cost: {
      CommodityCatalog.lumber.id: 5,
      CommodityCatalog.castIron.id: 5,
    },
  ),
  (
    target: kWorkTargetBuildFort,
    unitType: kUnitTypeEngineer,
    cost: {
      CommodityCatalog.lumber.id: 3,
      CommodityCatalog.bronze.id: 3,
    },
  ),
  (
    target: kWorkTargetBuildRail,
    unitType: kUnitTypeRailBuilder,
    cost: {
      CommodityCatalog.lumber.id: 2,
      CommodityCatalog.steel.id: 2,
    },
  ),
];

Stockpile validWorkPreviewStockpile() {
  return const Stockpile()
      .applyDelta(CommodityCatalog.lumber.id, 50)
      .applyDelta(CommodityCatalog.castIron.id, 50)
      .applyDelta(CommodityCatalog.bronze.id, 50)
      .applyDelta(CommodityCatalog.steel.id, 50);
}

void expectPhaseDeltasSumToNet({
  required Game game,
  required String playerId,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  Orders currentOrders = const Orders(),
  List<AssignedRecipe> defaultAssignments = const [],
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
}) {
  final inputs = economyPreviewInputs(
    extractedByPlayerId: extractedByPlayerId,
    currentOrders: currentOrders,
    defaultAssignments: defaultAssignments,
    defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
  );
  final phases = previewStockpilePhaseDeltasByCommodityForPlayer(
    game: game,
    topology: const MapTopology(),
    playerId: playerId,
    inputs: inputs,
  );
  final net = previewStockpileNetDeltaByCommodityForPlayer(
    game: game,
    topology: const MapTopology(),
    playerId: playerId,
    inputs: inputs,
  );
  final keys = <String>{};
  for (final m in phases.values) {
    keys.addAll(m.keys);
  }
  keys.addAll(net.keys);
  for (final c in keys) {
    var sum = 0;
    for (final p in EconomyPreviewStockpilePhase.values) {
      sum += phases[p]?[c] ?? 0;
    }
    expect(sum, net[c] ?? 0, reason: 'commodity $c phase sum vs net');
  }
}

void runPendingWorkTargetDeductionScenarios() {
  for (final t in kMaterialBackedWorkTargets) {
    final game = TestFixtures.singlePlayerWorkPreviewGame(
      playerStockpile: validWorkPreviewStockpile(),
      units: [
        Unit(
          id: 'u1',
          type: t.unitType,
          ownerId: 'p1',
          locationProvinceId: 'ow|p1',
          tileKey: kEconomyPreviewWorkTileKey,
        ),
      ],
      tileState: const TileMapState().setImprovement(kEconomyPreviewWorkTileKey, 0),
    );
    final orders = Orders(
      workOrdersByPlayerId: {
        'p1': [
          WorkOrder(
            unitId: 'u1',
            target: t.target,
            targetTileKey: kEconomyPreviewWorkTileKey,
          ),
        ],
      },
    );
    final phases = previewStockpilePhaseDeltasByCommodityForPlayer(
      game: game,
      topology: const MapTopology(),
      playerId: 'p1',
      inputs: economyPreviewInputs(currentOrders: orders),
    );
    final pending = phases[EconomyPreviewStockpilePhase.pendingBuildCosts]!;
    for (final e in t.cost.entries) {
      expect(
        pending[e.key],
        -e.value,
        reason: 'target=${t.target} commodity=${e.key}',
      );
    }
    expectPhaseDeltasSumToNet(
      game: game,
      playerId: 'p1',
      currentOrders: orders,
    );
  }
}
