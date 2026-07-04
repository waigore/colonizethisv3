// Table-driven lock-recovery minor auto-bid scenarios (Refs #3856).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'lock_recovery_minor_bids_test_support.dart';

/// One row in [lockRecoveryMinorBidsScenarios].
typedef LockRecoveryMinorBidsScenario = ({
  String label,
  Game game,
  void Function(Map<String, List<TradeOrder>> bids) verify,
});

/// Canonical scenarios for `computeLockRecoveryMinorAutoBids`.
List<LockRecoveryMinorBidsScenario> lockRecoveryMinorBidsScenarios() => [
  (
    label: 'returns empty when no GP is broke',
    game: lockRecoveryGameWithTreasury(const {'gp1': 5000, 'gp2': 5000}),
    verify: (bids) => expect(bids, isEmpty),
  ),
  (
    label: 'returns empty when no minors exist',
    game: lockRecoveryGameWithoutMinors(gpTreasury: 100),
    verify: (bids) => expect(bids, isEmpty),
  ),
  (
    label: 'emits urgent grain bid per minor when a GP is broke',
    game: lockRecoveryGameWithTreasury(const {'gp1': 100, 'gp2': 5000}),
    verify: (bids) {
      expect(bids.keys, containsAll(['minor1', 'minor2']));
      for (final orders in bids.values) {
        expect(orders, hasLength(1));
        expect(orders.first.type, TradeOrderType.bid);
        expect(orders.first.commodityId, 'grain');
        expect(orders.first.priority, kLockRecoveryMinorBidPriority);
        expect(orders.first.quantity, kLockRecoveryMinorBidQuantityPerMinor);
      }
    },
  ),
];
