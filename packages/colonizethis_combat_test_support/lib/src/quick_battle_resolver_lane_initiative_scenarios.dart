// Table-driven Quick Battle resolver scenarios (Refs #3865).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'quick_battle_input_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> resolveQuickBattleLaneInitiativeScenarios() => [
  RunnableScenario(
    scenarioId: 'qbr-lane-terrain-actions',
    label: 'uses lane terrain modifiers and actions',
    run: () {
      final input = centerFrontQuickBattleInput(
        attackerUnitIds: ['a1', 'a2', 'a3', 'a4'],
        defenderUnitIds: ['d1', 'd2', 'd3', 'd4'],
        defenderLaneTerrain: QuickBattleLaneTerrain.hill,
        seed: 7,
      );

      final aggressive = resolveQuickBattle(
        input,
        roundActions: const [
          QuickBattleRoundActions(actions: [QuickBattleAction.assaultCharge]),
          QuickBattleRoundActions(actions: [QuickBattleAction.assaultCharge]),
          QuickBattleRoundActions(actions: [QuickBattleAction.assaultCharge]),
        ],
      );
      final cautious = resolveQuickBattle(
        input,
        roundActions: const [
          QuickBattleRoundActions(actions: [QuickBattleAction.defendEntrench]),
          QuickBattleRoundActions(actions: [QuickBattleAction.defendEntrench]),
          QuickBattleRoundActions(actions: [QuickBattleAction.defendEntrench]),
        ],
      );

      expect(
        aggressive.attackerCasualties.length +
            aggressive.defenderCasualties.length,
        greaterThan(0),
      );
      expect(
        cautious.attackerCasualties.length + cautious.defenderCasualties.length,
        greaterThan(0),
      );
    },
  ),
  RunnableScenario(
    scenarioId: 'qbr-initiative-ordering',
    label: 'initiative ordering is deterministic and affects sequencing',
    run: () {
      final sharedAttackerDeployment = centerFrontQuickBattleDeployment(
        unitIds: ['a1', 'a2', 'a3', 'a4', 'a5', 'a6'],
      );
      final sharedDefenderDeployment = centerFrontQuickBattleDeployment(
        unitIds: ['d1', 'd2', 'd3', 'd4', 'd5', 'd6'],
      );

      final inputAttFirst = centerFrontQuickBattleInput(
        attackerUnitIds: const [],
        defenderUnitIds: const [],
        provinceId: 'p-order',
        seed: 123,
        attackerDeployment: sharedAttackerDeployment,
        defenderDeployment: sharedDefenderDeployment,
        attackerCavalryShare: 1.0,
        defenderCavalryShare: 0.0,
      );

      const assaultEntrenchRounds = [
        QuickBattleRoundActions(
          attackerActions: [QuickBattleAction.assaultCharge],
          defenderActions: [QuickBattleAction.defendEntrench],
        ),
        QuickBattleRoundActions(
          attackerActions: [QuickBattleAction.assaultCharge],
          defenderActions: [QuickBattleAction.defendEntrench],
        ),
        QuickBattleRoundActions(
          attackerActions: [QuickBattleAction.assaultCharge],
          defenderActions: [QuickBattleAction.defendEntrench],
        ),
      ];

      final resultAttFirst = resolveQuickBattle(
        inputAttFirst,
        roundActions: assaultEntrenchRounds,
      );

      final inputDefFirst = centerFrontQuickBattleInput(
        attackerUnitIds: const [],
        defenderUnitIds: const [],
        provinceId: 'p-order',
        seed: 123,
        attackerDeployment: sharedAttackerDeployment,
        defenderDeployment: sharedDefenderDeployment,
        attackerCavalryShare: 0.0,
        defenderCavalryShare: 1.0,
      );
      final resultDefFirst = resolveQuickBattle(
        inputDefFirst,
        roundActions: assaultEntrenchRounds,
      );

      expect(
        resultAttFirst.attackerCasualties.length,
        isNot(resultDefFirst.attackerCasualties.length),
      );
    },
  ),
];
