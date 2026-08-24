// Table-driven effective-strength scenarios (Refs #3865).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_test/test.dart';
import 'scenario_runner.dart';

/// Attacker-side effective-strength scenarios for [combatEffectiveAttackerStrength].
List<RunnableScenario> combatEffectiveAttackerStrengthScenarios() => [
  RunnableScenario(
    scenarioId: 'att-all-factors-no-fort',
    label: 'multiplies base by all factors when no fort applies',
    run: () {
      final eff = combatEffectiveAttackerStrength(
        base: 10.0,
        fortLevel: 0,
        factor1: 1.1,
        factor2: 1.05,
        factor3: 0.9,
      );

      expect(eff, equals(10.0 * 1.1 * 1.05 * 0.9));
    },
  ),
  RunnableScenario(
    scenarioId: 'att-omitted-factors-identity',
    label: 'omitted factors are the identity (bit-exact)',
    run: () {
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
    },
  ),
  RunnableScenario(
    scenarioId: 'att-fort-damage-reduction',
    label: 'applies fort damage reduction inside the siege range',
    run: () {
      // fortDamageReduction[2] == 0.45 -> attacker scaled by 0.55.
      final eff = combatEffectiveAttackerStrength(
        base: 10.0,
        fortLevel: 2,
        factor1: 2.0,
      );

      expect(eff, equals(10.0 * 2.0 * (1.0 - 0.45)));
    },
  ),
  RunnableScenario(
    scenarioId: 'att-fort-outside-range',
    label: 'does not apply reduction outside the siege range',
    run: () {
      final eff = combatEffectiveAttackerStrength(
        base: 10.0,
        fortLevel: 4,
        factor1: 2.0,
      );

      expect(eff, equals(20.0));
    },
  ),
];

/// Defender-side effective-strength scenarios for [combatEffectiveDefenderStrength].
List<RunnableScenario> combatEffectiveDefenderStrengthScenarios() => [
  RunnableScenario(
    scenarioId: 'def-ignores-emplaced-without-fort',
    label: 'multiplies base by factors and ignores emplaced without fort',
    run: () {
      final eff = combatEffectiveDefenderStrength(
        base: 8.0,
        fortLevel: 0,
        factor1: 1.2,
        emplacedStrength: 100.0,
      );

      expect(eff, equals(8.0 * 1.2));
    },
  ),
  RunnableScenario(
    scenarioId: 'def-adds-emplaced-in-siege',
    label: 'adds emplaced strength inside the siege range',
    run: () {
      final eff = combatEffectiveDefenderStrength(
        base: 8.0,
        fortLevel: 1,
        factor1: 1.0,
        emplacedStrength: 5.0,
      );

      expect(eff, equals(8.0 + 5.0));
    },
  ),
];

/// Ratio-side scenarios for [combatEffectiveAttackForRatio].
List<RunnableScenario> combatEffectiveAttackForRatioScenarios() => [
  RunnableScenario(
    scenarioId: 'ratio-outside-siege-range',
    label: 'returns effAtt unchanged outside the siege range',
    run: () {
      expect(
        combatEffectiveAttackForRatio(effAtt: 42.0, fortLevel: 0),
        equals(42.0),
      );
    },
  ),
  RunnableScenario(
    scenarioId: 'ratio-subtracts-wall-hp',
    label: 'subtracts wall HP inside the siege range',
    run: () {
      // wallHpByFortLevel[2] == 20.0
      expect(
        combatEffectiveAttackForRatio(effAtt: 50.0, fortLevel: 2),
        equals(30.0),
      );
    },
  ),
  RunnableScenario(
    scenarioId: 'ratio-clamps-zero',
    label: 'clamps to zero when wall HP exceeds effAtt',
    run: () {
      // wallHpByFortLevel[3] == 30.0
      expect(
        combatEffectiveAttackForRatio(effAtt: 5.0, fortLevel: 3),
        equals(0.0),
      );
    },
  ),
];

/// Default emplaced-gun scenarios for [combatDefaultEmplacedStrength].
List<RunnableScenario> combatDefaultEmplacedStrengthScenarios() => [
  RunnableScenario(
    scenarioId: 'emplaced-outside-range',
    label: 'returns 0 outside the siege range',
    run: () {
      expect(combatDefaultEmplacedStrength(0), equals(0.0));
      expect(combatDefaultEmplacedStrength(4), equals(0.0));
    },
  ),
  RunnableScenario(
    scenarioId: 'emplaced-gun-count-times-strength',
    label: 'returns gunCount * emplacedStrength inside the siege range',
    run: () {
      // fortGunCount[2] == 2, fortEmplacedStrength[2] == 4.0
      expect(combatDefaultEmplacedStrength(2), equals(2 * 4.0));
      // fortGunCount[1] == 1, fortEmplacedStrength[1] == 3.0
      expect(combatDefaultEmplacedStrength(1), equals(1 * 3.0));
    },
  ),
];
