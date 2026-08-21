// Shared fixtures for DLG30001 destination hostile-fleet intel (#4573).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

const moveFleetDestIntelHumanId = 'gp_move_dest_intel';
const moveFleetDestIntelRivalId = 'gp_move_dest_rival';
const moveFleetDestIntelSea = 'sea_hostile';
const moveFleetDestIntelSeaTile = 'oldWorld|sea_hostile|0|0';
const moveFleetDestIntelPrefixedSea = 'oldWorld|sea_hostile';

Game buildMoveFleetDestinationIntelGame({
  required Map<String, String> visibilityByTile,
  List<Fleet> fleets = const [],
}) {
  return Game(
    id: 'g_move_dest_intel',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(
        provinces: [
          Province(
            id: 'oldWorld|p_home',
            regionId: 'oldWorld',
            ownerId: moveFleetDestIntelHumanId,
            displayName: 'Home',
          ),
        ],
      ),
      newWorld: const RegionData(),
      fleets: fleets,
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          moveFleetDestIntelPrefixedSea: [moveFleetDestIntelSeaTile],
        },
      },
      playerVisibilityByTile: {moveFleetDestIntelHumanId: visibilityByTile},
    ),
    players: const [
      Player(
        id: moveFleetDestIntelHumanId,
        displayName: 'England',
        isHuman: true,
      ),
      Player(
        id: moveFleetDestIntelRivalId,
        displayName: 'Spain',
        isHuman: false,
      ),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: moveFleetDestIntelHumanId,
        factionId2: moveFleetDestIntelRivalId,
        state: RelationState.atWar,
      ),
    ],
  );
}

Fleet buildHostileAtSeaFleet({
  required String id,
  required FleetMission mission,
}) =>
    Fleet(
      id: id,
      ownerId: moveFleetDestIntelRivalId,
      regionId: 'oldWorld',
      seaZoneId: moveFleetDestIntelSea,
      mission: mission,
      ships: [ShipInstance(id: '${id}_s1', typeId: 'carrack')],
    );
