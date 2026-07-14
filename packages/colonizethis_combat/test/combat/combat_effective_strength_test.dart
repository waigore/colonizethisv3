// Copyright 2024 Robert W. Guenther
// SPDX-License-Identifier: Apache-2.0

import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';

void main() {
  runLabeledScenarioGroup(
    'combatEffectiveAttackerStrength',
    combatEffectiveAttackerStrengthScenarios(),
    (s) => s.run(),
  );

  runLabeledScenarioGroup(
    'combatEffectiveDefenderStrength',
    combatEffectiveDefenderStrengthScenarios(),
    (s) => s.run(),
  );

  runLabeledScenarioGroup(
    'combatEffectiveAttackForRatio',
    combatEffectiveAttackForRatioScenarios(),
    (s) => s.run(),
  );

  runLabeledScenarioGroup(
    'combatDefaultEmplacedStrength',
    combatDefaultEmplacedStrengthScenarios(),
    (s) => s.run(),
  );
}
