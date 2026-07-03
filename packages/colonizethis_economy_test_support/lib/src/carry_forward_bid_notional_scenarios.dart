// Table-driven carry-forward bid-notional scenarios (Refs #3836).

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'bid_spend_game_factory.dart';
import 'trade_order_factory.dart';

/// One row for `carryForwardBidNotionalByPlayer` scenario tables.
class CarryForwardBidNotionalScenario {
  const CarryForwardBidNotionalScenario({
    required this.label,
    required this.bids,
    required this.prices,
    required this.verify,
    this.playerId = 'gp1',
    this.refs,
  });

  final String label;
  final List<TradeOrder> bids;
  final Map<CommodityId, int> prices;
  final String playerId;
  final void Function(int notional, data.ResourceRules rules) verify;
  final String? refs;
}

void runCarryForwardBidNotionalScenario(
  CarryForwardBidNotionalScenario scenario,
  data.ResourceRules rules,
) {
  final game = carryForwardBidGame(
    scenario.bids,
    playerId: scenario.playerId,
    prices: scenario.prices,
    gameId: 'g_carryfwd',
  );
  final notional = carryForwardBidNotionalByPlayer(
    game: game,
    playerId: scenario.playerId,
    resourceRules: rules,
  );
  scenario.verify(notional, rules);
}

/// Canonical carry-forward bid-notional cases not covered by the staged/carry
/// parity suite (`world_market_bid_spend_shared_helper_test.dart`).
List<CarryForwardBidNotionalScenario> carryForwardBidNotionalScenarios() => [
  CarryForwardBidNotionalScenario(
    label: 'falls back to catalog default price when world price is missing',
    bids: [testBid('timber', 4)],
    prices: const <CommodityId, int>{},
    verify: (notional, rules) {
      final catalogTimber =
          rules.defaultMarketPriceForCommodityId('timber') ?? 0;
      expect(catalogTimber, greaterThan(0));
      expect(notional, 4 * catalogTimber);
    },
    refs: '#3122',
  ),
];
