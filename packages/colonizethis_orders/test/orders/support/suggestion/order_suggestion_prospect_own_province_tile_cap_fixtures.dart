// Own-province prospect tile-cap fixtures (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const prospectOwnProvinceTileCapPlayerId = 'gp1';
const prospectOwnProvinceTileCapOw = kRegionOldWorld;
const prospectOwnProvinceTileCapProvinceId = 'oldWorld|home';
const prospectOwnProvinceTileCapFeedstockTileKey = 'oldWorld|home|9|0';

Game prospectOwnProvinceTileCapGame() {
  final mineralTiles = <String>[
    'oldWorld|home|0|0',
    'oldWorld|home|1|0',
    'oldWorld|home|2|0',
    'oldWorld|home|3|0',
    prospectOwnProvinceTileCapFeedstockTileKey,
  ];
  final resourceByTile = <String, String>{
    for (final tk in mineralTiles) tk: 'iron',
  };
  final unit = Unit(
    id: 'e1',
    type: kUnitTypeExplorer,
    ownerId: prospectOwnProvinceTileCapPlayerId,
    locationProvinceId: prospectOwnProvinceTileCapProvinceId,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(
      provinces: [
        Province(
          id: prospectOwnProvinceTileCapProvinceId,
          regionId: prospectOwnProvinceTileCapOw,
          ownerId: prospectOwnProvinceTileCapPlayerId,
        ),
      ],
      units: [unit],
    ),
    newWorld: const RegionData(),
    playerVisibilityByTile: {
      prospectOwnProvinceTileCapPlayerId: {
        for (final tk in mineralTiles) tk: 'fogged',
      },
    },
    resourceByTileKey: resourceByTile,
    tileKeysByRegionAndProvince: {
      prospectOwnProvinceTileCapOw: {
        prospectOwnProvinceTileCapProvinceId: mineralTiles,
      },
    },
  );
  return Game(
    id: 'g',
    worldState: world,
    players: const [
      Player(
        id: prospectOwnProvinceTileCapPlayerId,
        displayName: 'GP',
        isHuman: false,
      ),
    ],
  );
}

MapTopology prospectOwnProvinceTileCapTopology(Game game) {
  return MapTopology(
    nodes: [
      for (final p in game.worldState.oldWorld.provinces)
        TopologyNode(
          id: ProvinceId.localIdFrom(p.id),
          regionId: prospectOwnProvinceTileCapOw,
          type: TopologyNodeType.province,
        ),
    ],
    edges: const [],
  );
}
