// Tests for `tradeOrderValidationContextFromGame` — Refs #3123 budget-source
// acceptance criteria.
//
// SPEC/program/world-market-resolution.md § Validation (issue #2989).
//
// Verifies the validator context picks up the treasury bid budget from
// `treasuryAvailableForBidsByPlayer(game, playerId)` so rule 5 (cross-
// commodity bid spend) is enforced against live player state — both
// positive treasury (raw treasury surfaces directly) and negative
// treasury (clamped at zero per § Treasury budget for bids).

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  group('tradeOrderValidationContextFromGame (Refs #3123)', () {
    for (final scenario in tradeOrderValidatorContextTreasuryScenarios()) {
      test(scenario.label, scenario.run);
    }
  });
}
