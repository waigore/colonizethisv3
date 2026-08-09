// Aggregator for land resolver limit scenarios (Refs #4196 slice C).

export 'combat_resolver_deployment_limit_scenarios.dart';
export 'combat_resolver_general_medal_scenarios.dart';

import 'combat_resolver_deployment_limit_scenarios.dart';
import 'combat_resolver_general_medal_scenarios.dart';
import 'scenario_runner.dart';

/// Deployment limits and general-medal scenarios (part 1 limits).
List<RunnableScenario> combatResolverLimitsScenarios() => [
  ...combatResolverDeploymentLimitScenarios(),
  ...combatResolverGeneralMedalScenarios(),
];
