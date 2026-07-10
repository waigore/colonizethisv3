// SPEC-AC tests for `computeNonGreatPowerAutoOffers` purchased-tile parity —
// Issue #2991 C6.
//
// Anchors:
//   - `SPEC/game/world-market.md` § Minor and tribe auto-sell — acceptance
//     criteria *Purchased-tile non-riches auto-offer — emission* and
//     *Purchased-tile non-riches auto-offer — parity with unpurchased tiles*.
//   - `SPEC/game/world-market.md` § First right of refusal — *Riches handoff*
//     (purchased riches tiles route via `computePurchasedTileRichesCredits`
//     in phase 3, not the world market).
//
// C6 invariant: the minor/tribe auto-offer iteration treats purchased and
// unpurchased tiles identically. Purchased-tile attribution flows separately
// through `PurchasedTileIndex.fromGame` into the deal matcher's FRR routing
// (Refs #2992 D2/D4); the auto-offer emission contract is independent of
// purchased status.

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  runLabeledScenarioGroup(
    'computeNonGreatPowerAutoOffers — purchased-tile parity (Refs #2991 C6)',
    nonGpAutoOffersPurchasedTileScenarios(),
    runNonGpAutoOffersScenario,
  );
}
