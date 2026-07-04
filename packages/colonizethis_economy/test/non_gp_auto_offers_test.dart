// SPEC-AC tests for `computeNonGreatPowerAutoOffers` — Issue #2991 C4.
//
// Anchors `SPEC/program/world-market-resolution.md` § Step A Gather (Step
// A.2) and `SPEC/game/world-market.md` § Minor and tribe auto-sell:
//
//   - One `TradeOrder(offer)` per contributing tile (per-tile attribution
//     so FRR #2992 D2/D4 can credit the owning Great Power).
//   - `priority == 1`, `originTileKey == tileKey`, `type == offer`.
//   - Riches commodities (`spices`, `silver`, `gold`, `gems`, `diamonds`)
//     are excluded from auto-offers per Requirement 11 (riches do not
//     trade — they auto-convert to treasury via the riches-to-treasury
//     phase, not the World Market).
//   - Empty fixtures (no minors/tribes, no tile maps, no connectivity)
//     produce no auto-offers (matches the legacy direct-handler test
//     contract for the World Market phase).

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  group('computeNonGreatPowerAutoOffers (SPEC AC: minor/tribe auto-sell)', () {
    for (final scenario in nonGpAutoOffersScenarios()) {
      test(scenario.label, () => runNonGpAutoOffersScenario(scenario));
    }
  });
}
