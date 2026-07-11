// Full-candidate snapshot fixtures (Refs #3949 wave 3 / #3971 wave 4).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const fullCandidateSnapshotPlayerId = 'gp1';
const fullCandidateSnapshotRegionId = 'oldWorld';
const fullCandidateSnapshotHomeProvince =
    '$fullCandidateSnapshotRegionId|p_home';
const fullCandidateSnapshotTargetProvince =
    '$fullCandidateSnapshotRegionId|p_target';
const fullCandidateSnapshotHomeVisible =
    '$fullCandidateSnapshotRegionId|p_home|0|0';
const fullCandidateSnapshotHomeUnknown =
    '$fullCandidateSnapshotRegionId|p_home|1|0';
const fullCandidateSnapshotTargetVisible =
    '$fullCandidateSnapshotRegionId|p_target|0|0';
const fullCandidateSnapshotTargetUnknown =
    '$fullCandidateSnapshotRegionId|p_target|1|0';

Game fullCandidateSnapshotGame() => ordersOwRegionGame(
  id: 'g_suggest_work_snapshot',
  turnNumber: 1,
  players: const [
    Player(
      id: fullCandidateSnapshotPlayerId,
      displayName: 'Human',
      isHuman: true,
    ),
  ],
  tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe')],
  overtureStates: const [
    OvertureState(
      gpId: fullCandidateSnapshotPlayerId,
      targetId: 'tribe1',
      stage: OvertureStage.tradeConsulate,
    ),
  ],
  oldWorld: RegionData(
    provinces: const [
      Province(
        id: fullCandidateSnapshotHomeProvince,
        regionId: fullCandidateSnapshotRegionId,
        ownerId: fullCandidateSnapshotPlayerId,
      ),
      Province(
        id: fullCandidateSnapshotTargetProvince,
        regionId: fullCandidateSnapshotRegionId,
        ownerId: 'tribe1',
      ),
    ],
    units: [
      Unit(
        id: 'explorer_1',
        type: kUnitTypeExplorer,
        ownerId: fullCandidateSnapshotPlayerId,
        locationProvinceId: fullCandidateSnapshotHomeProvince,
        tileKey: fullCandidateSnapshotHomeVisible,
        status: UnitStatus.idle,
      ),
    ],
  ),
  tileKeysByRegionAndProvince: const {
    fullCandidateSnapshotRegionId: {
      fullCandidateSnapshotHomeProvince: [
        fullCandidateSnapshotHomeVisible,
        fullCandidateSnapshotHomeUnknown,
      ],
      fullCandidateSnapshotTargetProvince: [
        fullCandidateSnapshotTargetVisible,
        fullCandidateSnapshotTargetUnknown,
      ],
    },
  },
  playerVisibilityByTile: const {
    fullCandidateSnapshotPlayerId: {
      fullCandidateSnapshotHomeVisible: 'fullyVisible',
      fullCandidateSnapshotHomeUnknown: 'unknown',
      fullCandidateSnapshotTargetVisible: 'fogged',
      fullCandidateSnapshotTargetUnknown: 'unknown',
    },
  },
  resourceByTileKey: const {
    fullCandidateSnapshotHomeVisible: 'iron',
    fullCandidateSnapshotTargetVisible: 'iron',
  },
);

const fullCandidateSnapshotTopology = MapTopology(
  nodes: [
    TopologyNode(
      id: 'p_home',
      regionId: fullCandidateSnapshotRegionId,
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'p_target',
      regionId: fullCandidateSnapshotRegionId,
      type: TopologyNodeType.province,
    ),
  ],
  edges: [TopologyEdge(id1: 'p_home', id2: 'p_target')],
);
