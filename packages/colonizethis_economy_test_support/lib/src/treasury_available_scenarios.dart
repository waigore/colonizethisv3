// Table-driven treasuryAvailableForBidsByPlayer scenarios (Refs #3836).

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'treasury_bid_budget_test_support.dart';

/// One row for [treasuryAvailableForBidsScenarios].
typedef TreasuryAvailableScenario = ({
  String label,
  int treasury,
  String playerId,
  int projectedNonBidTreasuryDelta,
  int expected,
  String? refs,
});

const List<TreasuryAvailableScenario> treasuryAvailableForBidsScenarios = [
  (
    label: "returns the player's raw treasury for known players",
    treasury: 250,
    playerId: humanPlayerId,
    projectedNonBidTreasuryDelta: 0,
    expected: 250,
    refs: '#3093',
  ),
  (
    label: 'clamps negative treasury to 0 (defensive guard)',
    treasury: -10,
    playerId: humanPlayerId,
    projectedNonBidTreasuryDelta: 0,
    expected: 0,
    refs: null,
  ),
  (
    label: 'returns 0 when playerId does not resolve to a player',
    treasury: 100,
    playerId: 'gp_ghost',
    projectedNonBidTreasuryDelta: 0,
    expected: 0,
    refs: null,
  ),
  (
    label: 'default projectedNonBidTreasuryDelta == 0 preserves the legacy '
        '"raw treasury" contract for callers without a projection',
    treasury: 175,
    playerId: humanPlayerId,
    projectedNonBidTreasuryDelta: 0,
    expected: 175,
    refs: '#3093',
  ),
  (
    label: 'projectedNonBidTreasuryDelta < 0 subtracts the absolute deficit '
        'from raw treasury (positive AC #1)',
    treasury: 100,
    playerId: humanPlayerId,
    projectedNonBidTreasuryDelta: -40,
    expected: 60,
    refs: '#3093',
  ),
  (
    label: 'projectedNonBidTreasuryDelta > 0 leaves the budget at raw treasury '
        '(conservative — net non-bid income never raises the budget)',
    treasury: 100,
    playerId: humanPlayerId,
    projectedNonBidTreasuryDelta: 50,
    expected: 100,
    refs: '#3093',
  ),
  (
    label: 'projected deficit equal to treasury clamps the budget at exactly 0',
    treasury: 80,
    playerId: humanPlayerId,
    projectedNonBidTreasuryDelta: -80,
    expected: 0,
    refs: null,
  ),
  (
    label: 'projected deficit larger than treasury still clamps at 0 (not negative)',
    treasury: 50,
    playerId: humanPlayerId,
    projectedNonBidTreasuryDelta: -120,
    expected: 0,
    refs: null,
  ),
  (
    label: 'projectedNonBidTreasuryDelta is ignored when treasury is already 0',
    treasury: 0,
    playerId: humanPlayerId,
    projectedNonBidTreasuryDelta: 25,
    expected: 0,
    refs: null,
  ),
  (
    label: 'unknown playerId returns 0 even when a non-zero '
        'projectedNonBidTreasuryDelta is supplied',
    treasury: 100,
    playerId: 'gp_ghost',
    projectedNonBidTreasuryDelta: -30,
    expected: 0,
    refs: null,
  ),
];

void runTreasuryAvailableScenario(TreasuryAvailableScenario scenario) {
  final game = buildTreasuryBidBudgetGame(treasury: scenario.treasury);
  final actual = treasuryAvailableForBidsByPlayer(
    game: game,
    playerId: scenario.playerId,
    projectedNonBidTreasuryDelta: scenario.projectedNonBidTreasuryDelta,
  );
  expect(actual, scenario.expected);
}

/// UI composition scenarios reconstructing treasury-bid-cap math end-to-end.
class TreasuryUiCompositionScenario {
  const TreasuryUiCompositionScenario({
    required this.label,
    required this.treasury,
    this.prices = const {},
    this.stagedBids = const [],
    this.projectedNonBidTreasuryDelta = 0,
    required this.verify,
    this.refs,
  });

  final String label;
  final int treasury;
  final Map<CommodityId, int> prices;
  final List<TradeOrder> stagedBids;
  final int projectedNonBidTreasuryDelta;
  final void Function({
    required Game game,
    required data.ResourceRules rules,
    required int budget,
    required int currentSpend,
  })
  verify;
  final String? refs;
}

List<TreasuryUiCompositionScenario> treasuryUiCompositionScenarios(
  data.ResourceRules rules,
) => [
  TreasuryUiCompositionScenario(
    label: 'treasury 100, market price timber 30, no staged bids → headroom for '
        'fresh row equals raw treasury (allows up to qty 3)',
    treasury: 100,
    prices: const {'timber': 30},
    verify: ({required game, required rules, required budget, required currentSpend}) {
      final int? rowPrice = effectiveMarketPriceForCommodityId(
        commodityId: 'timber',
        worldMarket: game.worldMarketState,
        resourceRules: rules,
      );
      expect(rowPrice, 30);
      final int headroom = budget - currentSpend;
      expect(headroom ~/ rowPrice!, 3);
    },
    refs: '#3093',
  ),
  TreasuryUiCompositionScenario(
    label: 'treasury 100, staged Bid timber qty 3 (spend 90) → adding a fresh bid '
        'for iron (price 80) is refused (headroom 10 < 80)',
    treasury: 100,
    prices: const {'timber': 30, 'iron': 80},
    stagedBids: [bidOrder('timber', 3)],
    verify: ({required game, required rules, required budget, required currentSpend}) {
      final int? ironPrice = effectiveMarketPriceForCommodityId(
        commodityId: 'iron',
        worldMarket: game.worldMarketState,
        resourceRules: rules,
      );
      expect(ironPrice, 80);
      final int headroom = budget - currentSpend;
      expect(headroom, 10);
      expect(
        headroom < ironPrice!,
        isTrue,
        reason:
            'Cannot fit even 1 unit of iron at price 80 with only 10 treasury '
            'headroom — the UI must silent-no-op the toggle.',
      );
    },
    refs: '#3093',
  ),
  TreasuryUiCompositionScenario(
    label: 'treasury 100, staged Bid timber qty 3 (spend 90), incrementing timber → '
        'next increment would make spend 120 (> 100), so the UI must silent-no-op',
    treasury: 100,
    prices: const {'timber': 30},
    stagedBids: [bidOrder('timber', 3)],
    verify: ({required game, required rules, required budget, required currentSpend}) {
      const int delta = 1;
      final int? rowPrice = effectiveMarketPriceForCommodityId(
        commodityId: 'timber',
        worldMarket: game.worldMarketState,
        resourceRules: rules,
      );
      expect(rowPrice, 30);
      expect(currentSpend + delta * rowPrice! > budget, isTrue);
    },
    refs: '#3093',
  ),
  TreasuryUiCompositionScenario(
    label: 'treasury 100, projectedDelta=-40 (UI reconstructs non-bid delta with '
        'no staged bids), market price timber 30 → budget = 60, default qty '
        '1 fits and headroom permits up to qty 2 (spend 60)',
    treasury: 100,
    prices: const {'timber': 30},
    projectedNonBidTreasuryDelta: -40,
    verify: ({required game, required rules, required budget, required currentSpend}) {
      final int headroom = budget - currentSpend;
      final int? rowPrice = effectiveMarketPriceForCommodityId(
        commodityId: 'timber',
        worldMarket: game.worldMarketState,
        resourceRules: rules,
      );
      expect(budget, 60);
      expect(rowPrice, 30);
      expect(headroom ~/ rowPrice!, 2);
    },
    refs: '#3093',
  ),
  TreasuryUiCompositionScenario(
    label: 'treasury 50, projectedNonBidTreasuryDelta=-60 → budget clamps to 0 '
        'so no bid (even default qty 1) can be staged on any priced '
        'commodity (silent no-op gate)',
    treasury: 50,
    prices: const {'timber': 30},
    projectedNonBidTreasuryDelta: -60,
    verify: ({required game, required rules, required budget, required currentSpend}) {
      final int? rowPrice = effectiveMarketPriceForCommodityId(
        commodityId: 'timber',
        worldMarket: game.worldMarketState,
        resourceRules: rules,
      );
      expect(budget, 0);
      expect(rowPrice, 30);
      expect(budget < rowPrice!, isTrue);
    },
    refs: '#3093',
  ),
];

void runTreasuryUiCompositionScenario(
  TreasuryUiCompositionScenario scenario,
  data.ResourceRules rules,
) {
  final game = buildTreasuryBidBudgetGame(
    treasury: scenario.treasury,
    prices: scenario.prices,
  );
  final orders = scenario.stagedBids.isEmpty
      ? const Orders()
      : humanOrdersWith(scenario.stagedBids);
  final budget = treasuryAvailableForBidsByPlayer(
    game: game,
    playerId: humanPlayerId,
    projectedNonBidTreasuryDelta: scenario.projectedNonBidTreasuryDelta,
  );
  final currentSpend = stagedBidTotalSpendByPlayer(
    orders: orders,
    playerId: humanPlayerId,
    game: game,
    resourceRules: rules,
  );
  scenario.verify(
    game: game,
    rules: rules,
    budget: budget,
    currentSpend: currentSpend,
  );
}
