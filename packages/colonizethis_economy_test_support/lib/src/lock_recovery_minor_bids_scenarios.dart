// Table-driven lock-recovery minor auto-bid scenarios (Refs #3856, #3939 slice 15).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'lock_recovery_minor_bids_expectations.dart';
import 'lock_recovery_minor_bids_test_support.dart';

/// One row in [lockRecoveryMinorBidsScenarios] (Refs #3939 slice 63).
typedef LockRecoveryMinorBidsScenario = ({
  String label,
  Game game,
  void Function(Map<String, List<TradeOrder>> bids) verify,
});

/// Compact expect-wired row (Refs #3939 slice 59).
// dart format off
LockRecoveryMinorBidsScenario lockRecoveryBidsRow({required String label, required Game game, required LockRecoveryMinorBidsExpectation expect}) =>
    (label: label, game: game, verify: (bids) => assertLockRecoveryMinorBidsExpectation(bids, expect));

/// Canonical scenarios for `computeLockRecoveryMinorAutoBids`.
List<LockRecoveryMinorBidsScenario> lockRecoveryMinorBidsScenarios() => [
  lockRecoveryBidsRow(label: 'returns empty when no GP is broke', game: lockRecoveryGameWithTreasury(const {'gp1': 5000, 'gp2': 5000}), expect: const LockRecoveryMinorBidsExpectation(isEmpty: true)),
  lockRecoveryBidsRow(label: 'returns empty when no minors exist', game: lockRecoveryGameWithoutMinors(gpTreasury: 100), expect: const LockRecoveryMinorBidsExpectation(isEmpty: true)),
  lockRecoveryBidsRow(
    label: 'emits urgent grain bid per minor when a GP is broke',
    game: lockRecoveryGameWithTreasury(const {'gp1': 100, 'gp2': 5000}),
    expect: const LockRecoveryMinorBidsExpectation(minorIds: ['minor1', 'minor2'], urgentGrainBidPerMinor: true),
  ),
];

/// Runs a lock-recovery minor-bids scenario row.
void runLockRecoveryMinorBidsScenario({required LockRecoveryMinorBidsScenario scenario, required WorldMarketState worldMarketState}) {
  final bids = computeLockRecoveryMinorAutoBids(game: scenario.game, worldMarketState: worldMarketState);
  scenario.verify(bids);
}
// dart format on
