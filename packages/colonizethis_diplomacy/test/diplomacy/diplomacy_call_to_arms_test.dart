import 'package:colonizethis_test/test.dart';

import 'call_to_arms_scenarios.dart';

void main() {
  group('call to arms (alliance mutual defence)', () {
    for (final scenario in callToArmsScenarios()) {
      test(scenario.label, () => runCallToArmsScenario(scenario));
    }
  });
}
