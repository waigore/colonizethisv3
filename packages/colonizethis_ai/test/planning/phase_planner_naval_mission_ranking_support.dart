// Shared fixtures for phase_planner_naval_mission_ranking pin cases (Refs #4079 Slice D).
library;

import 'package:colonizethis_data/colonizethis_data.dart';

// Two invadable NW provinces: `phaseColony` is in the phase-priority list,
// `otherColony` is not. A minimal topology is enough for mission scoring
// (mission scoring does not consult topology adjacency) but the
// `runNavalPlanner` integration tests need a topology so the planner has
// a coherent fixture; the move-candidate list stays empty so move ranking
// does not interact with this slice.
const topology = MapTopology(
  nodes: [
    TopologyNode(
      id: 'oldWorld|home',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
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
  edges: [],
);

const phasePriorityIds = <String>['newWorld|phaseColony'];
