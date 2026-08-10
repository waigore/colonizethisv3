// Shared Game fixtures for growth_stage industry counsel characterization pin
// (Refs #4310 Slice C).

import 'package:colonizethis_models/colonizethis_models.dart';

Game growthStageIndustryCounselFeedstockTileGame() {
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
