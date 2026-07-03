// Table-driven unit tests for lock-recovery minor auto-bids (Refs #3856).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  group('computeLockRecoveryMinorAutoBids', () {
    for (final scenario in lockRecoveryMinorBidsScenarios()) {
      test(scenario.label, () {
        final bids = computeLockRecoveryMinorAutoBids(
          game: scenario.game,
          worldMarketState: lockRecoveryGrainMarket(),
        );
        scenario.verify(bids);
      });
    }
  });
}
