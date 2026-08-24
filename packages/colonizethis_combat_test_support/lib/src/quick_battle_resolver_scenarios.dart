export 'quick_battle_resolver_seed_winner_fort_scenarios.dart';
export 'quick_battle_resolver_lane_initiative_scenarios.dart';

import 'quick_battle_resolver_seed_winner_fort_scenarios.dart';
import 'quick_battle_resolver_lane_initiative_scenarios.dart';
import 'scenario_runner.dart';

/// Scenarios for [resolveQuickBattle].
List<RunnableScenario> resolveQuickBattleScenarios() => [
  ...resolveQuickBattleSeedWinnerFortScenarios(),
  ...resolveQuickBattleLaneInitiativeScenarios(),
];
