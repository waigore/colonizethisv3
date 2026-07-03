import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

/// Matcher-level coverage for the per-buyer treasury clamp added to Step C
/// (Refs #3115). The matcher receives `treasuryBudgetByBuyerFactionId`
/// in `DealMatchInputs`; this suite asserts the clamp behavior, FRR
/// integration, `bidPartialFillTreasuryInsufficient` note emission, the
/// missing-price defect path, and the missing-buyer-entry edge case.
///
/// SPEC anchors:
/// - `SPEC/program/world-market-resolution.md` § Step C — Match
///   (treasury clamp, running tally, note emission).
/// - `SPEC/program/world-market-resolution.md` § Deal matching engine
///   (`treasuryBudgetByBuyerFactionId` field; missing-entry → 0 budget).
void main() {
  group('DealMatcher.matchDeals — treasury clamp (Refs #3115)', () {
    for (final scenario in dealMatcherTreasuryScenarios()) {
      test(scenario.label, () => runDealMatcherScenario(scenario));
    }
  });
}
