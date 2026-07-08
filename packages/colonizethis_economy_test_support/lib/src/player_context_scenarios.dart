// Table-driven world-market player-context facade scenarios (Refs #3856).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'treasury_scenarios/treasury_test_support.dart';

/// One row in a player-context scenario table.
class PlayerContextScenario {
  const PlayerContextScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  final String label;
  final void Function() run;
  final String? refs;
}

/// Runs [scenario] (setup + assertions live in [PlayerContextScenario.run]).
void runPlayerContextScenario(PlayerContextScenario scenario) {
  scenario.run();
}

/// `worldMarketPlayerContextFromGame` snapshot cases (Refs #3615 Cluster 2).
List<PlayerContextScenario> worldMarketPlayerContextSnapshotScenarios() => [
  PlayerContextScenario(
    label: 'surfaces the raw treasury budget for a known player',
    run: () {
      final game = buildTreasuryBidBudgetGame(treasury: 175);
      final base = worldMarketPlayerContextFromGame(game, humanPlayerId);
      expect(base.playerId, humanPlayerId);
      expect(base.treasuryBudgetForBids, 175);
      expect(base.worldMarketState, same(game.worldMarketState));
    },
    refs: '#3615',
  ),
  PlayerContextScenario(
    label: 'negative treasury clamps the snapshot budget at 0',
    run: () {
      final game = buildTreasuryBidBudgetGame(treasury: -25);
      final base = worldMarketPlayerContextFromGame(game, humanPlayerId);
      expect(base.treasuryBudgetForBids, 0);
    },
    refs: '#3615',
  ),
  PlayerContextScenario(
    label: 'ghost player id returns a zero-budget snapshot (ghost guard)',
    run: () {
      final game = buildTreasuryBidBudgetGame(treasury: 200);
      final base = worldMarketPlayerContextFromGame(game, 'gp_ghost');
      expect(base.treasuryBudgetForBids, 0);
    },
    refs: '#3615',
  ),
  PlayerContextScenario(
    label:
        'staged orders + projectedTreasuryDelta reduce the snapshot budget '
        'by the projected non-bid deficit',
    run: () {
      final game = buildTreasuryBidBudgetGame(treasury: 175);
      final base = worldMarketPlayerContextFromGame(
        game,
        humanPlayerId,
        stagedOrders: humanOrdersWith(const <TradeOrder>[]),
        projectedTreasuryDelta: -50,
      );
      expect(base.treasuryBudgetForBids, 125);
    },
    refs: '#3615',
  ),
];

/// Factory parity over the shared snapshot (single build path).
List<PlayerContextScenario> worldMarketPlayerContextFactoryParityScenarios() =>
    [
      PlayerContextScenario(
        label:
            'validation and suggestion factories reuse identical shared scalars '
            'for the same (game, player)',
        run: () {
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
        },
        refs: '#3615',
      ),
      PlayerContextScenario(
        label:
            'validation and suggestion factories share the same staged '
            'treasury-budget composition',
        run: () {
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
        },
        refs: '#3615',
      ),
    ];

/// `tradeSuggestionContextFromGame` concern-specific behavior.
List<PlayerContextScenario>
tradeSuggestionContextFromGameBehaviorScenarios() => [
  PlayerContextScenario(
    label:
        'passes the caller-supplied availability through unchanged (suggester '
        'raw-stockpile source is not replaced by offer caps)',
    run: () {
      final game = buildTreasuryBidBudgetGame(treasury: 100);
      const available = <CommodityId, int>{'timber': 7, 'grain': 3};
      final suggestion = tradeSuggestionContextFromGame(
        game,
        humanPlayerId,
        availableStockpileByCommodityId: available,
      );
      expect(suggestion.availableStockpileByCommodityId, available);
    },
    refs: '#3615',
  ),
  PlayerContextScenario(
    label: 'keeps the suggester defaults when need and priorities are omitted',
    run: () {
      final game = buildTreasuryBidBudgetGame(treasury: 100);
      final suggestion = tradeSuggestionContextFromGame(
        game,
        humanPlayerId,
        availableStockpileByCommodityId: const <CommodityId, int>{},
      );
      expect(suggestion.commodityNeedByCommodityId, isEmpty);
      expect(
        suggestion.offerPriority,
        TradeSuggestionContext.defaultOfferPriority,
      );
      expect(
        suggestion.bidPriority,
        TradeSuggestionContext.defaultBidPriority,
      );
    },
    refs: '#3615',
  ),
  PlayerContextScenario(
    label: 'forwards caller need and priority overrides',
    run: () {
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
    },
    refs: '#3615',
  ),
];
