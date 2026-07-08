import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

/// Tests for economy_riches_to_treasury.dart. SPEC/program/turn-resolution-phases.md.
void main() {
  group('resolveRichesToTreasury', () {
    for (final scenario in resolveRichesToTreasuryScenarios()) {
      test(scenario.label, () => verifyResolveRichesToTreasuryScenario(scenario));
    }
  });

  group('pendingRichesTreasuryDelta', () {
    for (final scenario in pendingRichesTreasuryDeltaScenarios()) {
      test(
        scenario.label,
        () => verifyPendingRichesTreasuryDeltaScenario(scenario),
      );
    }
  });
}
