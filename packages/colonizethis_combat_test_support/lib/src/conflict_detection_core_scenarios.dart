export 'conflict_detection_two_faction_scenarios.dart';
export 'conflict_detection_single_multi_province_scenarios.dart';

import 'conflict_detection_two_faction_scenarios.dart';
import 'conflict_detection_single_multi_province_scenarios.dart';
import 'scenario_runner.dart';

List<RunnableScenario> detectConflictsCoreScenarios() => [
  ...detectConflictsTwoFactionScenarios(),
  ...detectConflictsSingleAndMultiProvinceScenarios(),
];
