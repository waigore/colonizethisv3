// Copyright 2024 Robert W. Guenther
// SPDX-License-Identifier: Apache-2.0

import 'package:colonizethis_combat/src/combat/combat_effective_strength.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('combatEffectiveAttackerStrength', () {
    test('multiplies base by all factors when no fort applies', () {
      final eff = combatEffectiveAttackerStrength(
        base: 10.0,
        fortLevel: 0,
        factor1: 1.1,
        factor2: 1.05,
        factor3: 0.9,
      );

      expect(eff, equals(10.0 * 1.1 * 1.05 * 0.9));
    });

    test('omitted factors are the identity (bit-exact)', () {
      final full = combatEffectiveAttackerStrength(
        base: 13.0,
        fortLevel: 0,
        factor1: 1.1,
        factor2: 1.0,
        factor3: 1.0,
      );
      final partial = combatEffectiveAttackerStrength(
        base: 13.0,
        fortLevel: 0,
        factor1: 1.1,
      );

      expect(partial, equals(full));
    });

    test('applies fort damage reduction inside the siege range', () {
      // fortDamageReduction[2] == 0.45 -> attacker scaled by 0.55.
      final eff = combatEffectiveAttackerStrength(
        base: 10.0,
        fortLevel: 2,
        factor1: 2.0,
      );

      expect(eff, equals(10.0 * 2.0 * (1.0 - 0.45)));
    });

    test('does not apply reduction outside the siege range', () {
      final eff = combatEffectiveAttackerStrength(
        base: 10.0,
        fortLevel: 4,
        factor1: 2.0,
      );

      expect(eff, equals(20.0));
    });
  });

  group('combatEffectiveDefenderStrength', () {
    test('multiplies base by factors and ignores emplaced without fort', () {
      final eff = combatEffectiveDefenderStrength(
        base: 8.0,
        fortLevel: 0,
        factor1: 1.2,
        emplacedStrength: 100.0,
      );

      expect(eff, equals(8.0 * 1.2));
    });

    test('adds emplaced strength inside the siege range', () {
      final eff = combatEffectiveDefenderStrength(
        base: 8.0,
        fortLevel: 1,
        factor1: 1.0,
        emplacedStrength: 5.0,
      );

      expect(eff, equals(8.0 + 5.0));
    });
  });

  group('combatEffectiveAttackForRatio', () {
    test('returns effAtt unchanged outside the siege range', () {
      expect(
        combatEffectiveAttackForRatio(effAtt: 42.0, fortLevel: 0),
        equals(42.0),
      );
    });

    test('subtracts wall HP inside the siege range', () {
      // wallHpByFortLevel[2] == 20.0
      expect(
        combatEffectiveAttackForRatio(effAtt: 50.0, fortLevel: 2),
        equals(30.0),
      );
    });

    test('clamps to zero when wall HP exceeds effAtt', () {
      // wallHpByFortLevel[3] == 30.0
      expect(
        combatEffectiveAttackForRatio(effAtt: 5.0, fortLevel: 3),
        equals(0.0),
      );
    });
  });

  group('combatDefaultEmplacedStrength', () {
    test('returns 0 outside the siege range', () {
      expect(combatDefaultEmplacedStrength(0), equals(0.0));
      expect(combatDefaultEmplacedStrength(4), equals(0.0));
    });

    test('returns gunCount * emplacedStrength inside the siege range', () {
      // fortGunCount[2] == 2, fortEmplacedStrength[2] == 4.0
      expect(combatDefaultEmplacedStrength(2), equals(2 * 4.0));
      // fortGunCount[1] == 1, fortEmplacedStrength[1] == 3.0
      expect(combatDefaultEmplacedStrength(1), equals(1 * 3.0));
    });
  });
}
