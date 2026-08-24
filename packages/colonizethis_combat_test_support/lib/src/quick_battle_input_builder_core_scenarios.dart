import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'combat_resolver_test_support.dart';
import 'quick_battle_input_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> quickBattleInputBuilderCoreScenarios() => [
  RunnableScenario(
    scenarioId: 'qbib-groups',
    label: 'produces QuickBattleInput with defender and attacker groups',
    run: () {
      final game = quickBattleInputBuilderGame(
        oldWorldUnits: musketeersPikemenPair(),
      );
      final input = buildQuickBattleInput(
        game,
        quickBattleInputBuilderContext(),
      );
      expect(input.provinceId, 'P1');
      expect(input.regionId, 'oldWorld');
      expect(input.attackerFactionId, 'att');
      expect(input.defenderFactionId, 'def');
      expect(input.attackerDeployment.groups.length, 1);
      expect(input.attackerDeployment.groups.first.unitIds, ['u1']);
      expect(input.defenderDeployment.groups.length, 1);
      expect(input.defenderDeployment.groups.first.unitIds, ['u2']);
      expect(
        input.attackerDeployment.groups.first.lane,
        QuickBattleLane.center,
      );
      expect(input.attackerDeployment.groups.first.line, QuickBattleLine.front);
    },
  ),
  RunnableScenario(
    scenarioId: 'qbib-filter-missing',
    label: 'filters out unit ids not present in region',
    run: () {
      final game = quickBattleInputBuilderGame(
        oldWorldUnits: musketeersPikemenPair().sublist(1),
      );
      const ctx = BattleContext(
        provinceId: 'P1',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['u2', 'missing'],
        attackers: [
          AttackingSide(factionId: 'att', unitIds: ['ghost']),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );
      final input = buildQuickBattleInput(game, ctx);
      expect(input.defenderDeployment.groups.first.unitIds, ['u2']);
      expect(input.attackerDeployment.groups.first.unitIds, isEmpty);
    },
  ),
  RunnableScenario(
    scenarioId: 'qbib-leader-multipliers',
    label:
        'supplies leader multipliers from Game players (napoleon 1.25, frederick 1.15)',
    run: () {
      final game = quickBattleInputBuilderGame(
        oldWorldUnits: musketeersPikemenPair(),
        players: landResolverNapoleonFrederickPlayers,
      );
      final input = buildQuickBattleInput(
        game,
        quickBattleInputBuilderContext(),
      );
      expect(input.attackerLeaderMultiplier, 1.25);
      expect(input.defenderLeaderMultiplier, 1.15);
    },
  ),
  RunnableScenario(
    scenarioId: 'qbib-default-multipliers',
    label: 'leader multipliers default to 1.0 when players have no leaderKey',
    run: () {
      final game = quickBattleInputBuilderGame(
        oldWorldUnits: musketeersPikemenPair(),
      );
      final input = buildQuickBattleInput(
        game,
        quickBattleInputBuilderContext(),
      );
      expect(input.attackerLeaderMultiplier, 1.0);
      expect(input.defenderLeaderMultiplier, 1.0);
    },
  ),
];
