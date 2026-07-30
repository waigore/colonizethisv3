import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/industry_counsel_ranking.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('rankIndustryCounselRecommendations', () {
    test('returns at most three stable recommendations', () {
      final player = Player(
        id: 'gp1',
        displayName: 'GP',
        isHuman: true,
        stockpile: Stockpile()
            .applyDelta(CommodityCatalog.timber.id, 20)
            .applyDelta(CommodityCatalog.fabric.id, 10),
        workerPool: const WorkerPool(peasants: 4),
      );
      final game = Game(
        id: 'g1',
        players: [player],
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
      );
      const topology = MapTopology();
      final first = rankIndustryCounselRecommendations(
        game: game,
        playerId: 'gp1',
        currentOrders: const Orders(),
        topology: topology,
        tileMapByRegion: const {},
      );
      final second = rankIndustryCounselRecommendations(
        game: game,
        playerId: 'gp1',
        currentOrders: const Orders(),
        topology: topology,
        tileMapByRegion: const {},
      );
      expect(first.length, lessThanOrEqualTo(3));
      expect(second, equals(first));
      for (final recommendation in first) {
        expect(recommendation.recommendationId, isNotEmpty);
        expect(recommendation.detailReasonKeys, isNotEmpty);
      }
    });

    test('stars only produce recipes in ranked produce slots', () {
      final player = Player(
        id: 'gp1',
        displayName: 'GP',
        isHuman: true,
        stockpile: Stockpile()
            .applyDelta(CommodityCatalog.timber.id, 30)
            .applyDelta(CommodityCatalog.iron.id, 30)
            .applyDelta(CommodityCatalog.coal.id, 30),
        workerPool: const WorkerPool(peasants: 8),
      );
      final game = Game(
        id: 'g1',
        players: [player],
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
      );
      final recommendations = rankIndustryCounselRecommendations(
        game: game,
        playerId: 'gp1',
        currentOrders: const Orders(),
        topology: const MapTopology(),
        tileMapByRegion: const {},
      );
      final produce = recommendations
          .where(
            (r) => r.kind == IndustryCounselRecommendationKind.produceRecipe,
          )
          .toList();
      expect(produce.length, lessThanOrEqualTo(3));
      for (final recommendation in produce) {
        expect(recommendation.recipeId, isNotNull);
        expect(
          recommendation.recommendationId,
          startsWith('produce:'),
        );
      }
    });
  });

  group('industryCounselScoreRecipe', () {
    test('neutral agenda yields zero agenda contribution', () {
      final recipe = ProductionRecipesCatalog.byId['lumber_from_timber']!;
      final scoreNeutral = industryCounselScoreRecipe(
        recipe: recipe,
        stockpile: const Stockpile(),
        workers: const WorkerPool(),
        agendaId: kIndustryCounselNeutralAgendaId,
      );
      final scoreWarmonger = industryCounselScoreRecipe(
        recipe: recipe,
        stockpile: const Stockpile(),
        workers: const WorkerPool(),
        agendaId: 'warmonger',
      );
      expect(scoreWarmonger, greaterThan(scoreNeutral));
    });
  });
}
