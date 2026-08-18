// Trade counsel ranking Game fixtures (Refs #4508 Slice D).
// dart format off
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/trade_counsel_ranking.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

Stockpile tcTimberSurplus([int amount = 80]) => const Stockpile().applyDelta(CommodityCatalog.timber.id, amount);

Game tcGame({Stockpile? stockpile, int treasury = 0}) => TestFixtures.minimalGame(id: 'g1', turnNumber: 0, players: [Player(id: 'gp1', displayName: 'GP', isHuman: true, stockpile: stockpile ?? const Stockpile(), treasury: treasury)]);

TradeCounselBookResult tcRank(Game game, {List<AssignedRecipe> assignments = const []}) => rankTradeCounselRecommendations(game: game, playerId: 'gp1', productionAssignments: assignments, currentOrders: const Orders(), topology: const MapTopology(), tileMapByRegion: const {});

Stockpile tcSaturatedNonRichesExceptTimber() {
  var stockpile = tcTimberSurplus();
  for (final commodity in CommodityCatalog.all) {
    if (richesCommodityIds.contains(commodity.id)) continue;
    if (commodity.id == CommodityCatalog.timber.id) continue;
    stockpile = stockpile.applyDelta(commodity.id, kTradeCounselSpeculativeBidStockpileTarget * 4);
  }
  return stockpile;
}
