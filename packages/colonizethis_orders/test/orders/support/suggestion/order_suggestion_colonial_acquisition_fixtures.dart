// Embassy-stage colonial acquisition fixtures (Refs #2509, #3949 wave 3,
// #3971 wave 4).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

// dart format off
/// Minimal four-node topology: gp1 home OW province ↔ OW sea ↔ NW sea ↔
/// tribe1 colony NW province. Same shape as
/// `order_suggestion_declare_war_colonial_discovery_test.dart` and
/// `order_suggestion_declare_war_intervention_risk_test.dart`.
const colonialAcquisitionTopology = MapTopology(
  nodes: [
    TopologyNode(id: 'oldWorld|home', regionId: 'oldWorld', type: TopologyNodeType.province),
    TopologyNode(id: 'oldWorld|owSea', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
    TopologyNode(id: 'newWorld|nwSea', regionId: 'newWorld', type: TopologyNodeType.seaZone),
    TopologyNode(id: 'newWorld|colony', regionId: 'newWorld', type: TopologyNodeType.province),
  ],
  edges: [
    TopologyEdge(id1: 'oldWorld|home', id2: 'oldWorld|owSea'),
    TopologyEdge(id1: 'oldWorld|owSea', id2: 'newWorld|nwSea'),
    TopologyEdge(id1: 'newWorld|nwSea', id2: 'newWorld|colony'),
  ],
);

const _colonialOwHome = Province(id: 'oldWorld|home', regionId: 'oldWorld', ownerId: 'gp1');
const _colonialNwColony = Province(id: 'newWorld|colony', regionId: 'newWorld', ownerId: 'tribe1');
const _colonialTileKeys = {
  'oldWorld': {'oldWorld|home': ['oldWorld|home|0|0']},
  'newWorld': {'newWorld|colony': ['newWorld|colony|0|0']},
};

/// Shared OW-home + NW-colony graph for colonial acquisition / declare-war
/// suggestion fixtures (Refs #3971).
Game colonialAcquisitionRegionGame({
  required String id,
  required List<Player> players,
  Map<String, Map<String, String>>? playerVisibilityByTile,
  List<Tribe> tribes = const [Tribe(id: 'tribe1', displayName: 'T1')],
  List<DiplomacyRelation> diplomacyRelations = const [],
  List<OvertureState> overtureStates = const [],
}) => ordersOwRegionGame(
  id: id,
  turnNumber: 1,
  players: players,
  oldWorld: const RegionData(provinces: [_colonialOwHome]),
  newWorld: const RegionData(provinces: [_colonialNwColony]),
  playerVisibilityByTile: playerVisibilityByTile,
  tileKeysByRegionAndProvince: _colonialTileKeys,
  tribes: tribes,
  diplomacyRelations: diplomacyRelations,
  overtureStates: overtureStates,
);

/// Embassy-stage colonial scenario: gp1 has NAP overture with tribe1, score at
/// the friendly threshold, and treasury above Join Empire cost.
Game colonialAcquisitionEmbassyScenarioGame() => colonialAcquisitionRegionGame(
  id: 'g-2509-colonial-acquisition',
  players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: false, treasury: 10000)],
  playerVisibilityByTile: const {'gp1': {'oldWorld|home|0|0': 'fullyVisible'}},
  diplomacyRelations: const [DiplomacyRelation(factionId1: 'gp1', factionId2: 'tribe1', state: RelationState.atPeace, score: relationScoreMinFriendly)],
  overtureStates: const [OvertureState(gpId: 'gp1', targetId: 'tribe1', stage: OvertureStage.nap)],
);
// dart format on

PlayerView colonialAcquisitionViewFor(Game game) =>
    buildPlayerView(game, colonialAcquisitionTopology, 'gp1');

String colonialAcquisitionOrderKey(DiplomaticOrder o) =>
    '${o.type.name}:${o.targetFactionId}:${o.overtureStage?.name ?? ""}';
