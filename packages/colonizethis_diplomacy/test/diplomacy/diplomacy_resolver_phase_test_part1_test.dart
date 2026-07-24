import 'package:colonizethis_test/test.dart';

import 'diplomacy_resolver_phase_scenarios.dart';

void main() {
  group('resolveDiplomacyPhase', () {
    for (final scenario in diplomacyResolverPhasePart1Scenarios()) {
      test(scenario.label, () => runDiplomacyPhaseScenario(scenario));
    }
  });
}
