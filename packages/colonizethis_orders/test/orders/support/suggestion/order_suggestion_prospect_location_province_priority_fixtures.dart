// Shared fixtures for prospect location province priority scenarios (Refs #3949 wave 3).
//
// Refs #2847: prospect province sweep is capped at kMaxExploreProvinceProbesPerUnit
// (4). On seed-scale maps the co-located feedstock province sorts after many
// world provinces and was never probed despite a co-located idle Explorer.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const orderSuggestionProspectLocationProvincePriorityPlayerId = 'gp1';
const orderSuggestionProspectLocationProvincePriorityRegionId = kRegionOldWorld;

const orderSuggestionProspectLocationProvincePriorityIronProvinceId =
    'oldWorld|z_feedstock';
const orderSuggestionProspectLocationProvincePriorityIronTileKey =
    'oldWorld|z_feedstock|2|0';
const orderSuggestionProspectLocationProvincePriorityExplorerUnitId = 'e1';

Game orderSuggestionProspectLocationProvincePriorityGame({
  bool includeFoggedVisibility = true,
}) {
  const playerId = orderSuggestionProspectLocationProvincePriorityPlayerId;
  const ow = orderSuggestionProspectLocationProvincePriorityRegionId;
  const ironProvinceId =
      orderSuggestionProspectLocationProvincePriorityIronProvinceId;
  const ironTileKey =
      orderSuggestionProspectLocationProvincePriorityIronTileKey;

  final fillerProvinces = <Province>[
    for (var i = 0; i < 6; i++)
      Province(
        id: 'oldWorld|aaa$i',
        regionId: ow,
        ownerId: 'minor1',
      ),
  ];
  final ironProvince = Province(
    id: ironProvinceId,
    regionId: ow,
    ownerId: playerId,
  );
  final unit = Unit(
    id: orderSuggestionProspectLocationProvincePriorityExplorerUnitId,
    type: kUnitTypeExplorer,
    ownerId: playerId,
    locationProvinceId: ironProvinceId,
  );
  final tileKeysByRegion = <String, Map<String, List<String>>>{
    ow: {
      for (final p in fillerProvinces) p.id: <String>[],
      ironProvinceId: [ironTileKey],
    },
  };
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(
      provinces: [...fillerProvinces, ironProvince],
      units: [unit],
    ),
    newWorld: const RegionData(),
    playerVisibilityByTile: includeFoggedVisibility
        ? {
            playerId: {ironTileKey: 'fogged'},
          }
        : const {},
    resourceByTileKey: const {ironTileKey: 'iron'},
    tileKeysByRegionAndProvince: tileKeysByRegion,
  );
  return Game(
    id: 'g',
    worldState: world,
    players: const [
      Player(id: playerId, displayName: 'GP', isHuman: false),
    ],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
  );
}

MapTopology orderSuggestionProspectLocationProvincePriorityTopology(
  Game game,
) {
  const ow = orderSuggestionProspectLocationProvincePriorityRegionId;
  return MapTopology(
    nodes: [
      for (final p in game.worldState.oldWorld.provinces)
        TopologyNode(
          id: ProvinceId.localIdFrom(p.id),
          regionId: ow,
          type: TopologyNodeType.province,
        ),
    ],
    edges: const [],
  );
}
