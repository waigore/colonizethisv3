import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

void main() {
  group('resolveDiplomacyPhase', () {
    for (final scenario in diplomacyResolverPhasePart1Scenarios()) {
      test(scenario.label, () => runDiplomacyPhaseScenario(scenario));
    }
  });
}
