/// Shared Old-World military topology / Game scaffolds for `defaultSimGameAi`
/// pins (Refs #4084).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Default acting GP in sim-game AI fixtures.
const String simGameAiPlayerId = 'p1';

/// Adjacent peer GP province owner used by most military-move pins.
const String simGameAiPeerOwnerId = 'p2';

/// Two- or three-province Old-World chain topology (P1–P2[–P3]).
MapTopology simGameAiTopology({bool includeP3 = false}) {
  final nodes = <TopologyNode>[
    const TopologyNode(
      id: 'P1',
      regionId: kRegionOldWorld,
      type: TopologyNodeType.province,
    ),
    const TopologyNode(
      id: 'P2',
      regionId: kRegionOldWorld,
      type: TopologyNodeType.province,
    ),
    if (includeP3)
      const TopologyNode(
        id: 'P3',
        regionId: kRegionOldWorld,
        type: TopologyNodeType.province,
      ),
  ];
  final edges = <TopologyEdge>[
    const TopologyEdge(id1: 'P1', id2: 'P2'),
    if (includeP3) const TopologyEdge(id1: 'P2', id2: 'P3'),
  ];
  return MapTopology(nodes: nodes, edges: edges);
}

/// Builds a military-only OW Game for `defaultSimGameAi` adjacency / diplomacy
/// pins. Province locals default to P1/P2 with optional P3; each unit sits on
/// the given local province id under [simGameAiPlayerId].
Game simGameAiMilitaryGame({
  int turnNumber = 1,
  List<String> provinceLocals = const ['P1', 'P2'],
  Map<String, String> ownerByLocal = const {
    'P1': simGameAiPlayerId,
    'P2': simGameAiPeerOwnerId,
  },
  List<String> unitLocals = const ['P1'],
  List<Player> players = const [
    Player(id: simGameAiPlayerId, displayName: 'Power 1', isHuman: true),
  ],
  List<DiplomacyRelation> diplomacyRelations = const [],
  List<MinorNation> minorNations = const [],
}) {
  final provinces = [
    for (final local in provinceLocals)
      Province(
        id: '$kRegionOldWorld|$local',
        regionId: kRegionOldWorld,
        ownerId: ownerByLocal[local] ?? simGameAiPeerOwnerId,
      ),
  ];
  final units = [
    for (var i = 0; i < unitLocals.length; i++)
      Unit(
        id: 'u${i + 1}',
        type: 'grenadiers',
        ownerId: simGameAiPlayerId,
        locationProvinceId: '$kRegionOldWorld|${unitLocals[i]}',
      ),
  ];
  final visibility = <String, String>{
    for (final local in provinceLocals)
      '$kRegionOldWorld|$local|0|0': 'fullyVisible',
  };
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: RegionData(provinces: provinces, units: units),
      newWorld: const RegionData(),
      playerVisibilityByTile: {simGameAiPlayerId: visibility},
    ),
    players: players,
    diplomacyRelations: diplomacyRelations,
    minorNations: minorNations,
  );
}
