import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

/// Tests for economy_riches_to_treasury.dart. SPEC/program/turn-resolution-phases.md.
void main() {
  group('resolveRichesToTreasury', () {
    runLabeledScenarios(resolveRichesToTreasuryScenarios(), (scenario) {
      verifyResolveRichesToTreasuryScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('pendingRichesTreasuryDelta', () {
    runLabeledScenarios(pendingRichesTreasuryDeltaScenarios(), (scenario) {
      verifyPendingRichesTreasuryDeltaScenario(scenario);
    }, labelOf: (s) => s.label);
  });
}
