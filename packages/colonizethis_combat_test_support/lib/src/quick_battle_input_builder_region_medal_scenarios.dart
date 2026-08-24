import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'quick_battle_input_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> quickBattleInputBuilderRegionAndMedalScenarios() => [
  RunnableScenario(
    scenarioId: 'qbib-new-world',
    label: 'builds input from newWorld BattleContext',
    run: () {
      const nw = 'newWorld';
      const provinceId = 'newWorld|N1';
      final game = quickBattleInputBuilderNewWorldGame(
        provinceId: provinceId,
        units: musketeersPikemenPair(provinceId: provinceId),
      );
      final input = buildQuickBattleInput(
        game,
        quickBattleInputBuilderContext(provinceId: provinceId, regionId: nw),
      );
      expect(input.regionId, nw);
      expect(input.defenderDeployment.groups.first.unitIds, ['u2']);
      expect(input.attackerDeployment.groups.first.unitIds, ['u1']);
    },
  ),
  RunnableScenario(
    scenarioId: 'qbib-assignment-medals',
    label: 'passes attacker and defender medals from battle assignment',
    run: () {
      final game = quickBattleInputBuilderGame(
        turnNumber: 3,
        oldWorldUnits: musketeersPikemenPair(),
        generals: const [
          General(id: 'ga', ownerId: 'att', medals: 3),
          General(id: 'gd', ownerId: 'def', medals: 2),
        ],
      );
      final ctx = quickBattleInputBuilderContext();
      final assignment = assignGeneralsForBattleContext(
        game: game,
        ctx: ctx,
        rng: battleAssignmentRng(game, ctx),
        ledger: CombatPhaseGeneralLedger(),
      );
      final input = buildQuickBattleInput(
        game,
        ctx,
        battleAssignment: assignment,
      );
      expect(input.attackerGeneralMedals, 3);
      expect(input.defenderGeneralMedals, 2);
    },
  ),
];
