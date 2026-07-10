// Shared purchase_land prefilter scenario fixtures (Refs #3949 wave 3).

import 'package:colonizethis_models/colonizethis_models.dart';

const workTilePrefilterPlayerId = 'gp1';
const workTilePrefilterOldWorld = 'oldWorld';

Game workTilePrefilterMinorGpGame({
  required String minorTile,
  required String gpTile,
}) {
  final player = Player(
    id: workTilePrefilterPlayerId,
    displayName: 'GP',
    isHuman: false,
    treasury: 500,
  );
  final ownProvince = Province(
    id: '$workTilePrefilterOldWorld|p1',
    regionId: workTilePrefilterOldWorld,
    ownerId: workTilePrefilterPlayerId,
  );
  final minorProvince = Province(
    id: '$workTilePrefilterOldWorld|minor1',
    regionId: workTilePrefilterOldWorld,
    ownerId: 'minor1',
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(
      provinces: [ownProvince, minorProvince],
      units: const [],
    ),
    newWorld: const RegionData(),
    tileKeysByRegionAndProvince: {
      workTilePrefilterOldWorld: {
        '$workTilePrefilterOldWorld|p1': [gpTile],
        '$workTilePrefilterOldWorld|minor1': [minorTile],
      },
    },
    resourceByTileKey: {minorTile: 'grain', gpTile: 'timber'},
  );
  return Game(
    id: 'g1',
    worldState: world,
    players: [player],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
  );
}

Game workTilePrefilterTribeGame({required String tribeTile}) {
  final player = Player(
    id: workTilePrefilterPlayerId,
    displayName: 'GP',
    isHuman: false,
    treasury: 500,
  );
  final tribeProvince = Province(
    id: '$workTilePrefilterOldWorld|tribe1',
    regionId: workTilePrefilterOldWorld,
    ownerId: 'tribe1',
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: [tribeProvince], units: const []),
    newWorld: const RegionData(),
    tileKeysByRegionAndProvince: {
      workTilePrefilterOldWorld: {
        '$workTilePrefilterOldWorld|tribe1': [tribeTile],
      },
    },
    resourceByTileKey: {tribeTile: 'grain'},
  );
  return Game(
    id: 'g1',
    worldState: world,
    players: [player],
    tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
  );
}

Game workTilePrefilterBuildRoadGame({
  required String minorTile,
  required String gpTile,
}) {
  final player = Player(
    id: workTilePrefilterPlayerId,
    displayName: 'GP',
    isHuman: false,
    treasury: 500,
  );
  final ownProvince = Province(
    id: '$workTilePrefilterOldWorld|p1',
    regionId: workTilePrefilterOldWorld,
    ownerId: workTilePrefilterPlayerId,
  );
  final minorProvince = Province(
    id: '$workTilePrefilterOldWorld|minor1',
    regionId: workTilePrefilterOldWorld,
    ownerId: 'minor1',
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(
      provinces: [ownProvince, minorProvince],
      units: const [],
    ),
    newWorld: const RegionData(),
    tileKeysByRegionAndProvince: {
      workTilePrefilterOldWorld: {
        '$workTilePrefilterOldWorld|p1': [gpTile],
        '$workTilePrefilterOldWorld|minor1': [minorTile],
      },
    },
  );
  return Game(
    id: 'g1',
    worldState: world,
    players: [player],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
  );
}
