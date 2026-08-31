// Screen-level fixtures for counsel military invade Agree tests (Refs #4307, #4305).

import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'panel_fixtures/core.dart';

const kCounselMilitaryInvadeGameId = 'counsel-military-invade-screen-test';
const kCounselMilitaryInvadeRivalId = 'gp2';
const kCounselMilitaryInvadeFromProvince = 'oldWorld|p1';
const kCounselMilitaryInvadeProvince = 'oldWorld|p2';

final MapTopology counselMilitaryInvadeTopology = MapTopology(
  nodes: const [
    TopologyNode(
      id: kCounselMilitaryInvadeFromProvince,
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: kCounselMilitaryInvadeProvince,
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [
    TopologyEdge(id1: kCounselMilitaryInvadeFromProvince, id2: kCounselMilitaryInvadeProvince),
  ],
);

class CounselMilitaryInvadeMapGameService extends GameService {
  CounselMilitaryInvadeMapGameService(super.box, super.adapter);

  @override
  ({
    MapTopology combinedTopology,
    Map<String, TileMapResult> tileMapByRegion,
    Map<String, MapTopology> topologyByRegion,
    List<WarpLink>? warpLinks,
  })?
  getMapData(String gameId) {
    if (gameId != kCounselMilitaryInvadeGameId) return null;
    return (
      combinedTopology: counselMilitaryInvadeTopology,
      tileMapByRegion: const {},
      topologyByRegion: const {},
      warpLinks: null,
    );
  }
}

Game buildCounselMilitaryInvadeScreenGame({required bool atWar}) {
  const human = kPanelTestHumanPlayerId;
  final armyId = fieldArmyIdFor(human, kCounselMilitaryInvadeFromProvince);
  return buildPanelTestGame(
    id: kCounselMilitaryInvadeGameId,
    players: [
      Player(
        id: human,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: kCounselMilitaryInvadeFromProvince,
        stockpile: const Stockpile()
            .applyDelta('grain', 20)
            .applyDelta('meat', 20),
      ),
      const Player(id: kCounselMilitaryInvadeRivalId, displayName: 'Rival', isHuman: false),
    ],
    oldWorldProvinces: const [
      Province(
        id: kCounselMilitaryInvadeFromProvince,
        regionId: 'oldWorld',
        ownerId: human,
        displayName: 'Origin',
      ),
      Province(
        id: kCounselMilitaryInvadeProvince,
        regionId: 'oldWorld',
        ownerId: kCounselMilitaryInvadeRivalId,
        displayName: 'Enemy Border',
      ),
    ],
    oldWorldUnits: [
      Unit(
        id: 'u1',
        type: kPanelTestRegimentType,
        ownerId: human,
        locationProvinceId: kCounselMilitaryInvadeFromProvince,
      ),
    ],
    armies: [
      Army(
        id: armyId,
        ownerId: human,
        regionId: 'oldWorld',
        stationedProvinceId: kCounselMilitaryInvadeFromProvince,
        regimentUnitIds: const ['u1'],
        isHomeArmy: false,
      ),
    ],
    tileKeysByRegionAndProvince: const {
      'oldWorld': {
        kCounselMilitaryInvadeFromProvince: ['oldWorld|p1|0|0'],
        kCounselMilitaryInvadeProvince: ['oldWorld|p2|0|0'],
      },
    },
    playerVisibilityByTile: const {
      human: {
        'oldWorld|p1|0|0': 'fullyVisible',
        'oldWorld|p2|0|0': 'fullyVisible',
      },
    },
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: human,
        factionId2: kCounselMilitaryInvadeRivalId,
        state: atWar ? RelationState.atWar : RelationState.atPeace,
        score: atWar ? 20 : 50,
        sinceTurn: 0,
        lastInteractionTurn: 0,
      ),
    ],
  );
}
