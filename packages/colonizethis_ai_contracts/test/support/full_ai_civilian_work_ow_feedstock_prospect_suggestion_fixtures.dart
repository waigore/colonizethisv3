/// Suggestion-generation gate fixtures for OW mineral feedstock prospect
/// (Refs #2847 / #4368 Slice C).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

const String prospectSuggestionPlayerId = 'gp1';
const String prospectSuggestionProvinceId = 'oldWorld|s0';
const String prospectSuggestionOtherProvinceId = 'oldWorld|s1';
const String prospectSuggestionIronTile = 'oldWorld|s0|0|0';
const String prospectSuggestionExplorerId = 'e_feedstock';

Game prospectSuggestionFeedstockGame({
  bool tileVisible = true,
  bool alreadyProspected = false,
  CurrentWork? explorerWork,
  String explorerProvinceId = prospectSuggestionProvinceId,
}) {
  final visibility = <String, String>{
    if (tileVisible) prospectSuggestionIronTile: 'fogged',
  };
  final prospected = <String>{
    if (alreadyProspected) prospectSuggestionIronTile,
  };
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: prospectSuggestionProvinceId,
            regionId: kRegionOldWorld,
            ownerId: prospectSuggestionPlayerId,
          ),
          Province(
            id: prospectSuggestionOtherProvinceId,
            regionId: kRegionOldWorld,
            ownerId: prospectSuggestionPlayerId,
          ),
        ],
        units: [
          Unit(
            id: prospectSuggestionExplorerId,
            type: kUnitTypeExplorer,
            ownerId: prospectSuggestionPlayerId,
            locationProvinceId: explorerProvinceId,
            currentWork: explorerWork,
          ),
        ],
      ),
      newWorld: const RegionData(),
      playerVisibilityByTile: {prospectSuggestionPlayerId: visibility},
      playerProspectedTiles: {prospectSuggestionPlayerId: prospected},
      resourceByTileKey: const {prospectSuggestionIronTile: 'iron'},
      tileKeysByRegionAndProvince: const {
        kRegionOldWorld: {
          prospectSuggestionProvinceId: [prospectSuggestionIronTile],
          prospectSuggestionOtherProvinceId: <String>[],
        },
      },
    ),
    players: const [
      Player(id: prospectSuggestionPlayerId, displayName: 'GP', isHuman: false),
    ],
  );
}

MapTopology prospectSuggestionTopology(Game game) {
  return MapTopology(
    nodes: [
      for (final p in game.worldState.oldWorld.provinces)
        TopologyNode(
          id: ProvinceId.localIdFrom(p.id),
          regionId: kRegionOldWorld,
          type: TopologyNodeType.province,
        ),
    ],
    edges: const [],
  );
}
