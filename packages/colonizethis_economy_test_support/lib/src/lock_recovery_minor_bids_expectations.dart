// Compact lock-recovery minor auto-bid assertions (Refs #3939 phase 3 slice 15).
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
/// Data-driven expectations for [LockRecoveryMinorBidsScenario] rows.
// dart format off
class LockRecoveryMinorBidsExpectation {
  const LockRecoveryMinorBidsExpectation({this.isEmpty, this.minorIds, this.urgentGrainBidPerMinor});
  final bool? isEmpty;
  final List<String>? minorIds;
  final bool? urgentGrainBidPerMinor;
}
void assertLockRecoveryMinorBidsExpectation(Map<String, List<TradeOrder>> bids, LockRecoveryMinorBidsExpectation expectation) {
  if (expectation.isEmpty != null) {
    if (expectation.isEmpty!) {
      expect(bids, isEmpty);
    } else {
      expect(bids, isNotEmpty);
    }
  }
  if (expectation.minorIds != null) {
    expect(bids.keys, containsAll(expectation.minorIds!));
  }
  if (expectation.urgentGrainBidPerMinor == true) {
    for (final orders in bids.values) {
      expect(orders, hasLength(1));
      expect(orders.first.type, TradeOrderType.bid);
      expect(orders.first.commodityId, 'grain');
      expect(orders.first.priority, kLockRecoveryMinorBidPriority);
      expect(orders.first.quantity, kLockRecoveryMinorBidQuantityPerMinor);
    }
  }
}
// dart format on
