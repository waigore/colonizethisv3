// Trade counsel ranking (Refs #4282, #4508 Slice D). Dense for repo.orders_test_support_loc.
// dart format off
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'support/counsel/trade_counsel_ranking_fixtures.dart';
import 'support/scenario_runner.dart';

void main() {
  runLabeledScenarioGroup('rankTradeCounselRecommendations', [
    rs('returns empty book for bare stockpile', () {final result = tcRank(tcGame()); expect(result.isEmpty, isTrue); expect(result.recommendations, isEmpty);}),
    rs('emits offer for large timber surplus', () {final offers = tcRank(tcGame(stockpile: tcTimberSurplus())).book.where((o) => o.type == TradeOrderType.offer); expect(offers, isNotEmpty); expect(offers.any((o) => o.commodityId == CommodityCatalog.timber.id), isTrue);}),
    rs('stable ids use bid:/offer: prefix', () {for (final rec in tcRank(tcGame(stockpile: tcTimberSurplus())).recommendations) {expect(rec.recommendationId, startsWith(rec.order.type == TradeOrderType.bid ? 'bid:' : 'offer:'));}}),
    rs('deterministic across identical inputs', () {final game = tcGame(stockpile: tcTimberSurplus(), treasury: tradeCounselTreasuryAffluenceThreshold()); final a = tcRank(game); final b = tcRank(game); expect(a.book, equals(b.book)); expect(a.recommendations.map((r) => r.recommendationId).toList(), equals(b.recommendations.map((r) => r.recommendationId).toList()));}),
    rs('includes speculative bid when affluent and under target', () {expect(tcRank(tcGame(stockpile: tcTimberSurplus(), treasury: tradeCounselTreasuryAffluenceThreshold())).book.any((o) => o.type == TradeOrderType.bid), isTrue, reason: 'F10 speculative pass should emit at least one bid');}),
    rs('excludes speculative bid below affluence threshold', () {expect(tcRank(tcGame(stockpile: tcSaturatedNonRichesExceptTimber(), treasury: tradeCounselTreasuryAffluenceThreshold() - 1)).book.where((o) => o.type == TradeOrderType.bid), isEmpty);}),
    rs('highlights at most three recommendations', () {final highlights = tcRank(tcGame(stockpile: Stockpile().applyDelta(CommodityCatalog.timber.id, 80).applyDelta(CommodityCatalog.iron.id, 80).applyDelta(CommodityCatalog.coal.id, 80).applyDelta(CommodityCatalog.grain.id, 80), treasury: tradeCounselTreasuryAffluenceThreshold())).recommendations.where((r) => r.isHighlight).toList(); expect(highlights.length, lessThanOrEqualTo(3)); expect(highlights, isNotEmpty);}),
  ], runRunnableScenario);
}
