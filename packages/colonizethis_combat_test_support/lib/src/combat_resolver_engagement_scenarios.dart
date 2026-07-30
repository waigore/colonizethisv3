// Aggregator (Refs #4196 slice B).

export 'combat_resolver_engagement_outcome_scenarios.dart';
import 'combat_resolver_engagement_outcome_scenarios.dart';
export 'combat_resolver_engagement_context_scenarios.dart';
import 'combat_resolver_engagement_context_scenarios.dart';

import 'scenario_runner.dart';

/// Scenarios for [resolveEngagement] and [resolveBattleContext] (part 1).
List<RunnableScenario> combatResolverEngagementScenarios() => [
  ...combatResolverEngagementOutcomeScenarios(),
  ...combatResolverEngagementContextScenarios(),
];
