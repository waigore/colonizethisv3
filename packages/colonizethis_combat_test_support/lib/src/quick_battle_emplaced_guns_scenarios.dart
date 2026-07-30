// Table-driven Quick Battle emplaced-gun scenarios (Refs #3865).

import 'package:colonizethis_combat/src/combat/quick_battle_emplaced_guns.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'quick_battle_emplaced_guns_test_support.dart';
import 'scenario_runner.dart';



/// Scenarios for [MutableEmplacedGun.fromInput].
List<RunnableScenario> mutableEmplacedGunFromInputScenarios() => [
  RunnableScenario(
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
List<RunnableScenario> aliveGunStrengthSumScenarios() => [
  RunnableScenario(
    scenarioId: 'ags-sum-alive',
    label: 'sums attack+defense over alive guns and skips dead',
    run: () {
      final guns = [emplacedGun('a', 4), emplacedGun('b', 0), emplacedGun('c', 2)];

      expect(aliveGunStrengthSum(guns), closeTo(10.0, 1e-9));
    },
  ),
  RunnableScenario(
    scenarioId: 'ags-empty',
    label: 'empty list yields 0.0',
    run: () {
      expect(aliveGunStrengthSum(const []), 0.0);
    },
  ),
];

/// Scenarios for [sumAliveGunHp].
List<RunnableScenario> sumAliveGunHpScenarios() => [
  RunnableScenario(
    scenarioId: 'sah-sum-hp',
    label: 'sums hp over alive guns only',
    run: () {
      final guns = [emplacedGun('a', 4), emplacedGun('b', 0), emplacedGun('c', 2)];

      expect(sumAliveGunHp(guns), 6);
    },
  ),
];

/// Scenarios for [applyRoundRobinGunHpDamage].
List<RunnableScenario> applyRoundRobinGunHpDamageScenarios() => [
  RunnableScenario(
    scenarioId: 'rrd-noop',
    label: 'non-positive amount is a no-op',
    run: () {
      final guns = [emplacedGun('a', 4), emplacedGun('b', 4)];

      applyRoundRobinGunHpDamage(guns, 0);
      applyRoundRobinGunHpDamage(guns, -3);

      expect(guns.map((g) => g.hp), [4, 4]);
    },
  ),
  RunnableScenario(
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
  RunnableScenario(
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
  RunnableScenario(
    scenarioId: 'rrd-overkill',
    label: 'damage exceeding total HP drives all guns to zero',
    run: () {
      final guns = [emplacedGun('a', 2), emplacedGun('b', 2)];

      applyRoundRobinGunHpDamage(guns, 99);

      expect(guns.every((g) => g.hp <= 0), isTrue);
    },
  ),
];
