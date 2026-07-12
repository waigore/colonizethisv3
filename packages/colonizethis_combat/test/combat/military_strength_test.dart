// Copyright 2024 Robert W. Guenther
// SPDX-License-Identifier: Apache-2.0

import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';

void main() {
  runLabeledScenarioGroup(
    'aggregateMilitaryStrengthForPlayer',
    aggregateMilitaryStrengthForPlayerScenarios(),
    (s) => s.run(),
  );

  runLabeledScenarioGroup(
    'aggregateStrength',
    aggregateStrengthScenarios(),
    (s) => s.run(),
  );

  runLabeledScenarioGroup(
    'effectiveEraForFaction',
    effectiveEraForFactionScenarios(),
    (s) => s.run(),
  );

  runLabeledScenarioGroup(
    'cavalryFraction',
    cavalryFractionScenarios(),
    (s) => s.run(),
  );
}
