// Table-driven Quick Battle emplaced-gun scenarios (Refs #3865).

import 'package:colonizethis_combat/src/combat/quick_battle_emplaced_guns.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'quick_battle_emplaced_guns_test_support.dart';

/// One row in a Quick Battle emplaced-gun scenario table.
class QuickBattleEmplacedGunScenario {
  const QuickBattleEmplacedGunScenario({
    required this.scenarioId,
    required this.label,
    required this.run,
  });

  final String scenarioId;
  final String label;
  final void Function() run;
}

/// Runs [scenario] (setup + assertions live in [QuickBattleEmplacedGunScenario.run]).
void runQuickBattleEmplacedGunScenario(QuickBattleEmplacedGunScenario scenario) {
  scenario.run();
}

/// Scenarios for [MutableEmplacedGun.fromInput].
List<QuickBattleEmplacedGunScenario> mutableEmplacedGunFromInputScenarios() => [
  QuickBattleEmplacedGunScenario(
    scenarioId: 'meg-from-input',
    label: 'copies all fields from immutable input gun',
    run: () {
      const input = QuickBattleEmplacedGun(
        id: 'g0',
        maxHp: 5,
        hp: 3,
        attackStrength: 1.5,
        defenseStrength: 2.5,
        rng: 7,
      );

      final m = MutableEmplacedGun.fromInput(input);

      expect(m.id, 'g0');
      expect(m.maxHp, 5);
      expect(m.hp, 3);
      expect(m.attackStrength, 1.5);
      expect(m.defenseStrength, 2.5);
    },
  ),
];

/// Scenarios for [aliveGunStrengthSum].
List<QuickBattleEmplacedGunScenario> aliveGunStrengthSumScenarios() => [
  QuickBattleEmplacedGunScenario(
    scenarioId: 'ags-sum-alive',
    label: 'sums attack+defense over alive guns and skips dead',
    run: () {
      final guns = [emplacedGun('a', 4), emplacedGun('b', 0), emplacedGun('c', 2)];

      expect(aliveGunStrengthSum(guns), closeTo(10.0, 1e-9));
    },
  ),
  QuickBattleEmplacedGunScenario(
    scenarioId: 'ags-empty',
    label: 'empty list yields 0.0',
    run: () {
      expect(aliveGunStrengthSum(const []), 0.0);
    },
  ),
];

/// Scenarios for [sumAliveGunHp].
List<QuickBattleEmplacedGunScenario> sumAliveGunHpScenarios() => [
  QuickBattleEmplacedGunScenario(
    scenarioId: 'sah-sum-hp',
    label: 'sums hp over alive guns only',
    run: () {
      final guns = [emplacedGun('a', 4), emplacedGun('b', 0), emplacedGun('c', 2)];

      expect(sumAliveGunHp(guns), 6);
    },
  ),
];

/// Scenarios for [applyRoundRobinGunHpDamage].
List<QuickBattleEmplacedGunScenario> applyRoundRobinGunHpDamageScenarios() => [
  QuickBattleEmplacedGunScenario(
    scenarioId: 'rrd-noop',
    label: 'non-positive amount is a no-op',
    run: () {
      final guns = [emplacedGun('a', 4), emplacedGun('b', 4)];

      applyRoundRobinGunHpDamage(guns, 0);
      applyRoundRobinGunHpDamage(guns, -3);

      expect(guns.map((g) => g.hp), [4, 4]);
    },
  ),
  QuickBattleEmplacedGunScenario(
    scenarioId: 'rrd-round-robin',
    label: 'distributes damage round-robin by id order',
    run: () {
      final guns = [emplacedGun('b', 4), emplacedGun('a', 4)];

      applyRoundRobinGunHpDamage(guns, 3);

      // Sorted by id: a then b. 3 points → a,b,a → a:2, b:3.
      final byId = {for (final g in guns) g.id: g.hp};
      expect(byId['a'], 2);
      expect(byId['b'], 3);
    },
  ),
  QuickBattleEmplacedGunScenario(
    scenarioId: 'rrd-skip-dead',
    label: 'skips fully destroyed guns and keeps damaging survivors',
    run: () {
      final guns = [emplacedGun('a', 1), emplacedGun('b', 4)];

      applyRoundRobinGunHpDamage(guns, 4);

      // a starts at 1: first hit kills it; remaining 3 all land on b.
      final byId = {for (final g in guns) g.id: g.hp};
      expect(byId['a'], 0);
      expect(byId['b'], 1);
    },
  ),
  QuickBattleEmplacedGunScenario(
    scenarioId: 'rrd-overkill',
    label: 'damage exceeding total HP drives all guns to zero',
    run: () {
      final guns = [emplacedGun('a', 2), emplacedGun('b', 2)];

      applyRoundRobinGunHpDamage(guns, 99);

      expect(guns.every((g) => g.hp <= 0), isTrue);
    },
  ),
];
