// Shared fixtures for phase_planner_naval_ranking pin cases (Refs #4079 Slice D).
library;

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

// Two invadable NW provinces share a NW sea zone each. `phaseColony` is
// the phase-priority target; `otherColony` is a general invadable NW
// province that the phase-priority list does NOT cover. Each colony has
// its own dedicated sea zone so the scorer can distinguish the tiers.
const topology = MapTopology(
  nodes: [
    TopologyNode(
      id: 'oldWorld|home',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'oldWorld|owSeaGateway',
      regionId: 'oldWorld',
      type: TopologyNodeType.seaZone,
    ),
    TopologyNode(
      id: 'newWorld|nwSeaPhase',
      regionId: 'newWorld',
      type: TopologyNodeType.seaZone,
    ),
    TopologyNode(
      id: 'newWorld|nwSeaOther',
      regionId: 'newWorld',
      type: TopologyNodeType.seaZone,
    ),
    TopologyNode(
      id: 'newWorld|phaseColony',
      regionId: 'newWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'newWorld|otherColony',
      regionId: 'newWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: [
    TopologyEdge(id1: 'oldWorld|home', id2: 'oldWorld|owSeaGateway'),
    TopologyEdge(id1: 'oldWorld|owSeaGateway', id2: 'newWorld|nwSeaPhase'),
    TopologyEdge(id1: 'newWorld|nwSeaPhase', id2: 'newWorld|phaseColony'),
    TopologyEdge(id1: 'newWorld|nwSeaOther', id2: 'newWorld|otherColony'),
  ],
);

const colonialWithBoth = ColonialSummary(
  invadableNewWorldProvinceIdsSorted: <String>[
    'newWorld|otherColony',
    'newWorld|phaseColony',
  ],
  adjacentNewWorldOwnerFactionIdsSorted: <String>['tribe1', 'tribe2'],
);

const phasePriorityIds = <String>['newWorld|phaseColony'];
