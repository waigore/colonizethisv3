// Aggregator for resolveEngagementProbabilistic scenarios (Refs #4196 slice C).

export 'combat_resolver_probabilistic_core_scenarios.dart';
export 'combat_resolver_probabilistic_outcome_scenarios.dart';

import 'combat_resolver_probabilistic_core_scenarios.dart';
import 'combat_resolver_probabilistic_outcome_scenarios.dart';
import 'scenario_runner.dart';

/// Scenarios for [resolveEngagementProbabilistic].
List<RunnableScenario> combatResolverProbabilisticScenarios() => [
  ...combatResolverProbabilisticCoreScenarios(),
  ...combatResolverProbabilisticOutcomeScenarios(),
];
