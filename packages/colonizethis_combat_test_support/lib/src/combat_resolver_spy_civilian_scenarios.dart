// Aggregator (Refs #4196 slice B).

export 'combat_resolver_spy_conquest_scenarios.dart';
import 'combat_resolver_spy_conquest_scenarios.dart';
export 'combat_resolver_civilian_relocation_scenarios.dart';
import 'combat_resolver_civilian_relocation_scenarios.dart';
export 'combat_resolver_general_morale_scenarios.dart';
import 'combat_resolver_general_morale_scenarios.dart';

import 'scenario_runner.dart';

/// Scenarios for spy timers, purchased land, and civilian relocation.
List<RunnableScenario> combatResolverSpyCivilianScenarios() => [
  ...combatResolverSpyConquestScenarios(),
  ...combatResolverCivilianRelocationScenarios(),
  ...combatResolverGeneralMoraleAuraScenarios(),
];
