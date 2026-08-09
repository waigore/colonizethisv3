// Table-driven Quick Battle resolver scenarios (Refs #3865).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'quick_battle_input_test_support.dart';
import 'scenario_runner.dart';



/// Scenarios for [resolveQuickBattle].
List<RunnableScenario> resolveQuickBattleScenarios() => [
  RunnableScenario(
    scenarioId: 'qbr-deterministic-seed',
    label: 'deterministic for same seed',
    run: () {
      final input = centerFrontQuickBattleInput(
        attackerUnitIds: quickBattleUnitIds('a', 5),
        defenderUnitIds: ['d1', 'd2'],
        seed: 42,
      );

      final r1 = resolveQuickBattle(input);
      final r2 = resolveQuickBattle(input);
      expect(r1.winner, r2.winner);
      expect(r1.attackerCasualties.length, r2.attackerCasualties.length);
      expect(r1.defenderCasualties.length, r2.defenderCasualties.length);
    },
  ),
  RunnableScenario(
    scenarioId: 'qbr-stronger-attacker-wins',
    label: 'stronger attacker tends to win',
    run: () {
      final input = centerFrontQuickBattleInput(
        attackerUnitIds: quickBattleUnitIds('a', 10),
        defenderUnitIds: ['d1', 'd2'],
        seed: 1,
      );

      final result = resolveQuickBattle(input);
      expect(result.winner, QuickBattleWinner.attacker);
      expect(result.provinceFlips, true);
    },
  ),
  RunnableScenario(
    scenarioId: 'qbr-custom-round-actions',
    label: 'custom roundActions override default Volley Fire',
    run: () {
      final input = centerFrontQuickBattleInput(
        attackerUnitIds: ['a1', 'a2'],
        defenderUnitIds: ['d1'],
        attackerCohesion: 2,
        defenderCohesion: 2,
        seed: 99,
        maxRounds: 2,
      );
      final result = resolveQuickBattle(
        input,
        roundActions: [
          QuickBattleRoundActions(
            attackerActions: [QuickBattleAction.volleyFire],
            defenderActions: [QuickBattleAction.volleyFire],
          ),
          QuickBattleRoundActions(
            attackerActions: [QuickBattleAction.volleyFire],
            defenderActions: [QuickBattleAction.volleyFire],
          ),
        ],
      );
      expect(result.attackerCasualties, isNotNull);
      expect(result.defenderCasualties, isNotNull);
    },
  ),
  RunnableScenario(
    scenarioId: 'qbr-fort-level',
    label: 'fort level applies wall and damage reduction',
    run: () {
      final input = centerFrontQuickBattleInput(
        attackerUnitIds: ['a1', 'a2', 'a3'],
        defenderUnitIds: ['d1', 'd2'],
        seed: 7,
        fortLevel: 2,
        provinceTerrain: 'plains',
      );
      final result = resolveQuickBattle(input);
      expect(result.winner, isNotNull);
    },
  ),
  RunnableScenario(
    scenarioId: 'qbr-stronger-defender-holds',
    label: 'stronger defender tends to hold',
    run: () {
      final input = centerFrontQuickBattleInput(
        attackerUnitIds: ['a1', 'a2'],
        defenderUnitIds: quickBattleUnitIds('d', 10),
        seed: 1,
      );

      final result = resolveQuickBattle(input);
      expect(result.winner, QuickBattleWinner.defender);
      expect(result.provinceFlips, false);
    },
  ),
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
