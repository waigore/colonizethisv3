// Table-driven consumption → production integration (Refs #4090 Slice A).

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

/// Consumption → Production order and strike interaction.
/// SPEC/game/workers-and-population.md, SPEC/program/turn-resolution-phase-details.md.
void main() {
  group('consumption then production', () {
    runLabeledScenarios(consumptionProductionIntegrationScenarios(), (
      scenario,
    ) {
      runConsumptionProductionIntegrationScenario(scenario);
    }, labelOf: (s) => s.label);
  });
}
