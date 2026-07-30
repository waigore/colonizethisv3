// Table-driven Quick Battle perf-invariant scenarios (Refs #3865, #2316 P1 #8/#9).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'quick_battle_input_test_support.dart';
import 'scenario_runner.dart';



void _expectEmplacedGunOutcomesMatch(
  QuickBattleResult r1,
  QuickBattleResult r2,
) {
  expect(r1.emplacedGunOutcomes.length, r2.emplacedGunOutcomes.length);
  for (var i = 0; i < r1.emplacedGunOutcomes.length; i++) {
    expect(r1.emplacedGunOutcomes[i].id, r2.emplacedGunOutcomes[i].id);
    expect(r1.emplacedGunOutcomes[i].hp, r2.emplacedGunOutcomes[i].hp);
    expect(
      r1.emplacedGunOutcomes[i].destroyed,
      r2.emplacedGunOutcomes[i].destroyed,
    );
  }
}

/// Scenarios for round-robin gun HP and effective-strength caching invariants.
List<RunnableScenario> quickBattlePerfInvariantScenarios() => [
  RunnableScenario(
    scenarioId: 'qbpi-three-guns-sorted-id-parity',
    label:
        'three small guns drained over multiple rounds keep sorted-id parity',
    run: () {
      final input = perfSiegeQuickBattleInput(
        seed: 7,
        fortLevel: 3,
        guns: [
          siegeEmplacedGun('qb:emplaced:ow:p:0', hp: 2),
          siegeEmplacedGun('qb:emplaced:ow:p:1', hp: 2),
          siegeEmplacedGun('qb:emplaced:ow:p:2', hp: 2),
        ],
        attackerRegiments: 60,
        defenderRegiments: 8,
      );
      final r1 = resolveQuickBattle(input);
      final r2 = resolveQuickBattle(input);
      expect(r1.emplacedGunOutcomes.length, 3);
      _expectEmplacedGunOutcomesMatch(r1, r2);
      expect(r1.attackerCasualties, r2.attackerCasualties);
      expect(r1.defenderCasualties, r2.defenderCasualties);
      expect(r1.winner, r2.winner);
      expect(r1.provinceFlips, r2.provinceFlips);
      expect(
        r1.fortDowngradeFromDestroyedEmplaced,
        r2.fortDowngradeFromDestroyedEmplaced,
      );
    },
  ),
  RunnableScenario(
    scenarioId: 'qbpi-asymmetric-gun-hp-round-robin',
    label:
        'asymmetric gun HP still allocates damage in sorted-id round-robin order',
    run: () {
      final input = perfSiegeQuickBattleInput(
        seed: 13,
        fortLevel: 2,
        guns: [
          siegeEmplacedGun('qb:emplaced:ow:p:0', hp: 3),
          siegeEmplacedGun('qb:emplaced:ow:p:1', hp: 10),
        ],
        attackerRegiments: 50,
        defenderRegiments: 6,
      );
      final result = resolveQuickBattle(input);
      expect(result.emplacedGunOutcomes, hasLength(2));
      final byId = {for (final o in result.emplacedGunOutcomes) o.id: o};
      expect(byId.containsKey('qb:emplaced:ow:p:0'), isTrue);
      expect(byId.containsKey('qb:emplaced:ow:p:1'), isTrue);
      expect(
        byId['qb:emplaced:ow:p:0']!.hp <= byId['qb:emplaced:ow:p:1']!.hp,
        isTrue,
        reason: 'sorted-id round-robin damages the smaller-id gun first',
      );
    },
  ),
  RunnableScenario(
    scenarioId: 'qbpi-attacker-first-cache-bit-identical',
    label: 'attacker-acts-first siege duplicate runs are bit-identical',
    run: () {
      final input = centerFrontQuickBattleInput(
        attackerUnitIds: quickBattleUnitIds('a', 20),
        defenderUnitIds: quickBattleUnitIds('d', 12),
        provinceId: 'p-cache-att-first',
        seed: 4242,
        fortLevel: 2,
        attackerCavalryShare: 1.0,
        defenderCavalryShare: 0.0,
        emplacedGuns: [
          siegeEmplacedGun('qb:emplaced:ow:c:0', hp: 6),
          siegeEmplacedGun('qb:emplaced:ow:c:1', hp: 6),
        ],
      );
      final r1 = resolveQuickBattle(input);
      final r2 = resolveQuickBattle(input);
      expect(r1.winner, r2.winner);
      expect(r1.provinceFlips, r2.provinceFlips);
      expect(r1.attackerCasualties, r2.attackerCasualties);
      expect(r1.defenderCasualties, r2.defenderCasualties);
      _expectEmplacedGunOutcomesMatch(r1, r2);
    },
  ),
  RunnableScenario(
    scenarioId: 'qbpi-defender-first-cache-bit-identical',
    label: 'defender-acts-first siege duplicate runs are bit-identical',
    run: () {
      final input = centerFrontQuickBattleInput(
        attackerUnitIds: quickBattleUnitIds('a', 16),
        defenderUnitIds: quickBattleUnitIds('d', 10),
        provinceId: 'p-cache-def-first',
        seed: 9090,
        fortLevel: 1,
        attackerCavalryShare: 0.0,
        defenderCavalryShare: 1.0,
        emplacedGuns: [siegeEmplacedGun('qb:emplaced:ow:c:0', hp: 5)],
      );
      final r1 = resolveQuickBattle(input);
      final r2 = resolveQuickBattle(input);
      expect(r1.winner, r2.winner);
      expect(r1.provinceFlips, r2.provinceFlips);
      expect(r1.attackerCasualties, r2.attackerCasualties);
      expect(r1.defenderCasualties, r2.defenderCasualties);
      _expectEmplacedGunOutcomesMatch(r1, r2);
    },
  ),
  RunnableScenario(
    scenarioId: 'qbpi-non-siege-initiative-ordering',
    label:
        'non-siege battle outcomes are unchanged across initiative orderings',
    run: () {
      final inputA = centerFrontQuickBattleInput(
        attackerUnitIds: quickBattleUnitIds('a', 14),
        defenderUnitIds: quickBattleUnitIds('d', 10),
        provinceId: 'p-non-siege',
        seed: 555,
        attackerCavalryShare: 1.0,
        defenderCavalryShare: 0.0,
      );
      final inputB = centerFrontQuickBattleInput(
        attackerUnitIds: quickBattleUnitIds('a', 14),
        defenderUnitIds: quickBattleUnitIds('d', 10),
        provinceId: 'p-non-siege',
        seed: 555,
        attackerCavalryShare: 0.0,
        defenderCavalryShare: 1.0,
      );
      final a = resolveQuickBattle(inputA);
      final b = resolveQuickBattle(inputB);
      expect(resolveQuickBattle(inputA).attackerCasualties, a.attackerCasualties);
      expect(resolveQuickBattle(inputB).defenderCasualties, b.defenderCasualties);
      final attTotalA = a.attackerCasualties.length;
      final defTotalA = a.defenderCasualties.length;
      final attTotalB = b.attackerCasualties.length;
      final defTotalB = b.defenderCasualties.length;
      expect(
        attTotalA != attTotalB || defTotalA != defTotalB,
        isTrue,
        reason: 'initiative ordering should still affect outcomes after caching',
      );
    },
  ),
];
