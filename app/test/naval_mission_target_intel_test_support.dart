// Shared fixtures for DLG31002 Beachhead/Blockade target intel tests (Refs #4340).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

const navalIntelHumanId = 'gp_naval_intel';
const navalIntelRivalId = 'gp_naval_rival';
const navalIntelUnopposed = 'oldWorld|p_empty';
const navalIntelDefended = 'oldWorld|p_fort';
const navalIntelPortProvince = 'oldWorld|p_port';
const navalIntelNoPortProvince = 'oldWorld|p_coast';

Game buildNavalMissionIntelGame({
  required Map<String, String> visibilityByTile,
  List<Unit> units = const [],
  List<Fleet> fleets = const [],
  Map<String, String> portsByProvinceSeaboard = const {},
}) {
  return Game(
    id: 'g_naval_target_intel',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: navalIntelUnopposed,
            regionId: 'oldWorld',
            ownerId: navalIntelRivalId,
            displayName: 'Open Coast',
          ),
          Province(
            id: navalIntelDefended,
            regionId: 'oldWorld',
            ownerId: navalIntelRivalId,
            displayName: 'Stone Harbor',
            fortLevel: 2,
          ),
          Province(
            id: navalIntelPortProvince,
            regionId: 'oldWorld',
            ownerId: navalIntelRivalId,
            displayName: 'Busy Port',
          ),
          Province(
            id: navalIntelNoPortProvince,
            regionId: 'oldWorld',
            ownerId: navalIntelRivalId,
            displayName: 'Coast Only',
          ),
        ],
        units: units,
      ),
      newWorld: const RegionData(),
      fleets: fleets,
      portsByProvinceSeaboard: portsByProvinceSeaboard,
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          navalIntelUnopposed: ['oldWorld|p_empty|0|0'],
          navalIntelDefended: ['oldWorld|p_fort|0|0'],
          navalIntelPortProvince: ['oldWorld|p_port|0|0'],
          navalIntelNoPortProvince: ['oldWorld|p_coast|0|0'],
        },
      },
      playerVisibilityByTile: {navalIntelHumanId: visibilityByTile},
    ),
    players: const [
      Player(id: navalIntelHumanId, displayName: 'England', isHuman: true),
      Player(id: navalIntelRivalId, displayName: 'Spain', isHuman: false),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: navalIntelHumanId,
        factionId2: navalIntelRivalId,
        state: RelationState.atWar,
      ),
    ],
  );
}

final navalIntelFleet = Fleet(
  id: 'f_at_sea',
  ownerId: navalIntelHumanId,
  regionId: 'oldWorld',
  seaZoneId: 'sea1',
  ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
);
