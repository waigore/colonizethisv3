// Copyright 2024 Robert W. Guenther
// SPDX-License-Identifier: Apache-2.0

import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('combatEffectiveAttackerStrength', () {
    for (final scenario in combatEffectiveAttackerStrengthScenarios()) {
      test(scenario.label, () => runEffectiveStrengthScenario(scenario));
    }
  });

  group('combatEffectiveDefenderStrength', () {
    for (final scenario in combatEffectiveDefenderStrengthScenarios()) {
      test(scenario.label, () => runEffectiveStrengthScenario(scenario));
    }
  });

  group('combatEffectiveAttackForRatio', () {
    for (final scenario in combatEffectiveAttackForRatioScenarios()) {
      test(scenario.label, () => runEffectiveStrengthScenario(scenario));
    }
  });

  group('combatDefaultEmplacedStrength', () {
    for (final scenario in combatDefaultEmplacedStrengthScenarios()) {
      test(scenario.label, () => runEffectiveStrengthScenario(scenario));
    }
  });
}
