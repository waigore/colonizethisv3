// Industry counsel ranking (Refs #4189/#4190). Dense for repo.orders_test_support_loc.
// dart format off
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/industry_counsel_ranking.dart';
import 'package:colonizethis_test/test.dart';
import 'support/scenario_runner.dart';

Game _icrGame({Stockpile? stockpile, WorkerPool? workers}) => Game(id: 'g1', players: [Player(id: 'gp1', displayName: 'GP', isHuman: true, stockpile: stockpile ?? const Stockpile(), workerPool: workers ?? const WorkerPool())], worldState: WorldState(turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0), oldWorld: const RegionData(), newWorld: const RegionData()));
List<IndustryCounselRecommendation> _icrRank(Game game) => rankIndustryCounselRecommendations(game: game, playerId: 'gp1', currentOrders: const Orders(), topology: const MapTopology(), tileMapByRegion: const {});

void main() {
  runLabeledScenarioGroup('rankIndustryCounselRecommendations', [
    rs('returns at most three stable recommendations', () {final g = _icrGame(stockpile: Stockpile().applyDelta(CommodityCatalog.timber.id, 20).applyDelta(CommodityCatalog.fabric.id, 10), workers: const WorkerPool(peasants: 4)); final first = _icrRank(g); expect(first.length, lessThanOrEqualTo(3)); expect(_icrRank(g), equals(first)); for (final r in first) {expect(r.recommendationId, isNotEmpty); expect(r.detailReasonKeys, isNotEmpty);}}),
    rs('stars only produce recipes in ranked produce slots', () {final produce = _icrRank(_icrGame(stockpile: Stockpile().applyDelta(CommodityCatalog.timber.id, 30).applyDelta(CommodityCatalog.iron.id, 30).applyDelta(CommodityCatalog.coal.id, 30), workers: const WorkerPool(peasants: 8))).where((r) => r.kind == IndustryCounselRecommendationKind.produceRecipe).toList(); expect(produce.length, lessThanOrEqualTo(3)); for (final r in produce) {expect(r.recipeId, isNotNull); expect(r.recommendationId, startsWith('produce:'));}}),
  ], runRunnableScenario);
  runLabeledScenarioGroup('industryCounselScoreRecipe', [
    rs('neutral agenda yields zero agenda contribution', () {final recipe = ProductionRecipesCatalog.byId['lumber_from_timber']!; final neutral = industryCounselScoreRecipe(recipe: recipe, stockpile: const Stockpile(), workers: const WorkerPool(), agendaId: kIndustryCounselNeutralAgendaId); expect(industryCounselScoreRecipe(recipe: recipe, stockpile: const Stockpile(), workers: const WorkerPool(), agendaId: 'warmonger'), greaterThan(neutral));}),
  ], runRunnableScenario);
}
