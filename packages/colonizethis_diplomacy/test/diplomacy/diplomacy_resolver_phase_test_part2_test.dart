import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

void main() {
  group('resolveDiplomacyPhase part2', () {
    for (final scenario in diplomacyResolverPhasePart2Scenarios()) {
      test(scenario.label, () => runDiplomacyPhaseScenario(scenario));
    }
  });
}
