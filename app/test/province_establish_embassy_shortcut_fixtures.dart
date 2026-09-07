// Shared fixtures for MAP20001 Establish Embassy pins (Refs #4739).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const String kEstablishEmbassyShortcutGameId = 'g_embassy_shortcut';
const String kEstablishEmbassyHumanPlayerId = 'gp1';
const String kEstablishEmbassyMinorId = 'minor1';
const String kEstablishEmbassyGpOwnerId = 'gp2';
const String kEstablishEmbassyProvinceId = 'oldWorld|p1';
const String kEstablishEmbassyTileKey = 'oldWorld|p1|0|0';

final MapTopology kEstablishEmbassyTopology = MapTopology(
  nodes: const [
    TopologyNode(
      id: 'oldWorld|p1',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'oldWorld|s1',
      regionId: 'oldWorld',
      type: TopologyNodeType.seaZone,
    ),
  ],
  edges: const [TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|s1')],
);

Game buildEstablishEmbassyShortcutGame({
  required String? ownerId,
  bool diplomaticExpertise = true,
  int treasury = 5000,
  bool asMinor = true,
  OvertureStage? overtureStage = OvertureStage.tradeConsulate,
  bool atWar = false,
}) {
  return Game(
    id: kEstablishEmbassyShortcutGameId,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: kEstablishEmbassyProvinceId,
            regionId: 'oldWorld',
            ownerId: ownerId,
            townTileKey: kEstablishEmbassyTileKey,
          ),
        ],
        units: const [],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      resourceByTileKey: const {kEstablishEmbassyTileKey: 'grain'},
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          kEstablishEmbassyProvinceId: [kEstablishEmbassyTileKey],
        },
      },
      playerVisibilityByTile: {
        kEstablishEmbassyHumanPlayerId: {
          kEstablishEmbassyTileKey: 'fullyVisible',
        },
      },
    ),
    players: [
      Player(
        id: kEstablishEmbassyHumanPlayerId,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: kEstablishEmbassyProvinceId,
        treasury: treasury,
        techUnlocked: {
          if (diplomaticExpertise) kTechIdDiplomaticExpertise: true,
        },
      ),
      if (!asMinor && ownerId == kEstablishEmbassyGpOwnerId)
        const Player(
          id: kEstablishEmbassyGpOwnerId,
          displayName: 'Rival GP',
          isHuman: false,
        ),
    ],
    minorNations: [
      if (asMinor && ownerId != null)
        MinorNation(id: ownerId, displayName: 'Minor One'),
    ],
    tribes: const [],
    overtureStates: [
      if (overtureStage != null && ownerId != null)
        OvertureState(
          gpId: kEstablishEmbassyHumanPlayerId,
          targetId: ownerId,
          stage: overtureStage,
        ),
    ],
    diplomacyRelations: [
      if (atWar && ownerId != null)
        DiplomacyRelation(
          factionId1: kEstablishEmbassyHumanPlayerId,
          factionId2: ownerId,
          state: RelationState.atWar,
        ),
    ],
  );
}
