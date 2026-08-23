import 'package:colonizethis_ai/src/planning/phase_priority_weights.dart';
import 'package:colonizethis_models/colonizethis_models.dart' show WorkOrder;

const WorkOrder kWorkOrderFilterNwPurchaseLand = WorkOrder(
  unitId: 'u_merchant_1',
  target: 'purchase_land',
  targetTileKey: 'newWorld|nw1|0|0',
);

const WorkOrder kWorkOrderFilterNwBuildImprovement = WorkOrder(
  unitId: 'u_builder_1',
  target: 'build_improvement',
  targetTileKey: 'newWorld|nw1|1|0',
);

const WorkOrder kWorkOrderFilterOwPurchaseLand = WorkOrder(
  unitId: 'u_merchant_2',
  target: 'purchase_land',
  targetTileKey: 'oldWorld|gp1_home|2|2',
);

const WorkOrder kWorkOrderFilterOwBuildImprovement = WorkOrder(
  unitId: 'u_builder_2',
  target: 'build_improvement',
  targetTileKey: 'oldWorld|gp1_home|3|3',
);

const WorkOrder kWorkOrderFilterCounterSpyAnyRegion = WorkOrder(
  unitId: 'u_spy_1',
  target: 'counter_spy',
  targetTileKey: 'newWorld|nw1|0|0',
);

const PhasePriorityWeights kWorkOrderFilterNwAcquisitionZeroExpand =
    PhasePriorityWeights(
      oldWorldConquest: 0.95,
      newWorldAcquisition: 0.0,
      oldWorldCivilian: 0.90,
      newWorldCivilian: 0.10,
    );
