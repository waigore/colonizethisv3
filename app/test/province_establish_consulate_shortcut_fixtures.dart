// Shared fixtures for MAP20001 Establish Consulate pins (Refs #4346, #4642).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const String kEstablishConsulateShortcutGameId = 'g_consulate_shortcut';
const String kEstablishConsulateHumanPlayerId = 'gp1';
const String kEstablishConsulateMinorId = 'minor1';
const String kEstablishConsulateProvinceId = 'oldWorld|p1';
const String kEstablishConsulateTileKey = 'oldWorld|p1|0|0';

final MapTopology kEstablishConsulateTopology = MapTopology(
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

Game buildEstablishConsulateShortcutGame({
  required String? ownerId,
  bool diplomaticExpertise = true,
  int treasury = 1000,
  bool asMinor = true,
  OvertureStage? overtureStage,
}) {
  return Game(
    id: kEstablishConsulateShortcutGameId,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: kEstablishConsulateProvinceId,
            regionId: 'oldWorld',
            ownerId: ownerId,
            townTileKey: kEstablishConsulateTileKey,
          ),
        ],
        units: const [],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      resourceByTileKey: const {kEstablishConsulateTileKey: 'grain'},
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          kEstablishConsulateProvinceId: [kEstablishConsulateTileKey],
        },
      },
      playerVisibilityByTile: {
        kEstablishConsulateHumanPlayerId: {
          kEstablishConsulateTileKey: 'fullyVisible',
        },
      },
    ),
    players: [
      Player(
        id: kEstablishConsulateHumanPlayerId,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: kEstablishConsulateProvinceId,
        treasury: treasury,
        techUnlocked: {
          if (diplomaticExpertise) kTechIdDiplomaticExpertise: true,
        },
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
          gpId: kEstablishConsulateHumanPlayerId,
          targetId: ownerId,
          stage: overtureStage,
        ),
    ],
  );
}
