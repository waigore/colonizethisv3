// Trade counsel ranking (Refs #4282). Dense for repo.orders_test_support_loc.
// dart format off
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/trade_counsel_ranking.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'support/scenario_runner.dart';

Game _tcGame({Stockpile? stockpile, int treasury = 0}) => Game(
  id: 'g1',
  players: [
    Player(
      id: 'gp1',
      displayName: 'GP',
      isHuman: true,
      stockpile: stockpile ?? const Stockpile(),
      treasury: treasury,
    ),
  ],
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: const RegionData(),
    newWorld: const RegionData(),
  ),
);

TradeCounselBookResult _tcRank(
  Game game, {
  List<AssignedRecipe> assignments = const [],
}) =>
    rankTradeCounselRecommendations(
      game: game,
      playerId: 'gp1',
      productionAssignments: assignments,
      currentOrders: const Orders(),
      topology: const MapTopology(),
      tileMapByRegion: const {},
    );

void main() {
  runLabeledScenarioGroup('rankTradeCounselRecommendations', [
    rs('returns empty book for bare stockpile', () {
      final result = _tcRank(_tcGame());
      expect(result.isEmpty, isTrue);
      expect(result.recommendations, isEmpty);
    }),
    rs('emits offer for large timber surplus', () {
      final game = _tcGame(
        stockpile: const Stockpile().applyDelta(CommodityCatalog.timber.id, 80),
      );
      final result = _tcRank(game);
      final offers = result.book.where((o) => o.type == TradeOrderType.offer);
      expect(offers, isNotEmpty);
      expect(
        offers.any((o) => o.commodityId == CommodityCatalog.timber.id),
        isTrue,
      );
    }),
    rs('stable ids use bid:/offer: prefix', () {
      final game = _tcGame(
        stockpile: const Stockpile().applyDelta(CommodityCatalog.timber.id, 80),
      );
      final result = _tcRank(game);
      for (final rec in result.recommendations) {
        expect(
          rec.recommendationId,
          startsWith(rec.order.type == TradeOrderType.bid ? 'bid:' : 'offer:'),
        );
      }
    }),
    rs('deterministic across identical inputs', () {
      final game = _tcGame(
        stockpile: const Stockpile().applyDelta(CommodityCatalog.timber.id, 80),
        treasury: tradeCounselTreasuryAffluenceThreshold(),
      );
      final a = _tcRank(game);
      final b = _tcRank(game);
      expect(a.book, equals(b.book));
      expect(
        a.recommendations.map((r) => r.recommendationId).toList(),
        equals(b.recommendations.map((r) => r.recommendationId).toList()),
      );
    }),
    rs('includes speculative bid when affluent and under target', () {
      final affluent = tradeCounselTreasuryAffluenceThreshold();
      final game = _tcGame(
        stockpile: const Stockpile().applyDelta(CommodityCatalog.timber.id, 80),
        treasury: affluent,
      );
      final result = _tcRank(game);
      expect(
        result.book.any((o) => o.type == TradeOrderType.bid),
        isTrue,
        reason: 'F10 speculative pass should emit at least one bid',
      );
    }),
    rs('excludes speculative bid below affluence threshold', () {
      var stockpile = const Stockpile().applyDelta(CommodityCatalog.timber.id, 80);
      for (final commodity in CommodityCatalog.all) {
        if (richesCommodityIds.contains(commodity.id)) continue;
        if (commodity.id == CommodityCatalog.timber.id) continue;
        stockpile = stockpile.applyDelta(
          commodity.id,
          kTradeCounselSpeculativeBidStockpileTarget * 4,
        );
      }
      final game = _tcGame(
        stockpile: stockpile,
        treasury: tradeCounselTreasuryAffluenceThreshold() - 1,
      );
      final result = _tcRank(game);
      expect(
        result.book.where((o) => o.type == TradeOrderType.bid),
        isEmpty,
      );
    }),
    rs('highlights at most three recommendations', () {
      final game = _tcGame(
        stockpile: Stockpile()
            .applyDelta(CommodityCatalog.timber.id, 80)
            .applyDelta(CommodityCatalog.iron.id, 80)
            .applyDelta(CommodityCatalog.coal.id, 80)
            .applyDelta(CommodityCatalog.grain.id, 80),
        treasury: tradeCounselTreasuryAffluenceThreshold(),
      );
      final highlights =
          _tcRank(game).recommendations.where((r) => r.isHighlight).toList();
      expect(highlights.length, lessThanOrEqualTo(3));
      expect(highlights, isNotEmpty);
    }),
  ], runRunnableScenario);
}
