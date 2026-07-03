// Table-driven unit tests for WorldMarketContextBase (Refs #3856).
// SPEC/game/world-market.md — issue #3396 cluster 4.

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('WorldMarketContextBase', () {
    for (final scenario in worldMarketContextBaseScenarios()) {
      test(scenario.label, () {
        final ctx = buildWorldMarketContextBaseScenario(scenario);
        scenario.verify(ctx);
      });
    }
  });
}
