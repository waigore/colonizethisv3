import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

Game _singlePlayerGame({
  required Stockpile stockpile,
  required WorkerPool workerPool,
  int treasury = 0,
}) {
  return Game(
    id: 'g-preview',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'Human',
        isHuman: true,
        stockpile: stockpile,
        workerPool: workerPool,
        treasury: treasury,
      ),
      const Player(id: 'p2', displayName: 'AI', isHuman: false),
    ],
  );
}

void main() {
  group('economy stockpile preview', () {
    test('extraction-only scenario', () {
      const game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: [Player(id: 'p1', displayName: 'Human', isHuman: true)],
      );

      final deltas = previewStockpileNetDeltaByCommodityForPlayer(
        game: game,
        playerId: 'p1',
        topology: const MapTopology(),
        tileMapByRegion: const {},
        extractedByPlayerId: const {
          'p1': {'timber': 3},
        },
      );

      expect(deltas, {'timber': 3});
    });

    test('riches-only scenario', () {
      final game = _singlePlayerGame(
        stockpile: const Stockpile(quantities: {'gold': 2}),
        workerPool: WorkerPool.empty,
      );

      final deltas = previewStockpileNetDeltaByCommodityForPlayer(
        game: game,
        playerId: 'p1',
        topology: const MapTopology(),
        tileMapByRegion: const {},
      );

      expect(deltas, {'gold': -2});
    });

    test('consumption-only scenario', () {
      final game = _singlePlayerGame(
        stockpile: const Stockpile(quantities: {'grain': 2}),
        workerPool: const WorkerPool(peasants: 2),
      );

      final deltas = previewStockpileNetDeltaByCommodityForPlayer(
        game: game,
        playerId: 'p1',
        topology: const MapTopology(),
        tileMapByRegion: const {},
      );

      expect(deltas, {'grain': -2});
    });

    test('production-only scenario', () {
      final game = _singlePlayerGame(
        stockpile: const Stockpile(quantities: {'timber': 2}),
        workerPool: const WorkerPool(apprentices: 1),
      );

      final deltas = previewStockpileNetDeltaByCommodityForPlayer(
        game: game,
        playerId: 'p1',
        topology: const MapTopology(),
        tileMapByRegion: const {},
        desiredOutputByRecipe: const {'lumber_from_timber': 1},
        extractedByPlayerId: {
          'p1': {
            CommodityCatalog.grain.id: 2,
            CommodityCatalog.refinedSugar.id: 1,
          },
        },
      );

      expect(deltas, {'timber': -2, 'lumber': 1});
    });

    test(
      'combined scenario matches stockpile_after minus stockpile_before',
      () {
        final game = _singlePlayerGame(
          stockpile: const Stockpile(
            quantities: {'gold': 1, 'timber': 2, 'grain': 2, 'refinedSugar': 1},
          ),
          workerPool: const WorkerPool(apprentices: 1),
        );

        final projected = applyEconomyPhasesForPreview(
          game: game,
          topology: const MapTopology(),
          tileMapByRegion: const {},
          extractedByPlayerId: const {
            'p1': {'timber': 2},
          },
          assignmentsByPlayerId: {
            'p1': assignedRecipesFromDesiredOutput(const {
              'lumber_from_timber': 1,
            }),
          },
        );
        final before = game.playerById('p1')!.stockpile;
        final after = projected.playerById('p1')!.stockpile;

        final expected = <String, int>{};
        for (final entry in after.quantities.entries) {
          final delta = entry.value - before.quantityOf(entry.key);
          if (delta != 0) expected[entry.key] = delta;
        }
        for (final entry in before.quantities.entries) {
          if (!after.quantities.containsKey(entry.key)) {
            expected[entry.key] = -entry.value;
          }
        }

        final deltas = previewStockpileNetDeltaByCommodityForPlayer(
          game: game,
          playerId: 'p1',
          topology: const MapTopology(),
          tileMapByRegion: const {},
          desiredOutputByRecipe: const {'lumber_from_timber': 1},
          extractedByPlayerId: const {
            'p1': {'timber': 2},
          },
        );

        expect(deltas, expected);
      },
    );
  });
}
