// Aggregator (Refs #4196 slice B).

export 'conflict_detection_core_scenarios.dart';
import 'conflict_detection_core_scenarios.dart';
export 'conflict_detection_ownership_scenarios.dart';
import 'conflict_detection_ownership_scenarios.dart';
export 'conflict_detection_order_scenarios.dart';
import 'conflict_detection_order_scenarios.dart';

import 'scenario_runner.dart';

List<RunnableScenario> detectConflictsScenarios() => [
  ...detectConflictsCoreScenarios(),
  ...detectConflictsOwnershipScenarios(),
  ...detectConflictsOrderScenarios(),
];
