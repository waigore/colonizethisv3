// Shared move/army validator game fixtures (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'move_validator_test_support.dart';

const mvOw = 'oldWorld';
const mvNw = 'newWorld';
const mvDestTile = '$mvOw|P2|0|0';

Map<String, Map<String, String>> mvP1FogPairVisibility({
  required String destRegion,
  required String destLocal,
}) =>
    {
      'p1': {
        '$mvOw|P1|0|0': 'fullyVisible',
        '$destRegion|$destLocal|0|0': 'fogged',
      },
    };

MapTopology get mvOwTopology => moveValidatorTestTwoProvinceTopology(mvOw);

Game mvTwoProvinceUnitGame({
  required String unitType,
  required String unitId,
  required String destOwnerId,
  bool includeP2Player = false,
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
  String? unitTileKey,
}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$mvOw|P1', regionId: mvOw, ownerId: 'p1'),
          Province(id: '$mvOw|P2', regionId: mvOw, ownerId: destOwnerId),
        ],
        units: [
          Unit(
            id: unitId,
            type: unitType,
            ownerId: 'p1',
            locationProvinceId: '$mvOw|P1',
            tileKey: unitTileKey,
          ),
        ],
      ),
      newWorld: const RegionData(),
      playerVisibilityByTile: mvP1FogPairVisibility(
        destRegion: mvOw,
        destLocal: 'P2',
      ),
    ),
    players: [
      const Player(id: 'p1', displayName: 'P1', isHuman: true),
      if (includeP2Player)
        const Player(id: 'p2', displayName: 'P2', isHuman: true),
    ],
    minorNations: minorNations,
    tribes: tribes,
    diplomacyRelations: const [],
  );
}

Game mvTwoProvinceArmyGame({
  required String destOwnerId,
  bool includeP2Player = false,
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$mvOw|P1', regionId: mvOw, ownerId: 'p1'),
          Province(id: '$mvOw|P2', regionId: mvOw, ownerId: destOwnerId),
        ],
        units: [
          Unit(
            id: 'u1',
            type: 'pikemen',
            ownerId: 'p1',
            locationProvinceId: '$mvOw|P1',
          ),
        ],
      ),
      newWorld: const RegionData(),
      armies: [moveValidatorTestFieldArmy(mvOw, 'p1', 'P1', 'u1')],
      playerVisibilityByTile: mvP1FogPairVisibility(
        destRegion: mvOw,
        destLocal: 'P2',
      ),
    ),
    players: [
      const Player(id: 'p1', displayName: 'P1', isHuman: true),
      if (includeP2Player)
        const Player(id: 'p2', displayName: 'P2', isHuman: true),
    ],
    minorNations: minorNations,
    tribes: tribes,
    diplomacyRelations: const [],
  );
}

Game mvCrossRegionTribeGame({required String unitType}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [Province(id: '$mvOw|P1', regionId: mvOw, ownerId: 'p1')],
        units: [
          Unit(
            id: 'u1',
            type: unitType,
            ownerId: 'p1',
            locationProvinceId: '$mvOw|P1',
            tileKey: '$mvOw|P1|0|0',
          ),
        ],
      ),
      newWorld: const RegionData(
        provinces: [Province(id: '$mvNw|P2', regionId: mvNw, ownerId: 'tribe1')],
      ),
      playerVisibilityByTile: mvP1FogPairVisibility(
        destRegion: mvNw,
        destLocal: 'P2',
      ),
    ),
    players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
    tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe1')],
  );
}
