// Quick Battle siege scenarios (Refs #4196 slice C).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'quick_battle_input_test_support.dart';
import 'quick_battle_siege_pipeline_test_support.dart';
import 'scenario_runner.dart';

/// Emplaced-gun siege scenarios for [resolveQuickBattle].
List<RunnableScenario> quickBattleSiegeScenarios() => [
  RunnableScenario(
    scenarioId: 'qbs-conquest-fort-downgrade',
    label:
        'Scenario: concentrated fire destroys battery before garrison — conquest + fort downgrade',
    run: () {
      final input = centerFrontQuickBattleInput(
        attackerUnitIds: quickBattleUnitIds('att', 50),
        defenderUnitIds: quickBattleUnitIds('def', 8),
        seed: 0,
        fortLevel: 1,
        provinceId: 'scenario-province',
        emplacedGuns: [siegeEmplacedGun('qb:emplaced:ow:s:0', hp: 3)],
      );
      final result = resolveQuickBattle(input);
      expect(result.winner, QuickBattleWinner.attacker);
      expect(result.provinceFlips, isTrue);
      expect(result.fortDowngradeFromDestroyedEmplaced, isTrue);
      expect(result.emplacedGunOutcomes, hasLength(1));
      expect(result.emplacedGunOutcomes.single.destroyed, isTrue);
      expect(result.emplacedGunOutcomes.single.hp, 0);
    },
  ),
  RunnableScenario(
    scenarioId: 'qbs-battery-absorbs-volleys',
    label: 'Scenario: battery absorbs volleys — partial HP loss, fort stands',
    run: () {
      final input = centerFrontQuickBattleInput(
        attackerUnitIds: quickBattleUnitIds('att', 35),
        defenderUnitIds: quickBattleUnitIds('def', 8),
        seed: 0,
        fortLevel: 1,
        provinceId: 'scenario-province',
        emplacedGuns: [siegeEmplacedGun('qb:emplaced:ow:s:0', hp: 8)],
      );
      final result = resolveQuickBattle(input);
      expect(result.emplacedGunOutcomes, hasLength(1));
      final gun = result.emplacedGunOutcomes.single;
      expect(gun.destroyed, isFalse);
      expect(gun.hp, lessThan(8));
      expect(gun.hp, greaterThan(0));
      expect(result.fortDowngradeFromDestroyedEmplaced, isFalse);
    },
  ),
  RunnableScenario(
    scenarioId: 'qbs-two-gun-round-robin',
    label: 'Scenario: two-gun battery — round-robin damage (sorted by id)',
    run: () {
      final input = centerFrontQuickBattleInput(
        attackerUnitIds: quickBattleUnitIds('att', 40),
        defenderUnitIds: quickBattleUnitIds('def', 6),
        seed: 1,
        fortLevel: 2,
        provinceId: 'scenario-province',
        emplacedGuns: [
          siegeEmplacedGun('qb:emplaced:ow:s:0', hp: 20),
          siegeEmplacedGun('qb:emplaced:ow:s:1', hp: 20),
        ],
      );
      final result = resolveQuickBattle(input);
      expect(result.emplacedGunOutcomes, hasLength(2));
      final byId = {for (final o in result.emplacedGunOutcomes) o.id: o};
      expect(byId['qb:emplaced:ow:s:0']!.destroyed, isFalse);
      expect(byId['qb:emplaced:ow:s:1']!.destroyed, isFalse);
      expect(byId['qb:emplaced:ow:s:0']!.hp, lessThan(20));
      expect(byId['qb:emplaced:ow:s:1']!.hp, lessThan(20));
      final diff =
          (byId['qb:emplaced:ow:s:0']!.hp - byId['qb:emplaced:ow:s:1']!.hp)
              .abs();
      expect(
        diff,
        lessThanOrEqualTo(2),
        reason: 'round-robin keeps guns within small HP spread',
      );
    },
  ),
  RunnableScenario(
    scenarioId: 'qbs-triple-battery',
    label:
        'Scenario: triple battery (fort 3) — each piece tracked independently',
    run: () {
      final input = centerFrontQuickBattleInput(
        attackerUnitIds: quickBattleUnitIds('att', 55),
        defenderUnitIds: quickBattleUnitIds('def', 10),
        seed: 2,
        fortLevel: 3,
        provinceId: 'scenario-province',
        emplacedGuns: [
          siegeEmplacedGun('qb:emplaced:ow:s:0', hp: 12),
          siegeEmplacedGun('qb:emplaced:ow:s:1', hp: 12),
          siegeEmplacedGun('qb:emplaced:ow:s:2', hp: 12),
        ],
      );
      final result = resolveQuickBattle(input);
      expect(result.emplacedGunOutcomes, hasLength(3));
      final totalHp = result.emplacedGunOutcomes.fold<int>(
        0,
        (s, o) => s + o.hp,
      );
      expect(
        totalHp,
        lessThan(12 * 3),
        reason: 'at least some gun HP was consumed',
      );
    },
  ),
  RunnableScenario(
    scenarioId: 'qbs-no-virtual-guns',
    label:
        'Scenario: no virtual guns — legacy aggregate emplaced lump still applies',
    run: () {
      final input = centerFrontQuickBattleInput(
        attackerUnitIds: quickBattleUnitIds('att', 6),
        defenderUnitIds: quickBattleUnitIds('def', 4),
        seed: 0,
        fortLevel: 2,
        provinceId: 'scenario-province',
      );
      final result = resolveQuickBattle(input);
      expect(result.emplacedGunOutcomes, isEmpty);
      expect(result.fortDowngradeFromDestroyedEmplaced, isFalse);
      expect(result.winner, isNotNull);
    },
  ),
  RunnableScenario(
    scenarioId: 'qbs-pipeline-build-apply',
    label:
        'Scenario: pipeline buildQuickBattleInput → resolve → apply reduces fort on conquest',
    run: () {
      const pipelineSeed = 0;
      final game = siegePipelineGame();
      final ctx = siegePipelineBattleContext();

      final input = buildQuickBattleInput(game, ctx, seed: pipelineSeed);
      expect(input.emplacedGuns.length, 1);
      final qbResult = resolveQuickBattle(input);
      expect(
        qbResult.fortDowngradeFromDestroyedEmplaced,
        isTrue,
        reason: 'battery should be eliminated under this scenario',
      );
      expect(qbResult.provinceFlips, isTrue);

      final after = applyQuickBattleResultToGame(game, ctx, qbResult);
      final province = after.worldState.oldWorld.provinces.firstWhere(
        (p) => p.id == siegePipelineProvinceId,
      );
      expect(province.ownerId, 'att');
      expect(province.fortLevel, 0);
    },
  ),
];
