import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

void main() {
  group('call to arms (alliance mutual defence)', () {
    for (final scenario in callToArmsScenarios()) {
      test(scenario.label, () => runCallToArmsScenario(scenario));
    }
  });
}
