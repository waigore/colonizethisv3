// Shared fixtures for prospect location province priority scenarios (Refs #3971).
//
// Refs #2847: prospect province sweep is capped at kMaxExploreProvinceProbesPerUnit
// (4). On seed-scale maps the co-located feedstock province sorts after many
// world provinces and was never probed despite a co-located idle Explorer.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

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
      Province(id: 'oldWorld|aaa$i', regionId: ow, ownerId: 'minor1'),
  ];
  return ordersOwRegionGame(
    id: 'g',
    turnNumber: 1,
    players: const [Player(id: playerId, displayName: 'GP', isHuman: false)],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
    oldWorld: RegionData(
      provinces: [
        ...fillerProvinces,
        Province(id: ironProvinceId, regionId: ow, ownerId: playerId),
      ],
      units: [
        Unit(
          id: orderSuggestionProspectLocationProvincePriorityExplorerUnitId,
          type: kUnitTypeExplorer,
          ownerId: playerId,
          locationProvinceId: ironProvinceId,
        ),
      ],
    ),
    playerVisibilityByTile: includeFoggedVisibility
        ? {
            playerId: {ironTileKey: 'fogged'},
          }
        : null,
    resourceByTileKey: const {ironTileKey: 'iron'},
    tileKeysByRegionAndProvince: {
      ow: {
        for (final p in fillerProvinces) p.id: <String>[],
        ironProvinceId: [ironTileKey],
      },
    },
  );
}

MapTopology orderSuggestionProspectLocationProvincePriorityTopology(
  Game game,
) => ordersProvinceTopology(
  game.worldState.oldWorld.provinces,
  regionId: orderSuggestionProspectLocationProvincePriorityRegionId,
);
