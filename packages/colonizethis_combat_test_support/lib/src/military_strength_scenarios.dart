// Aggregator barrel for military-strength scenario tables (Refs #4196 slice B).

export 'military_strength_player_faction_scenarios.dart';
export 'military_strength_player_filtering_scenarios.dart';
export 'military_strength_player_multiplier_scenarios.dart';
export 'military_strength_aggregate_scenarios.dart';
export 'military_strength_effective_era_scenarios.dart';
export 'military_strength_cavalry_scenarios.dart';

import 'military_strength_player_faction_scenarios.dart';
import 'military_strength_player_filtering_scenarios.dart';
import 'military_strength_player_multiplier_scenarios.dart';
import 'scenario_runner.dart';

/// Scenarios for [aggregateMilitaryStrengthForPlayer].
List<RunnableScenario> aggregateMilitaryStrengthForPlayerScenarios() => [
  ...militaryStrengthPlayerFactionScenarios(),
  ...militaryStrengthPlayerFilteringScenarios(),
  ...militaryStrengthPlayerMultiplierScenarios(),
];
