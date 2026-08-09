import 'package:colonizethis_test/test.dart';

import 'diplomacy_resolver_phase_scenarios.dart';

void main() {
  group('resolveDiplomacyPhase part2', () {
    for (final scenario in diplomacyResolverPhasePart2Scenarios()) {
      test(scenario.label, () => runDiplomacyPhaseScenario(scenario));
    }
  });
}
