// Compact boycottedColonySellableCommodityIds assertions (Refs #3939 phase 3 slice 15).
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
/// Data-driven expectations for [BoycottBlockedCommoditiesScenario] rows.
// dart format off
class BoycottBlockedCommoditiesExpectation {
  const BoycottBlockedCommoditiesExpectation({
    this.blockedCommodityIds,
    this.isEmpty,
  });
  final Set<CommodityId>? blockedCommodityIds;
  final bool? isEmpty;
}
void assertBoycottBlockedCommoditiesExpectation(
  Set<CommodityId> blocked,
  BoycottBlockedCommoditiesExpectation expectation,
) {
  if (expectation.isEmpty != null) {
    if (expectation.isEmpty!) {
      expect(blocked, isEmpty);
    } else {
      expect(blocked, isNotEmpty);
    }
  }
  if (expectation.blockedCommodityIds != null) {
    expect(blocked, equals(expectation.blockedCommodityIds));
  }
}
// dart format on
