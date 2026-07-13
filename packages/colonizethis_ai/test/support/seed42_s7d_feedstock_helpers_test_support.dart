// Shared Game factory for seed42 S7-D feedstock helper pin cases
// (Refs #3997 Phase 8).

import 'package:colonizethis_models/colonizethis_models.dart';

const kSeed42S7dFeedstockHelperPlayerId = 'gp1';

Game buildSeed42S7dFeedstockHelperGame({
  WorkerPool workers = const WorkerPool(),
  Stockpile stockpile = const Stockpile(),
  Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince =
      const {},
  Map<String, String> resourceByTileKey = const {},
  List<Province> oldWorldProvinces = const [],
  Map<String, int> improvementByTile = const {},
}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: oldWorldProvinces),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
      resourceByTileKey: resourceByTileKey,
      tileState: TileMapState(improvementByTile: improvementByTile),
    ),
    players: [
      Player(
        id: kSeed42S7dFeedstockHelperPlayerId,
        displayName: 'GP',
        isHuman: false,
        stockpile: stockpile,
        workerPool: workers,
      ),
    ],
  );
}
