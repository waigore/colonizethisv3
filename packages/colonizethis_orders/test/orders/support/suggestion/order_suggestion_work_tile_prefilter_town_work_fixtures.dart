// Shared town-work prefilter scenario fixtures (Refs #3949 wave 3).

import 'package:colonizethis_models/colonizethis_models.dart';

const workTilePrefilterTownPlayerId = 'gp1';
const workTilePrefilterTownOldWorld = 'oldWorld';

Game workTilePrefilterOwnedTownGame({
  required String ownedTownTile,
  required String otherTownTile,
}) {
  return Game(
    id: 'g-town-prefilter',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: '$workTilePrefilterTownOldWorld|p1',
            regionId: workTilePrefilterTownOldWorld,
            ownerId: workTilePrefilterTownPlayerId,
            townTileKey: ownedTownTile,
          ),
          Province(
            id: '$workTilePrefilterTownOldWorld|p2',
            regionId: workTilePrefilterTownOldWorld,
            ownerId: 'gp2',
            townTileKey: otherTownTile,
          ),
        ],
        units: const [],
      ),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(
        id: workTilePrefilterTownPlayerId,
        displayName: 'GP',
        isHuman: true,
      ),
      Player(id: 'gp2', displayName: 'GP2', isHuman: false),
    ],
  );
}

Game workTilePrefilterSingleTownGame({required String townTile}) {
  return Game(
    id: 'g-fort-prefilter',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: '$workTilePrefilterTownOldWorld|p1',
            regionId: workTilePrefilterTownOldWorld,
            ownerId: workTilePrefilterTownPlayerId,
            townTileKey: townTile,
          ),
        ],
        units: const [],
      ),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(
        id: workTilePrefilterTownPlayerId,
        displayName: 'GP',
        isHuman: true,
      ),
    ],
  );
}

Game workTilePrefilterCacheGame({
  required String ownedTownTile,
  required String otherTownTile,
}) {
  return Game(
    id: 'g-prefilter-cache',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: '$workTilePrefilterTownOldWorld|p1',
            regionId: workTilePrefilterTownOldWorld,
            ownerId: workTilePrefilterTownPlayerId,
            townTileKey: ownedTownTile,
          ),
          Province(
            id: '$workTilePrefilterTownOldWorld|p2',
            regionId: workTilePrefilterTownOldWorld,
            ownerId: 'gp2',
            townTileKey: otherTownTile,
          ),
        ],
        units: const [],
      ),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(
        id: workTilePrefilterTownPlayerId,
        displayName: 'GP',
        isHuman: true,
      ),
      Player(id: 'gp2', displayName: 'GP2', isHuman: false),
    ],
  );
}
