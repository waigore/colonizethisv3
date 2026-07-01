// Tests for the world-market player-context facade — Refs #3615 Cluster 2.
//
// SPEC/program/economy-models.md § Package locations (world-market player
// context facade), SPEC/program/world-market-resolution.md § Trade order
// validation / suggestion.
//
// Verifies `worldMarketPlayerContextFromGame` is the single Game→numeric
// snapshot build path and that `tradeOrderValidationContextFromGame` and
// `tradeSuggestionContextFromGame` are thin, behavior-preserving wrappers over
// it: identical shared scalars for the same (game, player), concern-specific
// availability sources preserved, staged treasury-budget parity, and ghost-id
// guard.

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  group('worldMarketPlayerContextFromGame (Refs #3615 Cluster 2)', () {
    test('surfaces the raw treasury budget for a known player', () {
      final game = buildTreasuryBidBudgetGame(treasury: 175);
      final base = worldMarketPlayerContextFromGame(game, humanPlayerId);
      expect(base.playerId, humanPlayerId);
      expect(base.treasuryBudgetForBids, 175);
      expect(base.worldMarketState, same(game.worldMarketState));
    });

    test('negative treasury clamps the snapshot budget at 0', () {
      final game = buildTreasuryBidBudgetGame(treasury: -25);
      final base = worldMarketPlayerContextFromGame(game, humanPlayerId);
      expect(base.treasuryBudgetForBids, 0);
    });

    test('ghost player id returns a zero-budget snapshot (ghost guard)', () {
      final game = buildTreasuryBidBudgetGame(treasury: 200);
      final base = worldMarketPlayerContextFromGame(game, 'gp_ghost');
      expect(base.treasuryBudgetForBids, 0);
    });

    test('staged orders + projectedTreasuryDelta reduce the snapshot budget '
        'by the projected non-bid deficit', () {
      final game = buildTreasuryBidBudgetGame(treasury: 175);
      final base = worldMarketPlayerContextFromGame(
        game,
        humanPlayerId,
        stagedOrders: humanOrdersWith(const <TradeOrder>[]),
        projectedTreasuryDelta: -50,
      );
      expect(base.treasuryBudgetForBids, 125);
    });
    // Refs #3661 step 2: the standalone twin-call "deterministic for identical
    // inputs" pin was removed. `worldMarketPlayerContextFromGame` is a pure
    // synchronous builder, and the scalars it re-asserted are already pinned
    // here (`treasuryBudgetForBids` above) and by the factory-parity group
    // below (`bidTypeCap`, `tradeCargoCapacity`), so double-invocation added no
    // coverage. Determinism that matters (sort/iteration order) is pinned by
    // dedicated ordering tests elsewhere in the suite.
  });

  group('factory parity over the shared snapshot (single build path)', () {
    test('validation and suggestion factories reuse identical shared scalars '
        'for the same (game, player)', () {
      final game = buildTreasuryBidBudgetGame(treasury: 175);
      final base = worldMarketPlayerContextFromGame(game, humanPlayerId);
      final validation = tradeOrderValidationContextFromGame(
        game,
        humanPlayerId,
      );
      final suggestion = tradeSuggestionContextFromGame(
        game,
        humanPlayerId,
        availableStockpileByCommodityId: const <CommodityId, int>{},
      );

      expect(validation.bidTypeCap, base.bidTypeCap);
      expect(validation.tradeCargoCapacity, base.tradeCargoCapacity);
      expect(validation.treasuryBudgetForBids, base.treasuryBudgetForBids);

      expect(suggestion.bidTypeCap, base.bidTypeCap);
      expect(suggestion.tradeCargoCapacity, base.tradeCargoCapacity);
      expect(suggestion.treasuryBudgetForBids, base.treasuryBudgetForBids);
    });

    test('validation and suggestion factories share the same staged '
        'treasury-budget composition', () {
      final game = buildTreasuryBidBudgetGame(treasury: 175);
      final validation = tradeOrderValidationContextFromGame(
        game,
        humanPlayerId,
        stagedOrders: humanOrdersWith(const <TradeOrder>[]),
        projectedTreasuryDelta: -50,
      );
      final suggestion = tradeSuggestionContextFromGame(
        game,
        humanPlayerId,
        availableStockpileByCommodityId: const <CommodityId, int>{},
        stagedOrders: humanOrdersWith(const <TradeOrder>[]),
        projectedTreasuryDelta: -50,
      );
      expect(validation.treasuryBudgetForBids, 125);
      expect(suggestion.treasuryBudgetForBids, 125);
    });
  });

  group('tradeSuggestionContextFromGame concern-specific behavior', () {
    test('passes the caller-supplied availability through unchanged (suggester '
        'raw-stockpile source is not replaced by offer caps)', () {
      final game = buildTreasuryBidBudgetGame(treasury: 100);
      const available = <CommodityId, int>{'timber': 7, 'grain': 3};
      final suggestion = tradeSuggestionContextFromGame(
        game,
        humanPlayerId,
        availableStockpileByCommodityId: available,
      );
      expect(suggestion.availableStockpileByCommodityId, available);
    });

    test('keeps the suggester defaults when need and priorities are omitted',
        () {
      final game = buildTreasuryBidBudgetGame(treasury: 100);
      final suggestion = tradeSuggestionContextFromGame(
        game,
        humanPlayerId,
        availableStockpileByCommodityId: const <CommodityId, int>{},
      );
      expect(suggestion.commodityNeedByCommodityId, isEmpty);
      expect(suggestion.offerPriority, TradeSuggestionContext.defaultOfferPriority);
      expect(suggestion.bidPriority, TradeSuggestionContext.defaultBidPriority);
    });

    test('forwards caller need and priority overrides', () {
      final game = buildTreasuryBidBudgetGame(treasury: 100);
      final suggestion = tradeSuggestionContextFromGame(
        game,
        humanPlayerId,
        availableStockpileByCommodityId: const <CommodityId, int>{},
        commodityNeedByCommodityId: const <CommodityId, int>{'iron': 4},
        offerPriority: 9,
        bidPriority: 2,
      );
      expect(suggestion.commodityNeedByCommodityId, const {'iron': 4});
      expect(suggestion.offerPriority, 9);
      expect(suggestion.bidPriority, 2);
    });
  });
}
