export 'combat_resolver_civilian_relocation_fixtures.dart';
export 'combat_resolver_civilian_relocation_working_scenarios.dart';
export 'combat_resolver_civilian_relocation_idle_scenarios.dart';

import 'combat_resolver_civilian_relocation_working_scenarios.dart';
import 'combat_resolver_civilian_relocation_idle_scenarios.dart';
import 'scenario_runner.dart';

List<RunnableScenario> combatResolverCivilianRelocationScenarios() => [
  ...combatResolverWorkingCivilianRelocationScenarios(),
  ...combatResolverIdleCivilianRelocationScenarios(),
];
