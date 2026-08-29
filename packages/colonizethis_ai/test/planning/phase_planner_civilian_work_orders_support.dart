// Shared fixtures for `phase_planner_civilian_work_orders` adapter pins (Refs #2509).

import 'package:colonizethis_ai/src/planning/phase_priority_weights.dart';
import 'package:colonizethis_models/colonizethis_models.dart' show WorkOrder;

/// Legacy hard-suppress contract: explicit zero NW weight (Refs #2847).
const PhasePriorityWeights kCivilianWorkOrdersNwAcquisitionZeroExpand =
    PhasePriorityWeights(
  oldWorldConquest: 0.95,
  newWorldAcquisition: 0.0,
  oldWorldCivilian: 0.90,
  newWorldCivilian: 0.10,
);

const WorkOrder kCivilianWorkOrdersColonialWork = WorkOrder(
  unitId: 'u_merchant_1',
  target: 'purchase_land',
  targetTileKey: 'newWorld|nw1|0|0',
);

const WorkOrder kCivilianWorkOrdersColonialBuilderWork = WorkOrder(
  unitId: 'u_builder_2',
  target: 'build_improvement',
  targetTileKey: 'newWorld|nw1|1|0',
);

const WorkOrder kCivilianWorkOrdersDevelopWork = WorkOrder(
  unitId: 'u_builder_1',
  target: 'build_improvement',
  targetTileKey: 'oldWorld|gp1_home|3|2',
);

const WorkOrder kCivilianWorkOrdersDevelopSecondWork = WorkOrder(
  unitId: 'u_builder_2',
  target: 'build_improvement',
  targetTileKey: 'oldWorld|gp1_home|4|2',
);
