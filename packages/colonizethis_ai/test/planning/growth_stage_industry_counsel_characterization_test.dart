// Growth-stage helpers delegate to shared industry counsel economy modules (Refs #4189).

import 'package:colonizethis_ai/src/planning/growth_stage.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

Game _feedstockTileGame() {
  const tileKey = 'oldWorld|p1|0|0';
  return Game(
    id: 'g-feedstock',
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP',
        isHuman: true,
        stockpile: const Stockpile(),
        workerPool: const WorkerPool(),
      ),
    ],
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: const {
        'oldWorld': {'p1': [tileKey]},
      },
      resourceByTileKey: const {tileKey: 'timber'},
      tileState: const TileMapState(
        improvementByTile: {tileKey: 1},
      ),
    ),
  );
}

void main() {
  group('growth stage industry counsel delegation', () {
    test('categoryPriorityForOutput matches industryCounselCategoryPriorityForOutput',
        () {
      const stage = GrowthStage(
        workerGrowthPriority: 0.8,
        infrastructurePriority: 0.4,
        resourceProductionPriority: 0.6,
        militaryPriority: 0.2,
      );
      const counselStage = IndustryCounselGrowthStage(
        workerGrowthPriority: 0.8,
        infrastructurePriority: 0.4,
        resourceProductionPriority: 0.6,
        militaryPriority: 0.2,
      );
      for (final outputId in [
        CommodityCatalog.fabric.id,
        CommodityCatalog.lumber.id,
        CommodityCatalog.steel.id,
        CommodityCatalog.grain.id,
      ]) {
        expect(
          categoryPriorityForOutput(outputId, stage),
          industryCounselCategoryPriorityForOutput(outputId, counselStage),
        );
      }
    });

    test('prospectedImprovedFeedstockTileCount matches economy helper', () {
      final game = _feedstockTileGame();
      expect(
        prospectedImprovedFeedstockTileCount(game, 'gp1'),
        industryCounselProspectedImprovedFeedstockTileCount(game, 'gp1'),
      );
    });
  });
}
