export 'combat_resolver_part2_tiebreak_scenarios.dart';
export 'combat_resolver_part2_garrison_recovery_scenarios.dart';

import 'combat_resolver_part2_tiebreak_scenarios.dart';
import 'combat_resolver_part2_garrison_recovery_scenarios.dart';
import 'scenario_runner.dart';

/// Scenarios for tie-break determinism and garrison recovery (part 2).
List<RunnableScenario> combatResolverPart2Scenarios() => [
  ...combatResolverPart2TieBreakScenarios(),
  ...combatResolverPart2GarrisonRecoveryScenarios(),
];
