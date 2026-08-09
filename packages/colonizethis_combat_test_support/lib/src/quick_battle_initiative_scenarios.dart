// Quick Battle cavalry initiative scenarios (Refs #4196 slice C).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'quick_battle_input_test_support.dart';
import 'scenario_runner.dart';

const _assaultVolleyRounds = [
  QuickBattleRoundActions(
    attackerActions: [QuickBattleAction.assaultCharge],
    defenderActions: [QuickBattleAction.volleyFire],
  ),
  QuickBattleRoundActions(
    attackerActions: [QuickBattleAction.assaultCharge],
    defenderActions: [QuickBattleAction.volleyFire],
  ),
  QuickBattleRoundActions(
    attackerActions: [QuickBattleAction.assaultCharge],
    defenderActions: [QuickBattleAction.volleyFire],
  ),
];

/// Cavalry initiative scenarios (assault vs volley trade).
List<RunnableScenario> quickBattleInitiativeScenarios() => [
  RunnableScenario(
    scenarioId: 'qbi-cavalry-attacker-first',
    label:
        'Scenario: cavalry-heavy attacker gains first action and trades better',
    run: () {
      final attackerFirst = centerFrontQuickBattleInput(
        attackerUnitIds: ['a1', 'a2', 'a3', 'a4', 'a5', 'a6'],
        defenderUnitIds: ['d1', 'd2', 'd3', 'd4', 'd5', 'd6'],
        provinceId: 'initiative-province',
        seed: 77,
        attackerCavalryShare: 1.0,
        defenderCavalryShare: 0.0,
      );
      final attackerFirstResult = resolveQuickBattle(
        attackerFirst,
        roundActions: _assaultVolleyRounds,
      );

      final defenderFirst = centerFrontQuickBattleInput(
        attackerUnitIds: ['a1', 'a2', 'a3', 'a4', 'a5', 'a6'],
        defenderUnitIds: ['d1', 'd2', 'd3', 'd4', 'd5', 'd6'],
        provinceId: 'initiative-province',
        seed: 77,
        attackerCavalryShare: 0.0,
        defenderCavalryShare: 1.0,
      );
      final defenderFirstResult = resolveQuickBattle(
        defenderFirst,
        roundActions: _assaultVolleyRounds,
      );

      expect(
        attackerFirstResult.attackerCasualties.length,
        lessThan(defenderFirstResult.attackerCasualties.length),
        reason: 'acting first should improve attacker trade in this setup',
      );
    },
  ),
];
