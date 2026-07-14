// dart format off
// Table-driven world-market admission helper scenarios (Refs #3856).
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'trade_order_factory.dart';
/// One row in [commoditiesWithBidAndOfferScenarios].
typedef CommoditiesWithBidAndOfferScenario = ({String label, List<TradeOrder> proposedOrders, Set<CommodityId> expected, String? refs});
/// Canonical scenarios for [commoditiesWithBidAndOffer] (rule 3).
List<CommoditiesWithBidAndOfferScenario> commoditiesWithBidAndOfferScenarios() => [
  (label: 'returns commodities appearing as both bid and offer', proposedOrders: [testBid('timber', 5), testOffer('timber', 5), testBid('iron', 5), testOffer('wool', 5)], expected: {'timber'}, refs: '#3615'),
  (label: 'returns const empty set when no offer side exists', proposedOrders: [testBid('timber', 5), testBid('iron', 5)], expected: {}, refs: '#3615'),
  (label: 'returns const empty set when no bid side exists', proposedOrders: [testOffer('timber', 5), testOffer('iron', 5)], expected: {}, refs: '#3615'),
  (label: 'handles multiple overlapping commodities', proposedOrders: [testBid('timber', 5), testOffer('timber', 5), testBid('iron', 5), testOffer('iron', 5), testOffer('wool', 5)], expected: {'timber', 'iron'}, refs: '#3615'),
];
/// One row in [admittedBidCommodityIdsScenarios].
typedef AdmittedBidCommodityIdsScenario = ({String label, List<TradeOrder> proposedOrders, int bidTypeCap, Set<CommodityId> mutuallyExcludedCommodityIds, Set<CommodityId> expected, String? refs});
/// Canonical scenarios for [admittedBidCommodityIdsInSubmissionOrder] (rule 4).
List<AdmittedBidCommodityIdsScenario> admittedBidCommodityIdsScenarios() => [
  (label: 'admits distinct bid commodities in submission order up to the cap', proposedOrders: [testBid('wool', 1), testBid('iron', 1), testBid('coal', 1), testBid('timber', 1)], bidTypeCap: 3, mutuallyExcludedCommodityIds: {}, expected: {'wool', 'iron', 'coal'}, refs: '#3615'),
  (label: 'a repeat bid on an admitted commodity does not consume a slot', proposedOrders: [testBid('wool', 1), testBid('wool', 2), testBid('iron', 1), testBid('coal', 1)], bidTypeCap: 3, mutuallyExcludedCommodityIds: {}, expected: {'wool', 'iron', 'coal'}, refs: '#3615'),
  (label: 'skips non-positive quantities, riches, and mutually-excluded ids', proposedOrders: [testBid('timber', 0), testBid('gold', 5), testBid('iron', 5), testBid('wool', 5), testBid('coal', 5)], bidTypeCap: 6, mutuallyExcludedCommodityIds: {'iron'}, expected: {'wool', 'coal'}, refs: '#3615'),
  (label: 'returns const empty set when bidTypeCap <= 0', proposedOrders: [testBid('timber', 5)], bidTypeCap: 0, mutuallyExcludedCommodityIds: {}, expected: {}, refs: '#3615'),
  (label: 'ignores offers entirely', proposedOrders: [testOffer('timber', 5), testBid('iron', 5)], bidTypeCap: 6, mutuallyExcludedCommodityIds: {}, expected: {'iron'}, refs: '#3615'),
];
/// Verifies admitted-bid scenario expectations including timber exclusion pin.
void verifyAdmittedBidCommodityIdsScenario(AdmittedBidCommodityIdsScenario scenario) {
  final admitted = admittedBidCommodityIdsInSubmissionOrder(proposedOrders: scenario.proposedOrders, bidTypeCap: scenario.bidTypeCap, mutuallyExcludedCommodityIds: scenario.mutuallyExcludedCommodityIds);
  expect(admitted, scenario.expected);
  if (scenario.label.startsWith('admits distinct bid commodities')) {
    expect(admitted.contains('timber'), isFalse);
  }
}
// dart format on
