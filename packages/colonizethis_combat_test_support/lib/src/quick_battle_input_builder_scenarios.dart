export 'quick_battle_input_builder_core_scenarios.dart';
export 'quick_battle_input_builder_region_medal_scenarios.dart';

import 'quick_battle_input_builder_core_scenarios.dart';
import 'quick_battle_input_builder_region_medal_scenarios.dart';
import 'scenario_runner.dart';

List<RunnableScenario> quickBattleInputBuilderScenarios() => [
  ...quickBattleInputBuilderCoreScenarios(),
  ...quickBattleInputBuilderRegionAndMedalScenarios(),
];
