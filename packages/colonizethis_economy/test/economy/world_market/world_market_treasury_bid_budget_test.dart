// Unit tests for `treasuryAvailableForBidsByPlayer` plus a SPEC
// composition group that reconstructs the UI treasury-bid-cap formula
// end-to-end (Refs #3093).
//
// SPEC/game/world-market.md § Treasury budget for bids,
// SPEC/ui/trade-screen.md § Market tab — treasury bid cap.

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  final data.ResourceRules rules = data.ResourceRules.defaultRules;

  group('treasuryAvailableForBidsByPlayer (Refs #3093)', () {
    for (final scenario in treasuryAvailableForBidsScenarios) {
      test(scenario.label, () {
        if (scenario.label.contains('default projectedNonBidTreasuryDelta')) {
          final game = buildTreasuryBidBudgetGame(treasury: scenario.treasury);
          expect(
            treasuryAvailableForBidsByPlayer(
              game: game,
              playerId: scenario.playerId,
            ),
            treasuryAvailableForBidsByPlayer(
              game: game,
              playerId: scenario.playerId,
              projectedNonBidTreasuryDelta: 0,
            ),
          );
        }
        if (scenario.label.contains('projectedNonBidTreasuryDelta is ignored')) {
          final game = buildTreasuryBidBudgetGame(treasury: scenario.treasury);
          expect(
            treasuryAvailableForBidsByPlayer(
              game: game,
              playerId: scenario.playerId,
              projectedNonBidTreasuryDelta: -25,
            ),
            0,
          );
        }
        runTreasuryAvailableScenario(scenario);
      });
    }
  });

  group('composition: UI clamp budget math (Refs #3093)', () {
    for (final scenario in treasuryUiCompositionScenarios(rules)) {
      test(scenario.label, () => runTreasuryUiCompositionScenario(scenario, rules));
    }
  });
}
