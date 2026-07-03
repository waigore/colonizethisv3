import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

/// #3753 R7.3 sell-priority relation tiebreaker (matcher slice).
///
/// Covers the deal-matcher buyer reorder for Minor/Tribe seller offers:
/// consulate-holding buyers (those keyed in
/// `sellPriorityRelationByMinorTribeSeller`) are served first by descending
/// relation score, ties by ascending faction id; consulate-less buyers fall
/// back to default order; GP sellers (absent from the map) keep legacy order.
/// SPEC: `SPEC/program/world-market-resolution.md` § Step B item 4,
/// `SPEC/game/world-market.md` § Sell-priority relation tiebreaker.
void main() {
  group('DealMatcher.matchDeals — #3753 R7.3 sell-priority relation', () {
    for (final scenario in dealMatcherSellPriorityScenarios()) {
      test(scenario.label, () => runDealMatcherScenario(scenario));
    }
  });
}
