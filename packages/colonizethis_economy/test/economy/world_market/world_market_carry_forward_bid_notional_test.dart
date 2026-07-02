// Table-driven unit tests for `carryForwardBidNotionalByPlayer` (Refs #3122).
//
// SPEC/ai/treasury-planner.md § Treasury-budget-aware bid sizing.

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  final data.ResourceRules rules = data.ResourceRules.defaultRules;

  group('carryForwardBidNotionalByPlayer (Refs #3122)', () {
    // Empty-list, positive summation, unpriced/unknown-id skip, and offer /
    // zero-quantity skip behaviours are pinned by the shared parity suite
    // `world_market_bid_spend_shared_helper_test.dart` (Refs #3427).

    for (final scenario in carryForwardBidNotionalScenarios()) {
      test(scenario.label, () {
        runCarryForwardBidNotionalScenario(scenario, rules);
      });
    }
  });
}
