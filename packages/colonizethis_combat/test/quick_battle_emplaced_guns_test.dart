import 'package:colonizethis_combat/src/combat/quick_battle_emplaced_guns.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

MutableEmplacedGun _gun(String id, int hp, {double att = 2.0, double def = 3.0}) =>
    MutableEmplacedGun(
      id: id,
      maxHp: 4,
      hp: hp,
      attackStrength: att,
      defenseStrength: def,
    );

void main() {
  group('MutableEmplacedGun.fromInput', () {
    test('copies all fields from immutable input gun', () {
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
    });
  });

  group('aliveGunStrengthSum', () {
    test('sums attack+defense over alive guns and skips dead', () {
      final guns = [_gun('a', 4), _gun('b', 0), _gun('c', 2)];

      expect(aliveGunStrengthSum(guns), closeTo(10.0, 1e-9));
    });

    test('empty list yields 0.0', () {
      expect(aliveGunStrengthSum(const []), 0.0);
    });
  });

  group('sumAliveGunHp', () {
    test('sums hp over alive guns only', () {
      final guns = [_gun('a', 4), _gun('b', 0), _gun('c', 2)];

      expect(sumAliveGunHp(guns), 6);
    });
  });

  group('applyRoundRobinGunHpDamage', () {
    test('non-positive amount is a no-op', () {
      final guns = [_gun('a', 4), _gun('b', 4)];

      applyRoundRobinGunHpDamage(guns, 0);
      applyRoundRobinGunHpDamage(guns, -3);

      expect(guns.map((g) => g.hp), [4, 4]);
    });

    test('distributes damage round-robin by id order', () {
      final guns = [_gun('b', 4), _gun('a', 4)];

      applyRoundRobinGunHpDamage(guns, 3);

      // Sorted by id: a then b. 3 points → a,b,a → a:2, b:3.
      final byId = {for (final g in guns) g.id: g.hp};
      expect(byId['a'], 2);
      expect(byId['b'], 3);
    });

    test('skips fully destroyed guns and keeps damaging survivors', () {
      final guns = [_gun('a', 1), _gun('b', 4)];

      applyRoundRobinGunHpDamage(guns, 4);

      // a starts at 1: first hit kills it; remaining 3 all land on b.
      final byId = {for (final g in guns) g.id: g.hp};
      expect(byId['a'], 0);
      expect(byId['b'], 1);
    });

    test('damage exceeding total HP drives all guns to zero', () {
      final guns = [_gun('a', 2), _gun('b', 2)];

      applyRoundRobinGunHpDamage(guns, 99);

      expect(guns.every((g) => g.hp <= 0), isTrue);
    });
  });
}
