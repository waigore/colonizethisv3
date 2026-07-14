// dart format off
// Compact world-market player-context facade assertions (Refs #3939 phase 3 slice 19).
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'treasury_test_support.dart';
/// Which factory path [PlayerContextExpectation] exercises.
enum PlayerContextScenarioTarget { snapshot, factoryParityScalars, factoryParityTreasury, suggestion }
/// Data-driven expectations for [PlayerContextScenario] rows.
class PlayerContextExpectation {
  const PlayerContextExpectation({required this.target, this.treasury = 100, this.playerId = humanPlayerId, this.treasuryBudgetForBids, this.worldMarketStateSameAsGame = false, this.stagedBids = const [], this.projectedTreasuryDelta = 0, this.availableStockpileByCommodityId = const {}, this.commodityNeedByCommodityId, this.offerPriority, this.bidPriority, this.checkDefaultNeedAndPriorities = false});
  final PlayerContextScenarioTarget target;
  final int treasury;
  final String playerId;
  final int? treasuryBudgetForBids;
  final bool worldMarketStateSameAsGame;
  final List<TradeOrder> stagedBids;
  final int projectedTreasuryDelta;
  final Map<CommodityId, int> availableStockpileByCommodityId;
  final Map<CommodityId, int>? commodityNeedByCommodityId;
  final int? offerPriority;
  final int? bidPriority;
  final bool checkDefaultNeedAndPriorities;
}
void assertPlayerContextExpectation(PlayerContextExpectation expectation) {
  final game = buildTreasuryBidBudgetGame(treasury: expectation.treasury);
  final Orders? stagedOrders = expectation.stagedBids.isNotEmpty ? humanOrdersWith(expectation.stagedBids) : (expectation.projectedTreasuryDelta != 0 ? humanOrdersWith(const <TradeOrder>[]) : null);
  switch (expectation.target) {
    case PlayerContextScenarioTarget.snapshot:
      final base = worldMarketPlayerContextFromGame(game, expectation.playerId, stagedOrders: stagedOrders, projectedTreasuryDelta: expectation.projectedTreasuryDelta);
      if (expectation.playerId == humanPlayerId) {
        expect(base.playerId, humanPlayerId);
      }
      if (expectation.treasuryBudgetForBids != null) {
        expect(base.treasuryBudgetForBids, expectation.treasuryBudgetForBids);
      }
      if (expectation.worldMarketStateSameAsGame) {
        expect(base.worldMarketState, same(game.worldMarketState));
      }
    case PlayerContextScenarioTarget.factoryParityScalars:
      final base = worldMarketPlayerContextFromGame(game, humanPlayerId);
      final validation = tradeOrderValidationContextFromGame(game, humanPlayerId);
      final suggestion = tradeSuggestionContextFromGame(game, humanPlayerId, availableStockpileByCommodityId: const <CommodityId, int>{});
      expect(validation.bidTypeCap, base.bidTypeCap);
      expect(validation.tradeCargoCapacity, base.tradeCargoCapacity);
      expect(validation.treasuryBudgetForBids, base.treasuryBudgetForBids);
      expect(suggestion.bidTypeCap, base.bidTypeCap);
      expect(suggestion.tradeCargoCapacity, base.tradeCargoCapacity);
      expect(suggestion.treasuryBudgetForBids, base.treasuryBudgetForBids);
    case PlayerContextScenarioTarget.factoryParityTreasury:
      final validation = tradeOrderValidationContextFromGame(game, humanPlayerId, stagedOrders: stagedOrders, projectedTreasuryDelta: expectation.projectedTreasuryDelta);
      final suggestion = tradeSuggestionContextFromGame(game, humanPlayerId, availableStockpileByCommodityId: const <CommodityId, int>{}, stagedOrders: stagedOrders, projectedTreasuryDelta: expectation.projectedTreasuryDelta);
      expect(validation.treasuryBudgetForBids, expectation.treasuryBudgetForBids);
      expect(suggestion.treasuryBudgetForBids, expectation.treasuryBudgetForBids);
    case PlayerContextScenarioTarget.suggestion:
      final suggestion = tradeSuggestionContextFromGame(game, humanPlayerId, availableStockpileByCommodityId: expectation.availableStockpileByCommodityId, stagedOrders: stagedOrders, projectedTreasuryDelta: expectation.projectedTreasuryDelta, commodityNeedByCommodityId: expectation.commodityNeedByCommodityId ?? const <CommodityId, int>{}, offerPriority: expectation.offerPriority ?? TradeSuggestionContext.defaultOfferPriority, bidPriority: expectation.bidPriority ?? TradeSuggestionContext.defaultBidPriority);
      if (expectation.availableStockpileByCommodityId.isNotEmpty) {
        expect(suggestion.availableStockpileByCommodityId, expectation.availableStockpileByCommodityId);
      }
      if (expectation.checkDefaultNeedAndPriorities) {
        expect(suggestion.commodityNeedByCommodityId, isEmpty);
        expect(suggestion.offerPriority, TradeSuggestionContext.defaultOfferPriority);
        expect(suggestion.bidPriority, TradeSuggestionContext.defaultBidPriority);
      }
      if (expectation.commodityNeedByCommodityId != null) {
        expect(suggestion.commodityNeedByCommodityId, expectation.commodityNeedByCommodityId);
      }
      if (expectation.offerPriority != null) {
        expect(suggestion.offerPriority, expectation.offerPriority);
      }
      if (expectation.bidPriority != null) {
        expect(suggestion.bidPriority, expectation.bidPriority);
      }
  }
}
// dart format on
