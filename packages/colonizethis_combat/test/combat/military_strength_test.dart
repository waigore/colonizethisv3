// Copyright 2024 Robert W. Guenther
// SPDX-License-Identifier: Apache-2.0

import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('aggregateMilitaryStrengthForPlayer', () {
    for (final scenario in aggregateMilitaryStrengthForPlayerScenarios()) {
      test(scenario.label, () => runMilitaryStrengthScenario(scenario));
    }
  });

  group('aggregateStrength', () {
    for (final scenario in aggregateStrengthScenarios()) {
      test(scenario.label, () => runMilitaryStrengthScenario(scenario));
    }
  });

  group('effectiveEraForFaction', () {
    for (final scenario in effectiveEraForFactionScenarios()) {
      test(scenario.label, () => runMilitaryStrengthScenario(scenario));
    }
  });

  group('cavalryFraction', () {
    for (final scenario in cavalryFractionScenarios()) {
      test(scenario.label, () => runMilitaryStrengthScenario(scenario));
    }
  });
}
