import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

/// SPEC: SPEC/game/world-market-first-right-of-refusal.md § Rules
/// (#2992 D2 — First Right of Refusal absolute-priority override in
/// `DealMatcher.matchDeals`). The behavior of the helper FRR profit
/// formula and the purchased-tile index is covered by D1/D3 tests; this
/// file exercises the matcher integration only.
void main() {
  group('DealMatcher.matchDeals — First Right of Refusal (#2992 D2)', () {
    for (final scenario in dealMatcherFirstRightScenarios()) {
      test(scenario.label, () => runDealMatcherScenario(scenario));
    }
  });
}
