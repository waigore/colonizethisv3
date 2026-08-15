import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'treasury_test_support.dart';
// dart format off
// Table-driven world-market player-context facade scenarios (Refs #3856, #3939 slice 19).
/// One row for `PlayerContextScenario` tables (Refs #3979).
typedef PlayerContextScenario = ({String label, PlayerContextExpectation expect, String? refs});
/// Compact expect-wired row (Refs #3939 slice 59, #3979).
PlayerContextScenario playerContextRow({required String label, required PlayerContextExpectation expect, String? refs}) => (label: label, expect: expect, refs: refs);
void runPlayerContextScenario(PlayerContextScenario scenario) {
  assertPlayerContextExpectation(scenario.expect);
}
/// `worldMarketPlayerContextFromGame` snapshot cases (Refs #3615 Cluster 2).
List<PlayerContextScenario> worldMarketPlayerContextSnapshotScenarios() => [
  playerContextRow(
    label: 'surfaces the raw treasury budget for a known player',
    expect: const PlayerContextExpectation(target: PlayerContextScenarioTarget.snapshot, treasury: 175, treasuryBudgetForBids: 175, worldMarketStateSameAsGame: true),
    refs: '#3615',
  ),
  playerContextRow(
    label: 'negative treasury clamps the snapshot budget at 0',
    expect: const PlayerContextExpectation(target: PlayerContextScenarioTarget.snapshot, treasury: -25, treasuryBudgetForBids: 0),
    refs: '#3615',
  ),
  playerContextRow(
    label: 'ghost player id returns a zero-budget snapshot (ghost guard)',
    expect: const PlayerContextExpectation(target: PlayerContextScenarioTarget.snapshot, treasury: 200, playerId: 'gp_ghost', treasuryBudgetForBids: 0),
    refs: '#3615',
  ),
  playerContextRow(
    label:
        'staged orders + projectedTreasuryDelta reduce the snapshot budget '
        'by the projected non-bid deficit',
    expect: const PlayerContextExpectation(target: PlayerContextScenarioTarget.snapshot, treasury: 175, treasuryBudgetForBids: 125, projectedTreasuryDelta: -50),
    refs: '#3615',
  ),
];
/// Factory parity over the shared snapshot (single build path).
List<PlayerContextScenario> worldMarketPlayerContextFactoryParityScenarios() => [
  playerContextRow(
    label:
        'validation and suggestion factories reuse identical shared scalars '
        'for the same (game, player)',
    expect: const PlayerContextExpectation(target: PlayerContextScenarioTarget.factoryParityScalars, treasury: 175),
    refs: '#3615',
  ),
  playerContextRow(
    label:
        'validation and suggestion factories share the same staged '
        'treasury-budget composition',
    expect: const PlayerContextExpectation(target: PlayerContextScenarioTarget.factoryParityTreasury, treasury: 175, treasuryBudgetForBids: 125, projectedTreasuryDelta: -50),
    refs: '#3615',
  ),
];
/// `tradeSuggestionContextFromGame` concern-specific behavior.
List<PlayerContextScenario> tradeSuggestionContextFromGameBehaviorScenarios() => [
  playerContextRow(
    label:
        'passes the caller-supplied availability through unchanged (suggester '
        'raw-stockpile source is not replaced by offer caps)',
    expect: const PlayerContextExpectation(target: PlayerContextScenarioTarget.suggestion, treasury: 100, availableStockpileByCommodityId: {'timber': 7, 'grain': 3}),
    refs: '#3615',
  ),
  playerContextRow(
    label: 'keeps the suggester defaults when need and priorities are omitted',
    expect: const PlayerContextExpectation(target: PlayerContextScenarioTarget.suggestion, treasury: 100, checkDefaultNeedAndPriorities: true),
    refs: '#3615',
  ),
  playerContextRow(
    label: 'forwards caller need and priority overrides',
    expect: const PlayerContextExpectation(target: PlayerContextScenarioTarget.suggestion, treasury: 100, commodityNeedByCommodityId: {'iron': 4}, offerPriority: 9, bidPriority: 2),
    refs: '#3615',
  ),
];
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
