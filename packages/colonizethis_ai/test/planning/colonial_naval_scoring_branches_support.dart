// Shared topology and colonial summaries for colonial naval scoring branch pins.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

/// Two NW provinces share a single NW sea zone (`newWorld|nwSeaShared`).
/// `newWorld|nwSeaIsolated` is a NW sea zone with no invadable adjacency.
/// `oldWorld|owSeaInterior` is an OW sea zone with no NW sea adjacency
/// (no gateway bonus). `oldWorld|owSeaGateway` borders `newWorld|nwSeaShared`.
const colonialNavalScoringBranchesTopology = MapTopology(
  nodes: [
    TopologyNode(
      id: 'oldWorld|home',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'oldWorld|owSeaInterior',
      regionId: 'oldWorld',
      type: TopologyNodeType.seaZone,
    ),
    TopologyNode(
      id: 'oldWorld|owSeaGateway',
      regionId: 'oldWorld',
      type: TopologyNodeType.seaZone,
    ),
    TopologyNode(
      id: 'newWorld|nwSeaShared',
      regionId: 'newWorld',
      type: TopologyNodeType.seaZone,
    ),
    TopologyNode(
      id: 'newWorld|nwSeaIsolated',
      regionId: 'newWorld',
      type: TopologyNodeType.seaZone,
    ),
    TopologyNode(
      id: 'newWorld|colonyA',
      regionId: 'newWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'newWorld|colonyB',
      regionId: 'newWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'newWorld|inlandLand',
      regionId: 'newWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: [
    TopologyEdge(id1: 'oldWorld|home', id2: 'oldWorld|owSeaInterior'),
    TopologyEdge(id1: 'oldWorld|owSeaGateway', id2: 'newWorld|nwSeaShared'),
    TopologyEdge(id1: 'newWorld|nwSeaShared', id2: 'newWorld|colonyA'),
    TopologyEdge(id1: 'newWorld|nwSeaShared', id2: 'newWorld|colonyB'),
    TopologyEdge(id1: 'newWorld|colonyA', id2: 'newWorld|inlandLand'),
    TopologyEdge(id1: 'newWorld|nwSeaIsolated', id2: 'newWorld|inlandLand'),
  ],
);

const colonialNavalScoringWithInvadable = ColonialSummary(
  invadableNewWorldProvinceIdsSorted: <String>[
    'newWorld|colonyA',
    'newWorld|colonyB',
  ],
);

const colonialNavalScoringNoInvadable = ColonialSummary();
