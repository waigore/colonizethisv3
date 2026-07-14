// Table-driven DealMatcher scenarios (Refs #3836, #3939).
import 'package:colonizethis_models/colonizethis_models.dart';
import 'deal_matcher_expectations.dart';
import 'deal_matcher_scenario.dart';
import 'deal_matcher_test_support.dart';
/// Treasury clamp scenarios from `world_market_deal_matcher_treasury_test.dart`.
List<DealMatcherScenario> dealMatcherTreasuryScenarios() => [
  ...dealMatcherTreasuryClampScenarios(),
  ...dealMatcherTreasuryEdgeCaseScenarios(),
];
// dart format off
List<DealMatcherScenario> dealMatcherTreasuryClampScenarios() => [
  matcherRow(label: 'truncates a single oversized bid to floor(treasury / price)', inputs: matcherPairTrade(buyer: 'gp1', bidQty: 10, treasuryBudget: 100), expect: matcherSingleFillExpect(buyer: 'gp1', quantity: 3, pricePerUnit: 30.0, unfilledBidsByFactionId: matcherUnfilledBid('gp1', 7)), refs: '#3115'),
  matcherRow(label: 'per-buyer running tally exhausts treasury across bids in order', inputs: matcherInputs(offersByFactionId: {'sellerA': [matcherOffer('alpha', 5)], 'sellerB': [matcherOffer('beta', 5)]}, bidsByFactionId: {'gp1': [matcherBid('alpha', 5), matcherBid('beta', 5)]}, tradeCapacityByFactionId: const {'gp1': 100}, treasuryBudgetByBuyerFactionId: const {'gp1': 100}, pricesByCommodityId: const {'alpha': 20.0, 'beta': 20.0}), expect: matcherSingleFillExpect(commodity: 'alpha', quantity: 5, unfilledBidsByFactionId: matcherUnfilledBid('gp1', 5, commodity: 'beta')), refs: '#3115'),
  matcherPairRow(label: 'negative-treasury buyer treated as zero budget (full suppression)', buyer: 'gp1', bidQty: 10, treasuryBudgetByBuyerFactionId: const {'gp1': -50}, expect: matcherNoFillExpect(unfilledBidsByFactionId: matcherUnfilledBid('gp1', 10))),
  matcherRow(label: 'FRR pre-pass respects treasury clamp', inputs: matcherPairTrade(seller: 'M1', buyer: 'gpA', bidQty: 10, treasuryBudget: 60, pricesByCommodityId: const {'timber': 20.0}, originTileKey: kFrrMatcherTestTileKey, purchasedTileIndex: frrMatcherTestIndex()), expect: matcherSingleFillExpect(buyer: 'gpA', quantity: 3, isFrr: true, unfilledBidsByFactionId: {'gpA': [matcherBid('timber', 10).copyWith(quantity: 7)]}), refs: '#3115'),
];
List<DealMatcherScenario> dealMatcherTreasuryEdgeCaseScenarios() => [
  matcherRow(label: 'emits exactly one bidPartialFillTreasuryInsufficient note per truncated bid (full bid quantity carried in note)', inputs: matcherPairTrade(buyer: 'gp1', bidQty: 10, treasuryBudget: 100), expect: DealMatchExpectation(activityNotesByCommodityId: matcherTreasuryInsufficientNotes('gp1', 'timber', 10)), refs: '#3115'),
  matcherRow(label: 'two identical runs produce byte-identical FilledDeal sequences', inputs: matcherInputs(offersByFactionId: {'a': [matcherOffer('timber', 10)]}, bidsByFactionId: {'gp1': [matcherBid('timber', 10)], 'gp2': [matcherBid('timber', 10)]}, tradeCapacityByFactionId: const {'gp1': 100, 'gp2': 100}, treasuryBudgetByBuyerFactionId: const {'gp1': 100, 'gp2': 200}), deterministicRerun: true, expect: const DealMatchExpectation(), refs: '#3115'),
  matcherPairRow(label: 'zero-price commodity preserves legacy free-fill (no treasury debit)', buyer: 'gp1', commodity: 'iron', offerQty: 5, bidQty: 5, treasuryBudgetByBuyerFactionId: const {'gp1': 0}, pricesByCommodityId: const <CommodityId, double>{}, expect: matcherSingleFillExpect(pricePerUnit: 0.0, quantity: 5, activityNotesEmptyForCommodities: const ['iron'])),
  matcherPairRow(label: 'missing buyer entry in treasury budget treated as zero', buyer: 'gp1', offerQty: 5, bidQty: 5, treasuryBudgetByBuyerFactionId: const <String, int>{}, expect: matcherNoFillExpect(unfilledBidsByFactionId: matcherUnfilledBid('gp1', 5))),
  matcherPairRow(label: 'unaffordable bid at non-zero price emits a note even with zero fill quantity', buyer: 'gp1', offerQty: 1, bidQty: 1, treasuryBudgetByBuyerFactionId: const {'gp1': 10}, expect: DealMatchExpectation(filledDealsEmpty: true, activityNotesByCommodityId: matcherTreasuryInsufficientNotes('gp1', 'timber', 1))),
  matcherPairRow(label: 'cargo clamps tighter than treasury → matchQty falls back to cargo, no truncation note emitted', buyer: 'gp1', bidQty: 10, buyerCapacity: 4, treasuryBudgetByBuyerFactionId: const {'gp1': 10_000}, expect: matcherSingleFillExpect(quantity: 4, activityNotesEmptyForCommodities: const ['timber'])),
];
// dart format on
